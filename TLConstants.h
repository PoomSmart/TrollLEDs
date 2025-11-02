//
//  TLConstants.h
//  TrollLEDs
//
//  Constants and configuration values used throughout the application
//

#ifndef TLConstants_h
#define TLConstants_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

// MARK: - UserDefaults Keys
/// Key for storing whether the device uses quad LEDs (YES) or dual LEDs (NO)
static NSString * const kTLQuadLEDsKey = @"TLQuadLEDs";

/// Key for storing the lock state (YES = locked to TrollLEDs)
static NSString * const kTLLockStateKey = @"TLLockState";

/// Key for storing Cool LED 0 level (0-255)
static NSString * const kTLCoolLED0LevelKey = @"TLCoolLED0Level";

/// Key for storing Cool LED 1 level (0-255)
static NSString * const kTLCoolLED1LevelKey = @"TLCoolLED1Level";

/// Key for storing Warm LED 0 level (0-255)
static NSString * const kTLWarmLED0LevelKey = @"TLWarmLED0Level";

/// Key for storing Warm LED 1 level (0-255)
static NSString * const kTLWarmLED1LevelKey = @"TLWarmLED1Level";

/// Key for storing legacy torch level (0-100)
static NSString * const kTLTorchLevelKey = @"TLTorchLevel";

/// Key for storing legacy warmth percentile (0-100)
static NSString * const kTLWarmthPercentileKey = @"TLWarmthPercentile";

// MARK: - App Shortcut Actions
/// Shortcut action identifier for turning on amber LEDs
static NSString * const kTLShortcutAmberOn = @"com.ps.TrollLEDs.AmberOn";

/// Shortcut action identifier for turning on white LEDs
static NSString * const kTLShortcutWhiteOn = @"com.ps.TrollLEDs.WhiteOn";

/// Shortcut action identifier for turning on all LEDs
static NSString * const kTLShortcutAllOn = @"com.ps.TrollLEDs.AllOn";

/// Shortcut action identifier for turning off all LEDs
static NSString * const kTLShortcutAllOff = @"com.ps.TrollLEDs.AllOff";

/// Shortcut action identifier for manual LED control
static NSString * const kTLShortcutManual = @"com.ps.TrollLEDs.Manual";

// MARK: - LED Configuration
/// Maximum LED level for quad-LED devices
static const int kTLQuadLEDMaxLevel = 255;

/// Maximum level for legacy dual-LED devices
static const int kTLLegacyLEDMaxLevel = 100;

/// Number of sliders for legacy devices
static const int kTLLegacySliderCount = 2;

/// Number of sliders for quad-LED devices
static const int kTLQuadSliderCount = 4;

// MARK: - UI Configuration
/// Spacing multiplier for iPad layouts
static const CGFloat kTLiPadLayoutMultiplier = 0.4;

/// Spacing multiplier for iPhone layouts
static const CGFloat kTLiPhoneLayoutMultiplier = 0.3;

/// Slider width in points
static const CGFloat kTLSliderWidth = 30.0;

/// Font size for labels
static const CGFloat kTLLabelFontSize = 14.0;

/// Spacing constant for layout constraints
static const CGFloat kTLLayoutSpacing = 10.0;

/// Edge inset for constraints
static const CGFloat kTLEdgeInset = 20.0;

// MARK: - Background Task
/// Timeout in seconds before app auto-terminates in background
static const NSTimeInterval kTLBackgroundTimeout = 300.0; // 5 minutes

// MARK: - Accessibility Identifiers
static NSString * const kTLAccessibilityLockSwitch = @"ledControlLockSwitch";
static NSString * const kTLAccessibilityLEDCount = @"ledCountSegmentedControl";
static NSString * const kTLAccessibilityErrorLabel = @"errorLabel";

// MARK: - Property Keys (for flashlight control)
/// Core Foundation string for TorchLevel property
#define kTLPropertyTorchLevel CFSTR("TorchLevel")

/// Core Foundation string for TorchColor property
#define kTLPropertyTorchColor CFSTR("TorchColor")

/// Core Foundation string for TorchManualParameters property
#define kTLPropertyTorchManualParameters CFSTR("TorchManualParameters")

#endif /* TLConstants_h */
