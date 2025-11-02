# Changelog

All notable changes to TrollLEDs will be documented in this file.

## 1.10.0

• (iOS 16+) Added `Get LED Levels` app shortcut, which returns the current LED brightness levels (reads from hardware when locked, or from saved state when unlocked)
• Enhanced error handling and reporting throughout the app with more descriptive error messages
• Added comprehensive accessibility support for VoiceOver users with proper labels, hints, and traits for all UI controls
• Added state persistence - the app now remembers LED levels and lock state across app launches
• Improved memory management with proper resource cleanup and deallocation
• Optimized UI layout performance by caching constraints and reducing unnecessary layout passes
• Improved code documentation with detailed method descriptions

## 1.9.0

• Add support for iOS 10

## 1.8.1

• If TrollLEDs cannot access the camera device for managing LEDs, it will properly print the error instead of crashing the app outright
• (Rootless) Compiled with iOS 15 SDK as the deployment target

## 1.8.0

• (iOS 16+) Added `Manual` app shortcut, which allows you to configure the level of each LEDs separately (for Quad-LEDs devices only)
• (iOS 16+) Added `All Off` app shortcut, which turns off all LEDs
• `All On` shortcut will now turn on the single white LED on Dual-LEDs devices

## 1.7.0

• Added App shortcuts support (iOS 16+)

## 1.6.1

• Tweaked app icon
• Combined `-[TLDeviceManager setNumberProperty:value:]` and `-[TLDeviceManager setDictionaryProperty:value:]` into just `-[TLDeviceManager setProperty:value:]`

## 1.6.0

• Added `Physical LED Count` segmented control for "Programmatic Quad-LEDs devices" (devices with H10 camera or newer), where you can explicitly inform TrollLEDs how many physical flashlight LEDs does your device have

## 1.5.0

• TrollLEDs will terminate itself after 5 minutes of inactivity, this is to work around the possible battery drain issue when the app is left running in the background without killing it from the app switcher

## 1.4.0

• Added app shortcut menus (Amber On, White On and All On)
• Refactored lots of parts in the app

## 1.3.1

• Fixed sandbox version of TrollLEDs app crashing on launch (tested on iOS 16)

## 1.3.0

• TrollLEDs is now fully sandboxed (the entitlement `com.apple.system.diagnostics.iokit-properties` is used)
• You can now tap the slider value label to change the slider value to either 0 or max

## 1.2.1

• Fixed icon not rendered on iOS <= 14

## 1.2.0

• Added lock switch feature to control LED access
• Added FLEX support for debugging

## 1.1.2

• Fixed IPA build issues

## 1.1.1

• Version bump and minor fixes

## 1.1.0

• Added support for iOS 12 (and iOS 11, 13)
• Removed unused entitlements

## 1.0.0

• Initial release of TrollLEDs
