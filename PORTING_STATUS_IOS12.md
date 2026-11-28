# LiquidAss iOS 12 port — implementation and verification notes

## Target

- Deployment target: iOS 12.0.
- Intended OS range for this compatibility branch: iOS 12.0–12.5.7.
- Default architecture: `arm64`. This is the default build profile for non-arm64e iOS 12 platform processes (generally A7–A11 devices).
- A12 devices on iOS 12 may require an `arm64e` slice to inject into arm64e system binaries. A regular `arm64` slice is not a substitute for that slice. Theos documents that the arm64e ABI changed in iOS 14/Xcode 12 and that the modern ABI cannot target iOS 12.0–13.7. For the legacy arm64e ABI, build with Xcode 11.7 and its iOS 13.7 SDK, using `DEVELOPER_DIR=/Applications/Xcode-11.7.app/Contents/Developer IOS12_SDK_VERSION=13.7 IOS12_ARCHS="arm64 arm64e" ./release.sh rootful`. This optional profile is documented but was not build-tested in this environment.
- Recommended baseline iOS 12 package: rootful (`./release.sh rootful`). Rootless/roothide are not iOS 12 installation schemes; they are retained for newer jailbreak environments.

## Compatibility code added

`Shared/LGCompatibility.h/.m` supplies iOS 12 runtime shims for the modern UIKit/Core Animation selectors used by this source:

- `CALayer.cornerCurve` / `setCornerCurve:` (stored as an associated value).
- Semantic UIKit colors used by the project, including labels, separators, system accent colors, grouped backgrounds and `tertiarySystemFillColor`.
- `UIColor colorWithDynamicProvider:` with a static light-appearance resolution (iOS 12 has no system-wide UIKit dark appearance API).
- `UITraitCollection.userInterfaceStyle`, `UIWindow.windowScene`, and `UIView.overrideUserInterfaceStyle` / `setOverrideUserInterfaceStyle:`.
- SF Symbols configuration and `UIImage systemImageNamed:` through template-rendered glyph fallbacks.
- `UIFont monospacedSystemFontOfSize:weight:` through Menlo/system-font fallback.
- `UIAction`, `UIMenu`, `UIControl addAction:forControlEvents:`, and UIButton menu properties through a retained target-action bridge and an action-sheet presentation fallback.

The shim is compiled into both the main tweak and PreferenceBundle, and installed from early constructors before the source's UI code runs.

## Rendering backend

On iOS 12, `LGLiveBackdropView`, `LGAdjustableBlurView`, the Settings low-blur view, AssistiveTouch vibrance, TabBar vibrance and Volume HUD vibrance use `CALayer` plus `UIVisualEffectView` fallback blur. Shape masks, corner geometry, gradients, specular edges and motion/highlight layers remain implemented in the existing code where supported.

The iOS 12 path intentionally does not register or call the private Backboardd custom CAFilter/Metal renderer. `LiquidAssBackboardd/Tweak.mm` returns before its QuartzCore symbol scanner, private offset reads, filter registration and render hooks on iOS 12. The private renderer source contains later-OS render ABI branches, but no verified iOS 12 ABI/signature/offset data was present in the supplied source. Guessing such values is not a safe porting strategy.

Therefore the iOS 12 result is a compatibility renderer, not bit-for-bit parity with the modern custom refraction/dispersion engine.

## OS-specific surface gates

- App Library hooks are registered only on iOS 14+.
- WidgetKit/Widget stack hooks are registered only on iOS 14+.
- `_UIContextMenu*` hooks are registered only on iOS 13+.
- Spotlight hooks retain their existing iOS 16+ gate.
- iOS 12 does not have the later WidgetKit host processes, so `chronod` and `WidgetRenderer-*` are excluded from the install-termination process list. The separate RWB component exits before initialization below iOS 14.
- Safe Mode alert presentation has a legacy `UIApplication.windows` fallback for iOS 12.
- Cover Sheet orientation lookup uses `statusBarOrientation` first and only reads a scene when one exists.

These gates prevent attempts to hook private host classes that are absent from iOS 12. The corresponding platform-only features cannot exist on iOS 12 itself. Legacy SpringBoard classes and the precise Control Center/Cover Sheet hierarchy still require device-level verification; where no verified iOS 12 host or selector exists in the supplied source, the hook is left inactive rather than attached to an assumed class.

## Packaging changes

- Main and Preferences Makefiles force-include the compatibility header.
- `IOS12_SDK_VERSION` and `IOS12_ARCHS` are configurable from the environment so the default modern-SDK arm64 build and the legacy Xcode 11.7 arm64e build use the same source tree.
- The Preferences bundle compiles the compatibility implementation.
- Package minimum firmware is 12.0.
- Release script defaults to a rootful iOS 12 build; rootless/roothide can be selected explicitly for newer environments.
- Main injection filter includes SpringBoard, `assistivetouchd`, UIKit and MobileSafari. Backboardd remains isolated in its own target; its iOS 12 constructor exits before private QuartzCore scanning.

## Verification status

Source-level changes, shell syntax, plist syntax and archive integrity can be checked in this deliverable. A genuine Theos build and runtime verification could not be completed in this environment because it does not contain Theos, Xcode, an iPhoneOS SDK or an iOS 12 device. Do not treat this source archive as a tested/stable binary. Before distribution, build with the intended Theos toolchain and test at minimum on one iOS 12.0–12.5.7 device for each relevant jailbreak/package scheme, checking SpringBoard launch/respring, Backboardd stability, Preferences, Safe Mode, blur clipping and each available UI surface.


## Follow-up hardening (port3)

- Corrected the Objective-C runtime type encodings for the iOS 12 `UIButton` menu boolean accessors (`BOOL` uses the signed-char encoding on arm64).
- Removed App Library settings from the iOS 12 surface list alongside App Library pods/search, WidgetKit and Context Menu entries; the underlying preference keys are retained for forward compatibility.
- Added `validate-ios12-port.sh` to check deployment/package declarations, early shim installation, private Backboardd renderer gating, OS-specific feature gates, shell syntax and plist syntax.

The validator is a source-level consistency check only. It does not replace a Theos compile, package install, or device test.


## Stability fixes (port4) — SpringBoard crash / Safe Mode on iOS 12.5.x

Crash logs from an iOS 12.5.8 device showed SpringBoard dying twice in a row (EXC_BAD_ACCESS at 0x0, main thread) inside
the third-party `HSWidgets` / `HSModernWeatherWidget` code, which triggers the jailbreak's Safe Mode. Fixes:

1. `liquidass.plist` matched `com.apple.UIKit`, so the tweak loaded into every UIKit process. Top-level Logos hooks
   (CALayer, MTMaterialView, ...) are installed before any `%ctor` gate runs. The filter is now limited to
   `SpringBoard`, `assistivetouchd` and `MobileSafari`.
2. `LiquidAssRWB` was gated at `< 12` instead of `< 14`, so its widget-stack/UIWindow/UIView hooks ran inside SpringBoard
   on iOS 12. The gate is now `< 14`.
3. `LGCompatInstallRuntimeShims` added iOS 13+ selectors to shared UIKit classes under their real names
   (`UIImage systemImageNamed:`, `UIColor labelColor`, `UIWindow windowScene`, `UITraitCollection userInterfaceStyle`,
   `UIView overrideUserInterfaceStyle`, `UIControl addAction:forControlEvents:`, `UIButton menu`, ...). Other tweaks
   that probe with `respondsToSelector:` then took their iOS 13+ path and received nil/placeholder values. No iOS 13+
   selector is injected any more. All call sites go through `LGCompat*` helpers that use the native API when present and
   otherwise call the private fallback directly. The only method still added to UIKit is the tweak-private
   `lgCompatPresentMenu` on `UIButton`.
4. `validate-ios12-port.sh` now fails if the UIKit filter returns, or if raw iOS 13+ API / UIKit injection is reintroduced.

Verification: `LGCompatibility.m` was syntax/type checked with clang `-Wall` against minimal UIKit/Foundation stub headers
(front end only). This is NOT a Theos build and NOT a device test.

## Port5 — lock screen corner clip (iOS 12 compat path)

On iOS 12 the glass container was not clipped, so the specular and edge sublayers drew square outside the rounded
notification shape. `LGLiveBackdropView` now sets `clipsToBounds = YES` on the container in the iOS 12 init and
`applyFilters` branches only. iOS 14+ code paths are unchanged.

Not fixed here, needs a device test: the home-screen SpringBoard crash in `HSWidgets.dylib` / `HSModernWeatherWidget`
(see port4). The crashing SpringBoard had 42 tweaks injected, including HSWidgets, Noctis, Snowboard, Choicy, Ersatz and
the W12-* suite. Test liquidass alone with those disabled before judging stability.

## Port6 — iOS 12 global hooks removed

Logos installs ungrouped `%hook` blocks before any `%ctor` runs, and an ungated `%init(...)` runs in the same way. Both
hook UIKit classes that exist on iOS 12 (UILabel, UIVisualEffectView, CALayer, CATransaction, UISwitch, UISlider,
UITabBar, UIAlertController, UIKBBackdropView, ...) across the whole SpringBoard, including the widget view hierarchy
that `HSWidgets` / `HSModernWeatherWidget` use. Changes:

1. Every ungrouped `%hook` block except the glass carriers is wrapped in its own `%group LGIOS14_*` and initialised only when
   `majorVersion >= 14`. Files: AppIcons, Banner, ControlCenter (8), CoverSheet (4), Folder, Passcode (2), QuickActions.
2. Kept ungrouped on purpose (the iOS 12 liquid glass itself): `MTMaterialView` in `Shared/LGGlassKit.x`, `Banner.x`,
   `Folder.x` and `Passcode.x`, plus `NCNotificationShortLookViewController` in `Banner.x` (lock screen notification glass).
3. The UIKit-wide `%init` calls in Alerts, AssistiveTouch, Clock (LGClockRewrite), Controls (both groups), Keyboard and
   TabBar are now gated on iOS 14+. VolumeHUD and PillHUD keep their intentional iOS 12 paths.
4. Trade-off: on iOS 12 the following glass effects are off: Control Center module glass and sliders, cover sheet
   background and wallpaper, passcode buttons, folder icon, quick actions, keyboard, tab bars, global UISwitch/UISlider
   and the iOS 14 alerts. The notification glass, the Dock/Control Center material glass and the legacy volume HUD stay.
5. `validate-ios12-port.sh` fails if a top-level hook outside the five glass carriers appears, or if an `%init` is not
   version-gated.

Not verified: no Theos build, no device run. Logos syntax was checked only by balance of `%group`/`%hook`/`%end` and
braces. The home-screen SpringBoard crash is expected to stop only if it came from the global UIKit hooks; a fresh
`.ips` from the new build is needed to confirm that.

## Port7 — respring commits settings, master switch default

1. The respring confirmation (`LGPrefsUIHelpers.m`) and "Exit Safe Mode" (`LGPRootListController.m`) posted the respring
   notification without first calling `LGForceSynchronizePreferences()`. Staged switch values stayed in memory, the
   on-disk plist never changed, and the respring reloaded the old values. Both now commit first.
2. `LG_requestRespring` now resets the backboardd rapid-start counter (`LGResetBackboardRapidStartCounter`), so a few
   deliberate responds are not counted as a crash loop. The disabled flag is never touched. On iOS 12 the backboardd
   guard does not run at all (the constructor returns early), so this matters for iOS 14+ builds.
3. `Global.Enabled` defaults to on everywhere (UI, `LG_globalEnabled`). Before, the switch showed off while the tweak
   already drew glass when the key was unset.

Not verified on a device.
