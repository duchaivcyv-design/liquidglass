

# Liquid (Gl)ass

## iOS 12 compatibility port

This branch targets iOS 12.0–12.5.7. The default profile builds an arm64 rootful package with `./release.sh rootful` (intended for non-arm64e system processes). A12 devices may require the legacy arm64e ABI to inject into arm64e platform binaries; use Xcode 11.7 and its iOS 13.7 SDK:

```sh
DEVELOPER_DIR=/Applications/Xcode-11.7.app/Contents/Developer \
IOS12_SDK_VERSION=13.7 IOS12_ARCHS="arm64 arm64e" ./release.sh rootful
```

Do not use a modern Xcode 12+ arm64e compiler for this pre-iOS-14 target: its arm64e ABI is incompatible with iOS 12–13.7. The `rootless` and `roothide` modes remain for newer jailbreak environments. The legacy A12 build profile is source-configured but has not been build-tested in this environment.

On iOS 12, LiquidAss uses a UIKit `UIVisualEffectView` backdrop with Core Animation shape/highlight layers. The private Backboardd QuartzCore/Metal renderer is intentionally not activated there because the source's verified render ABI branches begin after iOS 12; using guessed offsets or function signatures would risk SpringBoard/Backboardd instability. This fallback preserves the main blur/glass surfaces but does not reproduce the custom refraction, dispersion, or per-host shader pipeline exactly.

App Library and WidgetKit-specific surfaces are skipped on iOS 12 because those system features are not present in that OS. The iOS 13+ Context Menu hooks and iOS 16+ Spotlight hooks are likewise gated to the OS versions that provide their host classes.

See [PORTING_STATUS_IOS12.md](PORTING_STATUS_IOS12.md) for the compatibility matrix and verification limits. This source tree has not been compiled or exercised on physical iOS 12 devices in this environment.

This tweak is incomplete, issues WILL happen.

Nightly builds that contains the bleeding edge changes are available [here](https://github.com/winaviation-tweaks/liquidass/releases/tag/nightly)

And I'm still working on the tweak locally, just be patient :)

## Localization

Usage: tools/localizations.rb COMMAND [PATH]

  validate                 see if stuff are correct
  clean                    remove unused english keys and translated keys
  sync                     add missing locale keys using english values
  export-template [PATH]   export active english strings to PATH, or stdout

## donation
i only accept crypto for now, wallet addreses:
```
BTC: bc1qlv830emqsffqslns2e3kglkgcdnlag0nfnyj4k
ETH: 0x6245EF47c749D1b5c2830b145cB943a8aD826bea 
LTC: ltc1q7j6vlgvymxdtwm46u0n22h7m4890cexfp22vfm 
DOGE: D76nuR1HWSymSLhFYYhkfpc4JHg1HjvgWD 
SOL: F1rH3PSMHFHXbGLGQiWXGLRaahfYoVULUwhsvrewM37W
TRX: TVuW2KcYBMcr2VAMhYVqYmoT15N3MbZ8eX 
USDC (Polygon): 0x6245EF47c749D1b5c2830b145cB943a8aD826bea 
USDT (Tron/trc-20): TVuW2KcYBMcr2VAMhYVqYmoT15N3MbZ8eX 
```
contact me if you dont see your desired cryptocurrency

### contributions to this tweak are welcomed


## iOS 12 compatibility branch

This source tree now targets iOS 12.0 as its deployment baseline. The iOS 12 rendering path uses UIKit's `UIVisualEffectView` blur backend with Core Animation shape/highlight layers. The private Backboardd QuartzCore/Metal renderer is deliberately disabled on iOS 12 because the supplied source does not contain a verified iOS 12 ABI, symbol map or structure offsets. Consequently, this is a compatibility renderer and does not claim full refraction/dispersion parity with newer iOS releases.

Build a rootful package with `./release.sh rootful`. The default profile builds `arm64`. For A12 arm64e platform-process injection on iOS 12, use the legacy arm64e ABI toolchain documented in `PORTING_STATUS_IOS12.md`; the profile is provided but has not been build-tested in this environment.

### Static validation

Run `./validate-ios12-port.sh` before building. It checks the iOS 12 package/deployment declarations, early runtime-shim installation, the iOS 12 Backboardd safety gate, feature availability gates, shell syntax and property-list syntax. It does not compile the tweak or prove runtime stability.
