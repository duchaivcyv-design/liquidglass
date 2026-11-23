#!/bin/bash
set -euo pipefail
IOS12_SDK_VERSION="${IOS12_SDK_VERSION:-16.5}"
IOS12_ARCHS="${IOS12_ARCHS:-arm64}"
DEVICE_TARGET="iphone:clang:${IOS12_SDK_VERSION}:12.0"
MODE="${1:-rootful}"
case "$MODE" in
    rootful|rootless|roothide|sim) ;;
    *)
        echo "Usage: $0 [rootful|rootless|roothide|sim]" >&2
        echo 'Optional: IOS12_SDK_VERSION=16.5 IOS12_ARCHS="arm64"' >&2
        exit 2
        ;;
esac

if [[ "$MODE" == "rootless" ]]; then
    make clean
    make package -j8 ARCHS="$IOS12_ARCHS" TARGET="$DEVICE_TARGET" FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
fi
if [[ "$MODE" == "rootful" ]]; then
    make clean
    make package -j8 ARCHS="$IOS12_ARCHS" TARGET="$DEVICE_TARGET" FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=
fi
# this only works if you got the roothide theos fork: https://github.com/roothide/theos
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/roothide/theos/master/bin/install-theos)"
if [[ "$MODE" == "roothide" ]]; then
    make clean
    make package -j8 ARCHS="$IOS12_ARCHS" TARGET="$DEVICE_TARGET" FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide
fi

if [[ "$MODE" == "sim" ]]; then
    make clean
    make -j8 ARCHS=x86_64 TARGET="simulator:clang:latest:12.0"
    cp .theos/obj/iphone_simulator/debug/*.dylib /opt/simject/
    ldid -S /opt/simject/*.dylib
    cp -r .theos/obj/iphone_simulator/debug/LiquidAssPrefs.bundle /opt/simject/PreferenceBundles/
    cp LiquidAssPrefs/layout/Library/PreferenceLoader/Preferences/LiquidAssPrefs.plist /opt/simject/PreferenceLoader/Preferences/
    resim
fi
