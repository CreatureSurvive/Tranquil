#
#  Makefile.sh
#  Tranquil
#
#  Created by Dana Buehre on 3/8/22.
#

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET := iphone:clang:14.4:15.0
else
TARGET := iphone:clang:14.4:11.0
endif
ARCHS = arm64 arm64e

DEBUG = 1
RELEASE = 0
FINALPACKAGE = 1
GO_EASY_ON_ME = 0
LEAN_AND_MEAN = 1

DEBUG_EXT =
THEOS_PACKAGE_DIR = Releases
INSTALL_TARGET_PROCESSES = SpringBoard
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)$(DEBUG_EXT)

# set to 0 to build with regular png files
# set to 1 to build with Assets.car file (requires xcode, on Mac OS)
USE_ASSET_CATALOG = 1

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Tranquil
Tranquil_BUNDLE_EXTENSION = bundle
Tranquil_FILES = $(wildcard Classes/*.m)
Tranquil_CFLAGS = -fobjc-arc
Tranquil_PRIVATE_FRAMEWORKS = ControlCenterUIKit Preferences SpringBoardServices MediaControls
Tranquil_INSTALL_PATH = /Library/ControlCenter/Bundles/

include $(THEOS_MAKE_PATH)/bundle.mk

before-all::
	@echo "> Preparing bundle images"
    ifeq ($(USE_ASSET_CATALOG), 1)
		@echo "> Generating asset catalog"
		$(shell rm -f ./Resources/*.png; cp ./Image-Assets/SettingsIcon-large.png ./Resources/AppIcon-large.png)
		$(shell /usr/bin/xcrun actool Assets.xcassets --compile Resources --platform iphoneos --minimum-deployment-target 11.0 &> /dev/null)
#		$(shell ./generate_assets.sh -s ./Image-Assets -o ./Resources &> /dev/null)
		$(shell rm -f Resources/partial.plist)
    else
		@echo "> Generating bundle images"
    	$(shell  rm -f Resources/Assets.car ||:)
    	$(shell rm -f ./Resources/*.png; cp ./Image-Assets/SettingsIcon-large.png ./Resources/AppIcon-large.png)
    	$(shell ./generate_images.sh -s ./Image-Assets -o ./Resources &> /dev/null)
    endif
