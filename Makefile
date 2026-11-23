IOS12_SDK_VERSION ?= 16.5
IOS12_ARCHS ?= arm64
export TARGET 			:= iphone:clang:$(IOS12_SDK_VERSION):12.0
export ARCHS 			:= $(IOS12_ARCHS)
export USE_DEPS 		:= 1
THEOS_PACKAGE_SCHEME	?=

CCACHE := $(shell command -v ccache 2>/dev/null)
export TARGET_CC 		:= $(CCACHE) $(shell xcrun -f clang)
export TARGET_CXX 		:= $(CCACHE) $(shell xcrun -f clang++)

INSTALL_TARGET_PROCESSES = backboardd SpringBoard assistivetouchd
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = liquidass

liquidass_FILES     = Tweak.x \
                      $(wildcard Hooks/*.x) \
                      $(wildcard LiquidAssPrefs/LGPrefsLiquid*.m) \
                      $(wildcard Shared/*.[xm])
liquidass_CFLAGS    = -fobjc-arc -IShared -include LGCompatibility.h
liquidass_USE_MODULES = 0
liquidass_FRAMEWORKS = UIKit QuartzCore CoreText CoreGraphics CoreMotion
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
liquidass_LIBRARIES += roothide
endif


include $(THEOS)/makefiles/tweak.mk
SUBPROJECTS += LiquidAssBackboardd LiquidAssRWB LiquidAssPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
