ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET = iphone:clang:latest:15.0
else
TARGET = iphone:clang:latest:10.0
endif
INSTALL_TARGET_PROCESSES = TrollLEDs
ARCHS = arm64
PACKAGE_VERSION = 1.10.0

include $(THEOS)/makefiles/common.mk

# Update Info.plist version from PACKAGE_VERSION
before-all::
	@plutil -replace CFBundleShortVersionString -string "$(PACKAGE_VERSION)" Resources/Info.plist
	@plutil -replace CFBundleVersion -string "$(PACKAGE_VERSION)" Resources/Info.plist

APPLICATION_NAME = TrollLEDs

ifeq ($(UNSANDBOX),1)
	IPA_NAME = $(APPLICATION_NAME)-unsandboxed
else
	IPA_NAME = $(APPLICATION_NAME)
endif

$(APPLICATION_NAME)_FILES = main.m TLDeviceManager.m TLSceneDelegate.m TLAppDelegate.m TLRootViewController.m TLLEDReader.m Intents.swift ShortcutsProvider.swift
$(APPLICATION_NAME)_FRAMEWORKS = UIKit CoreGraphics CoreMedia
$(APPLICATION_NAME)_CFLAGS = -fobjc-arc
ifeq ($(UNSANDBOX),1)
$(APPLICATION_NAME)_CODESIGN_FLAGS = -Sentitlements-unsandboxed.plist
else
$(APPLICATION_NAME)_CODESIGN_FLAGS = -Sentitlements.plist
endif

include $(THEOS_MAKE_PATH)/application.mk

ifeq ($(PACKAGE_FORMAT),ipa)
after-package::
	cp $(THEOS_PROJECT_DIR)/$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)_$(PACKAGE_VERSION).ipa $(THEOS_PROJECT_DIR)/$(IPA_NAME).tipa
endif
