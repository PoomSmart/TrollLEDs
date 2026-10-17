ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET = iphone:clang:latest:15.0
else
TARGET = iphone:clang:latest:10.0
endif
INSTALL_TARGET_PROCESSES = TrollLEDs
ARCHS = arm64
PACKAGE_VERSION = 1.11.0

APPLICATION_NAME = TrollLEDs
INFO_PLIST_IN = Resources/Info.plist.in
INFO_PLIST = Resources/Info.plist
APPLICATION_BUNDLE = $(THEOS_OBJ_DIR)/$(APPLICATION_NAME).app

include $(THEOS)/makefiles/common.mk

.PHONY: sync-version
sync-version:
	@sed 's/@PACKAGE_VERSION@/$(PACKAGE_VERSION)/g' $(INFO_PLIST_IN) > $(INFO_PLIST)
	@sed -i '' 's/^Version: .*/Version: $(PACKAGE_VERSION)/' control

ifeq ($(UNSANDBOX),1)
IPA_NAME = $(APPLICATION_NAME)-unsandboxed
else
IPA_NAME = $(APPLICATION_NAME)
endif

before-all:: sync-version

$(APPLICATION_NAME)_FILES = main.m TLDeviceManager.m TLSceneDelegate.m TLAppDelegate.m TLRootViewController.m TLLEDReader.m Intents.swift ShortcutsProvider.swift
$(APPLICATION_NAME)_FRAMEWORKS = UIKit CoreGraphics CoreMedia
$(APPLICATION_NAME)_CFLAGS = -fobjc-arc
ifeq ($(UNSANDBOX),1)
$(APPLICATION_NAME)_CODESIGN_FLAGS = -Sentitlements-unsandboxed.plist
else
$(APPLICATION_NAME)_CODESIGN_FLAGS = -Sentitlements.plist
endif

include $(THEOS_MAKE_PATH)/application.mk

before-stage::
	@if [ -f "$(APPLICATION_BUNDLE)/Info.plist" ]; then \
		plutil -replace CFBundleShortVersionString -string "$(PACKAGE_VERSION)" "$(APPLICATION_BUNDLE)/Info.plist"; \
		plutil -replace CFBundleVersion -string "$(PACKAGE_VERSION)" "$(APPLICATION_BUNDLE)/Info.plist"; \
	fi

ifeq ($(PACKAGE_FORMAT),ipa)
after-package::
	cp $(THEOS_PROJECT_DIR)/$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)_$(PACKAGE_VERSION).ipa $(THEOS_PROJECT_DIR)/$(IPA_NAME).tipa
endif
