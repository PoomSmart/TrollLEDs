TARGET := iphone:clang:latest:11.0
INSTALL_TARGET_PROCESSES = TrollLEDs
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TrollLEDs

$(APPLICATION_NAME)_FILES = main.m TLSceneDelegate.m TLAppDelegate.m TLRootViewController.m
$(APPLICATION_NAME)_FRAMEWORKS = UIKit CoreGraphics CoreMedia
$(APPLICATION_NAME)_CFLAGS = -fobjc-arc -Wno-unguarded-availability-new

include $(THEOS_MAKE_PATH)/application.mk

after-stage::
	mkdir -p $(THEOS_STAGING_DIR)/Payload
	ldid -Sentitlements.plist $(THEOS_STAGING_DIR)/Applications/TrollLEDs.app/TrollLEDs
	cp -a $(THEOS_STAGING_DIR)/Applications/* $(THEOS_STAGING_DIR)/Payload
	mv $(THEOS_STAGING_DIR)/Payload .
	zip -q -r TrollLEDs.tipa Payload
	rm -rf Payload
