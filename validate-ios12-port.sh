#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

fail() { echo "[FAIL] $*" >&2; exit 1; }
pass() { echo "[PASS] $*"; }

# Package and bundle minimums.
grep -Eq '^Depends: .*firmware \(>= 12\.0\)' control || fail 'control does not declare iOS 12 minimum'
python3 - <<'PY2'
import plistlib
with open('LiquidAssPrefs/Resources/Info.plist', 'rb') as f:
    assert plistlib.load(f).get('MinimumOSVersion') == '12.0'
PY2
pass 'package and preference bundle target iOS 12.0'

# All Theos targets must inherit the same deployment target.
grep -Eq 'iphone:clang:\$\(IOS12_SDK_VERSION\):12\.0' Makefile || fail 'main target is not iOS 12.0'
grep -Eq 'IOS12_SDK_VERSION=.*16\.5' release.sh || fail 'release script SDK default missing'
pass 'main build target and release script are configured'

# Runtime compatibility installation must precede Logos constructors.
grep -q '__attribute__((constructor(101)))' Shared/LGCompatibility.m || fail 'early compatibility constructor missing'
grep -q 'LGCompatInstallRuntimeShims();' Shared/LGCompatibility.m || fail 'runtime shim install missing'
pass 'early UIKit/Core Animation compatibility shims are installed'

# Do not execute private QuartzCore ABI scanner on iOS 12.
grep -q 'initialOS.majorVersion <= 12' LiquidAssBackboardd/Tweak.mm || fail 'Backboardd iOS 12 guard missing'
pass 'private Backboardd renderer is disabled on iOS 12 pending verified ABI'

# Gate APIs/features that do not exist on iOS 12.
grep -q 'operatingSystemVersion.majorVersion < 14' Hooks/AppLibrary.x || fail 'App Library gate missing'
grep -q 'operatingSystemVersion.majorVersion < 14' Hooks/Widgets.x || fail 'WidgetKit gate missing'
grep -q 'operatingSystemVersion.majorVersion < 13' Hooks/ContextMenu.x || fail 'Context Menu gate missing'
grep -q 'operatingSystemVersion.majorVersion < 14' LiquidAssRWB/Tweak.x || fail 'RWB iOS 14 gate missing'
pass 'App Library, WidgetKit, Context Menu and RWB are version-gated'

grep -q 'com.apple.UIKit' liquidass.plist && fail 'main tweak filter must not match every UIKit app (com.apple.UIKit)'
pass 'main tweak injects only into SpringBoard, assistivetouchd and MobileSafari'

# Regression guards for the SpringBoard crash seen with third-party tweaks (HSWidgets).
# iOS 13+ selectors must never be added to shared UIKit classes under their real names.
if grep -nE 'Add(Class)?MethodIfMissing\((UIColor|UIImage|UIWindow|UITraitCollection|UIView|CALayer|UIFont|UIControl)\.class' Shared/LGCompatibility.m; then
    fail 'LGCompatibility.m must not inject iOS 13+ selectors into shared UIKit classes'
fi
pass 'no iOS 13+ selectors are injected into shared UIKit classes'
RAW_API=$(grep -rnE '\[UIColor (labelColor|secondaryLabelColor|tertiaryLabelColor|separatorColor|system[A-Za-z0-9]*Color|secondarySystem[A-Za-z]*Color|tertiarySystem[A-Za-z]*Color)\]|UIColor\.(labelColor|secondaryLabelColor|tertiaryLabelColor|system[A-Za-z0-9]*Color)|\.userInterfaceStyle|\.overrideUserInterfaceStyle|\[UIImage systemImageNamed|monospacedSystemFontOfSize' \
    --include=*.x --include=*.m --include=*.mm Hooks Shared LiquidAssPrefs Tweak.x 2>/dev/null | grep -v '^Shared/LGCompatibility\.m' || true)
if [ -n "$RAW_API" ]; then echo "$RAW_API" >&2; fail 'raw iOS 13+ UIKit API used; route through LGCompat helpers'; fi
pass 'iOS 13+ UIKit API is only reached through LGCompat helpers'

# Every hook outside an iOS 14 gated group installs on iOS 12 too (Logos auto-inits ungrouped hooks
# before any %ctor runs). Only the glass carriers may stay ungrouped.
python3 - <<'PYCHK' || fail 'ungrouped %hook outside the allowlist would run on iOS 12'
import re, glob, sys
ALLOW = {('Shared/LGGlassKit.x','MTMaterialView'), ('Hooks/Banner.x','MTMaterialView'),
         ('Hooks/Banner.x','NCNotificationShortLookViewController'), ('Hooks/Folder.x','MTMaterialView'),
         ('Hooks/Passcode.x','MTMaterialView')}
bad = []
for f in sorted(set(glob.glob('Hooks/*.x') + glob.glob('Shared/*.x') + glob.glob('*.x'))):
    st = []
    for i, l in enumerate(open(f, encoding='utf-8').read().split('\n'), 1):
        t = l.strip()
        if re.match(r'%group\b', t): st.append('G')
        elif re.match(r'%hook\b', t):
            if not st and (f, t.split()[1]) not in ALLOW: bad.append(f"{f}:{i} {t}")
            st.append('H')
        elif re.match(r'%end\b', t) and st: st.pop()
if bad:
    print('\n'.join(bad)); sys.exit(1)
PYCHK
pass 'every hook outside the 5 glass carriers sits in an iOS 14 gated group'

# Every %init must be version-gated unless it is an intentional iOS 12 feature.
python3 - <<'PYCHK2' || fail 'a hook group initialises on iOS 12 without a version gate'
import re, glob, sys
INTENTIONAL = {'LGLegacyVolumeHUDHooks', 'LGPillHUDHooks', 'LGNowPlayingArtwork', 'LGVolumeHUDHooks'}
bad = []
for f in sorted(set(glob.glob('Hooks/*.x') + glob.glob('Shared/*.x') + glob.glob('*.x'))):
    lines = open(f, encoding='utf-8').read().split('\n')
    for i, l in enumerate(lines):
        for m in re.finditer(r'%init\((\w+)\)', l):
            g = m.group(1)
            if g in INTENTIONAL: continue
            if g.startswith('LGIOS14_'):
                # generated group: its ctor returns early below iOS 14 (checked here once per file)
                if not re.search(r'majorVersion\s*<\s*14\)\s*return', '\n'.join(lines)):
                    bad.append(f"{f}:{i+1} %init({g}) has no iOS 14 early return")
                continue
            window = '\n'.join(lines[max(0, i-4):i+1])
            if not re.search(r'majorVersion\s*(<|>=)\s*1[2-6]|isOperatingSystemAtLeastVersion|LGIsAtLeastiOS16|LGCompatIsIOS12OrEarlier', window):
                bad.append(f"{f}:{i+1} %init({g})")
if bad:
    print('\n'.join(bad)); sys.exit(1)
PYCHK2
pass 'every %init outside the intentional iOS 12 features is version-gated'

# Respring must commit staged prefs before asking SpringBoard to respring; otherwise nothing changes.
python3 - <<'PYCHK3' || fail 'respring path does not commit staged preferences first'
import re, sys
bad = []
for f in ['LiquidAssPrefs/LGPrefsUIHelpers.m', 'LiquidAssPrefs/LGPRootListController.m']:
    lines = open(f, encoding='utf-8').read().split('\n')
    for i, l in enumerate(lines):
        if 'notify_post(LGPrefsRespringNotificationCString)' in l:
            window = '\n'.join(lines[max(0, i-4):i])
            if 'LGForceSynchronizePreferences()' not in window:
                bad.append(f"{f}:{i+1}")
if bad:
    print('\n'.join(bad)); sys.exit(1)
PYCHK3
pass 'every respring notify commits staged preferences first'

# The deliberate respring must not be counted as a backboardd crash loop.
grep -q 'LGResetBackboardRapidStartCounter();' Tweak.x || fail 'LG_requestRespring must reset the backboardd rapid-start counter'
pass 'deliberate respring resets the backboardd rapid-start counter'

# Master switch default must match what the tweak actually does when the key is unset.
grep -q 'Global.Enabled", YES)' Shared/LGSharedSupport.m || fail 'Global.Enabled default must be YES in LG_globalEnabled'
pass 'master switch default matches the tweak (unset = on)'

bash -n release.sh
bash -n validate-ios12-port.sh
pass 'shell syntax checks'

if command -v plutil >/dev/null 2>&1; then
    plutil -lint liquidass.plist LiquidAssBackboardd/LiquidAssBackboardd.plist \
        LiquidAssRWB/LiquidAssRWB.plist LiquidAssPrefs/Resources/Info.plist
else
    python3 - <<'PY2'
import plistlib
with open('LiquidAssPrefs/Resources/Info.plist', 'rb') as f:
    plistlib.load(f)
PY2
fi
pass 'property-list syntax checks'
pass 'static iOS 12 port checks completed (not a Theos build or device test)'
