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
#import <stdint.h>

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

/// Key for storing adaptive flash center LED level (0-255)
static NSString * const kTLCenterLEDLevelKey = @"TLCenterLEDLevel";

/// Key for storing adaptive flash corner LED level (0-255)
static NSString * const kTLCornerLEDLevelKey = @"TLCornerLEDLevel";

/// Key for storing adaptive flash side LED level (0-255)
static NSString * const kTLSideLEDLevelKey = @"TLSideLEDLevel";

/// Key for storing legacy torch level (0-100)
static NSString * const kTLTorchLevelKey = @"TLTorchLevel";

/// Key for storing legacy warmth percentile (0-100)
static NSString * const kTLWarmthPercentileKey = @"TLWarmthPercentile";

// MARK: - App Shortcut Actions
/// Shortcut action identifier for turning on amber LEDs
static NSString * const kTLShortcutAmberOn = @"com.ps.TrollLEDs.AmberOn";

/// Shortcut action identifier for turning on white LEDs
static NSString * const kTLShortcutWhiteOn = @"com.ps.TrollLEDs.WhiteOn";

/// Shortcut action identifier for the adaptive flash center group
static NSString * const kTLShortcutCenterOn = @"com.ps.TrollLEDs.CenterOn";

/// Shortcut action identifier for the adaptive flash ring (corners + sides)
static NSString * const kTLShortcutRingOn = @"com.ps.TrollLEDs.RingOn";

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

/// Number of sliders for adaptive True Tone (center, corners, sides)
static const int kTLSegmentedSliderCount = 3;

/// Bitmask for the center emitter on adaptive flash
static const uint64_t kTLSegmentLEDCenterMask = 0x10;

/// Bitmask for the four corner emitters (shared current)
static const uint64_t kTLSegmentLEDCornerMask = 0x145;

/// Bitmask for the four side emitters (shared current)
static const uint64_t kTLSegmentLEDSideMask = 0xAA;

/// Max sum of the three 0-255 group levels for sustained torch.
/// Firmware drops the request when center+corner+side milliamps reach 201 (about 180 mA per group).
/// 255+29 was the last combo that stayed on on iPhone 15 Pro.
static const int kTLSegmentedTorchLevelSumMax = 284;

// MARK: - UI Configuration
/// Horizontal space reserved for each vertical slider, including its thumb.
static const CGFloat kTLSliderWidth = 56.0;

/// Visible thumb diameter. The rest of kTLSliderWidth is shadow padding.
static const CGFloat kTLSliderThumbDiameter = 40.0;

/// Thickness of the rounded slider track.
static const CGFloat kTLSliderTrackThickness = 10.0;

/// Longest slider travel, so large screens keep even margins.
static const CGFloat kTLSliderMaxLength = 520.0;

/// Space between the slider group and the controls above and below it.
static const CGFloat kTLSliderGroupPadding = 16.0;

/// Space between the bottom of a slider and its name label.
static const CGFloat kTLSliderLabelSpacing = 12.0;

/// Space between a slider's name label and its value label.
static const CGFloat kTLSliderValueSpacing = 6.0;

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

/// Core Foundation string for TorchSegmentParameters property (adaptive flash)
#define kTLPropertyTorchSegmentParameters CFSTR("TorchSegmentParameters")

#endif /* TLConstants_h */
