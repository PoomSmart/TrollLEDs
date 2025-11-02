#include <Foundation/Foundation.h>
#import <objc/objc.h>
#import <theos/IOSMacros.h>
#import <UIKit/UIColor+Private.h>
#import "TLRootViewController.h"
#import "TLConstants.h"

/**
 * TLRootViewController
 *
 * Main view controller for TrollLEDs application.
 * Manages LED control sliders and settings for both legacy and modern devices.
 */

@interface TLRootViewController () {
    BOOL locked;
    double LEDLevel;
    int WarmLEDPercentile;
    int CoolLED0Level;
    int CoolLED1Level;
    int WarmLED0Level;
    int WarmLED1Level;
    BOOL constraintsCreated; // Performance: Cache flag to avoid recreating constraints
    CGSize lastViewSize;     // Performance: Track view size changes for layout optimization
}

@property(nonatomic, strong) TLDeviceManager *deviceManager;
@property(nonatomic, strong) NSMutableArray<UISlider *> *sliders;
@property(nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *sliderConstraints;
@property(nonatomic, strong) NSMutableArray<UILabel *> *sliderLabels;
@property(nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *sliderLabelConstraints;
@property(nonatomic, strong) NSMutableArray<UILabel *> *sliderValueLabels;
@property(nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *sliderValueLabelConstraints;
@property(nonatomic, strong) UISwitch *lockSwitch;
@property(nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *lockSwitchConstraints;
@property(nonatomic, strong) UILabel *lockSwitchLabel;
@property(nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *lockSwitchLabelConstraints;
@property(nonatomic, strong) UISegmentedControl *ledCount;
@property(nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *ledCountConstraints;
@property(nonatomic, strong) UILabel *ledCountLabel;
@property(nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *ledCountLabelConstraints;
@end

@implementation TLRootViewController

@synthesize deviceManager = _deviceManager;
@synthesize shortcutAction = _shortcutAction;
@synthesize sliders = _sliders;
@synthesize sliderConstraints = _sliderConstraints;
@synthesize sliderLabels = _sliderLabels;
@synthesize sliderLabelConstraints = _sliderLabelConstraints;
@synthesize sliderValueLabels = _sliderValueLabels;
@synthesize sliderValueLabelConstraints = _sliderValueLabelConstraints;
@synthesize lockSwitch = _lockSwitch;
@synthesize lockSwitchConstraints = _lockSwitchConstraints;
@synthesize lockSwitchLabel = _lockSwitchLabel;
@synthesize lockSwitchLabelConstraints = _lockSwitchLabelConstraints;
@synthesize ledCount = _ledCount;
@synthesize ledCountConstraints = _ledCountConstraints;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initDeviceManager];
    }
    return self;
}

- (void)initDeviceManager {
    _deviceManager = [[TLDeviceManager alloc] init];
    [_deviceManager initVendor];

    // Check if vendor initialization failed
    if (_deviceManager.currentError) {
        return; // Error will be displayed in viewDidLoad
    }

    [_deviceManager checkType];

    // Check if device type detection failed
    if (_deviceManager.currentError) {
        return; // Error will be displayed in viewDidLoad
    }

    // Try to setup stream initially
    BOOL success = [_deviceManager setupStream];
    if (!success) {
        // Error is already set in currentError
        NSLog(@"TrollLEDs: Initial stream setup failed: %@", _deviceManager.currentError);
    }
}

- (void)setupStream {
    BOOL success = [_deviceManager setupStream];
    if (!success && _deviceManager.currentError) {
        // If setup fails, display error to user
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"LED Control Error"
                                                                       message:_deviceManager.currentError
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];

        // Also post accessibility notification
        UIAccessibilityPostNotification(
            UIAccessibilityAnnouncementNotification,
            [NSString stringWithFormat:@"LED Control Error: %@", _deviceManager.currentError]);
    }
}

- (void)releaseStream {
    @try {
        [_deviceManager releaseStream];
    } @catch (NSException *exception) {
        NSLog(@"TrollLEDs: Exception while releasing stream: %@", exception.reason);
        // Post accessibility notification about the error
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                        @"Warning: Error while releasing LED control");
    }
}

- (BOOL)isQuadLEDs {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kTLQuadLEDsKey];
}

#pragma mark - State Persistence

/**
 * Saves the current LED levels and lock state to UserDefaults.
 * This allows the app to restore the previous state on next launch.
 */
- (void)saveState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Save lock state
    [defaults setBool:locked forKey:kTLLockStateKey];

    // Save LED levels based on device type
    if ([_deviceManager isLegacyLEDs]) {
        [defaults setDouble:LEDLevel forKey:kTLTorchLevelKey];
        [defaults setInteger:WarmLEDPercentile forKey:kTLWarmthPercentileKey];
    } else {
        [defaults setInteger:CoolLED0Level forKey:kTLCoolLED0LevelKey];
        [defaults setInteger:CoolLED1Level forKey:kTLCoolLED1LevelKey];
        [defaults setInteger:WarmLED0Level forKey:kTLWarmLED0LevelKey];
        [defaults setInteger:WarmLED1Level forKey:kTLWarmLED1LevelKey];
    }

    [defaults synchronize];
}

/**
 * Restores the previously saved LED levels and lock state from UserDefaults.
 * Called during initialization to restore the last known state.
 */
- (void)restoreState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Restore lock state (default to YES if not set)
    if ([defaults objectForKey:kTLLockStateKey]) {
        locked = [defaults boolForKey:kTLLockStateKey];
    } else {
        locked = YES; // Default state
    }

    // Restore LED levels based on device type
    if ([_deviceManager isLegacyLEDs]) {
        if ([defaults objectForKey:kTLTorchLevelKey]) {
            LEDLevel = [defaults doubleForKey:kTLTorchLevelKey];
        }
        if ([defaults objectForKey:kTLWarmthPercentileKey]) {
            WarmLEDPercentile = [defaults integerForKey:kTLWarmthPercentileKey];
        }
    } else {
        if ([defaults objectForKey:kTLCoolLED0LevelKey]) {
            CoolLED0Level = (int)[defaults integerForKey:kTLCoolLED0LevelKey];
        }
        if ([defaults objectForKey:kTLCoolLED1LevelKey]) {
            CoolLED1Level = (int)[defaults integerForKey:kTLCoolLED1LevelKey];
        }
        if ([defaults objectForKey:kTLWarmLED0LevelKey]) {
            WarmLED0Level = (int)[defaults integerForKey:kTLWarmLED0LevelKey];
        }
        if ([defaults objectForKey:kTLWarmLED1LevelKey]) {
            WarmLED1Level = (int)[defaults integerForKey:kTLWarmLED1LevelKey];
        }
    }
}

/**
 * Applies the restored state to the UI sliders.
 * Should be called after UI elements are created.
 */
- (void)applyRestoredStateToUI {
    if (!_sliders || _sliders.count == 0)
        return;

    if ([_deviceManager isLegacyLEDs]) {
        if (_sliders.count > 0)
            _sliders[0].value = LEDLevel;
        if (_sliders.count > 1)
            _sliders[1].value = WarmLEDPercentile;
    } else {
        if (_sliders.count > 0)
            _sliders[0].value = CoolLED0Level;
        if (_sliders.count > 1)
            _sliders[1].value = CoolLED1Level;
        if (_sliders.count > 2)
            _sliders[2].value = WarmLED0Level;
        if (_sliders.count > 3)
            _sliders[3].value = WarmLED1Level;
    }

    // Update value labels
    for (int i = 0; i < _sliders.count; i++) {
        [self updateSliderValueLabel:i withValue:(int)_sliders[i].value];
    }

    // Apply to hardware if locked
    if (locked) {
        [self updateParameters];
    }
}

#pragma mark - Shortcut Handling

- (void)handleShortcutAction:(NSString *)shortcutType withParameters:(NSArray<NSURLQueryItem *> *)parameters {
    BOOL legacy = [_deviceManager isLegacyLEDs];
    BOOL quad = [self isQuadLEDs];
    if ([shortcutType isEqualToString:kTLShortcutAmberOn]) {
        if (legacy) {
            LEDLevel = 100;
            WarmLEDPercentile = 100;
        } else {
            CoolLED0Level = 0;
            CoolLED1Level = 0;
            WarmLED0Level = kTLQuadLEDMaxLevel;
            WarmLED1Level = quad ? kTLQuadLEDMaxLevel : 0;
        }
    } else if ([shortcutType isEqualToString:kTLShortcutWhiteOn]) {
        if (legacy) {
            LEDLevel = 100;
            WarmLEDPercentile = 0;
        } else {
            CoolLED0Level = kTLQuadLEDMaxLevel;
            CoolLED1Level = quad ? kTLQuadLEDMaxLevel : 0;
            WarmLED0Level = 0;
            WarmLED1Level = 0;
        }
    } else if ([shortcutType isEqualToString:kTLShortcutAllOn]) {
        if (legacy) {
            LEDLevel = 100;
        } else {
            CoolLED0Level = kTLQuadLEDMaxLevel;
            CoolLED1Level = quad ? kTLQuadLEDMaxLevel : 0;
            WarmLED0Level = kTLQuadLEDMaxLevel;
            WarmLED1Level = quad ? kTLQuadLEDMaxLevel : 0;
        }
    } else if ([shortcutType isEqualToString:kTLShortcutAllOff]) {
        if (legacy) {
            LEDLevel = 0;
        } else {
            CoolLED0Level = 0;
            CoolLED1Level = 0;
            WarmLED0Level = 0;
            WarmLED1Level = 0;
        }
    } else if ([shortcutType isEqualToString:kTLShortcutManual]) {
        if (!legacy) {
            for (NSURLQueryItem *parameter in parameters) {
                if ([parameter.name isEqualToString:@"coolLED0"])
                    CoolLED0Level = [parameter.value intValue];
                else if ([parameter.name isEqualToString:@"coolLED1"])
                    CoolLED1Level = [parameter.value intValue];
                else if ([parameter.name isEqualToString:@"warmLED0"])
                    WarmLED0Level = [parameter.value intValue];
                else if ([parameter.name isEqualToString:@"warmLED1"])
                    WarmLED1Level = [parameter.value intValue];
            }
        }
    }
    if (legacy) {
        _sliders[0].value = LEDLevel;
        _sliders[1].value = WarmLEDPercentile;
    } else {
        _sliders[0].value = CoolLED0Level;
        _sliders[1].value = CoolLED1Level;
        _sliders[2].value = WarmLED0Level;
        _sliders[3].value = WarmLED1Level;
    }
    for (int i = 0; i < _sliders.count; i++)
        [self updateSliderValueLabel:i withValue:_sliders[i].value];
    [self updateParameters];
}

- (void)printError:(NSString *)errorText {
    UILabel *error = [[UILabel alloc] init];
    error.translatesAutoresizingMaskIntoConstraints = NO;
    error.text = errorText;
    error.textColor = [UIColor systemRedColor];
    error.textAlignment = NSTextAlignmentCenter;
    error.numberOfLines = 2;

    // Accessibility support for error messages
    error.isAccessibilityElement = YES;
    error.accessibilityLabel = @"Error";
    error.accessibilityValue = errorText;
    error.accessibilityTraits = UIAccessibilityTraitStaticText;
    error.accessibilityIdentifier = @"errorLabel";

    [self.view addSubview:error];
    [NSLayoutConstraint activateConstraints:@[
        [error.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [error.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [error.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [error.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20]
    ]];

    // Post accessibility announcement for immediate feedback
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                    [NSString stringWithFormat:@"Error: %@", errorText]);
}

- (NSString *)labelText:(int)index {
    if ([_deviceManager isLegacyLEDs]) {
        switch (index) {
            case 0:
                return @"Torch Level";
            case 1:
                return @"Warmth";
        }
    } else {
        switch (index) {
            case 0:
                return @"Cool LED 0";
            case 1:
                return @"Cool LED 1";
            case 2:
                return @"Warm LED 0";
            case 3:
                return @"Warm LED 1";
        }
    }
    return @"";
}

- (UIColor *)color:(int)index {
    BOOL isWarm = [_deviceManager isLegacyLEDs] ? index == 1 : (index == 2 || index == 3);
    return isWarm ? [UIColor systemOrangeColor] : [UIColor whiteColor];
}

- (NSString *)switchLabel {
    return locked ? @"On: Only TrollLEDs can control the LEDs"
                  : @"Off: Release the LEDs to other apps (this may take few seconds)";
}

- (void)configureTableView {
    UITableView *tableView = (UITableView *)self.view;
    tableView.scrollEnabled = NO;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = [UIColor blackColor];
}

- (void)configureLockSwitch {
    _lockSwitchConstraints = [[NSMutableArray alloc] init];
    _lockSwitchLabelConstraints = [[NSMutableArray alloc] init];

    _lockSwitch = [[UISwitch alloc] init];
    _lockSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    _lockSwitch.on = locked = YES;
    [_lockSwitch addTarget:self action:@selector(lockStateChanged:) forControlEvents:UIControlEventValueChanged];

    // Accessibility support
    _lockSwitch.isAccessibilityElement = YES;
    _lockSwitch.accessibilityLabel = @"LED Control Lock";
    _lockSwitch.accessibilityHint =
        @"When on, only TrollLEDs can control the LEDs. When off, other apps can use the flashlight.";
    _lockSwitch.accessibilityIdentifier = @"ledControlLockSwitch";

    [self.view addSubview:_lockSwitch];

    _lockSwitchLabel = [[UILabel alloc] init];
    _lockSwitchLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _lockSwitchLabel.text = [self switchLabel];
    _lockSwitchLabel.textColor = [UIColor systemGrayColor];
    _lockSwitchLabel.textAlignment = NSTextAlignmentCenter;
    _lockSwitchLabel.numberOfLines = 2;
    _lockSwitchLabel.font = [UIFont systemFontOfSize:14];

    // Accessibility support
    _lockSwitchLabel.isAccessibilityElement = NO; // Label is descriptive, switch is interactive

    [self.view addSubview:_lockSwitchLabel];
}

- (void)configureLEDCount {
    _ledCountConstraints = [[NSMutableArray alloc] init];
    _ledCountLabelConstraints = [[NSMutableArray alloc] init];

    _ledCount = [[UISegmentedControl alloc] initWithItems:@[ @"Dual", @"Quad" ]];
    _ledCount.translatesAutoresizingMaskIntoConstraints = NO;
    _ledCount.selectedSegmentIndex = [self isQuadLEDs] ? 1 : 0;
    [_ledCount addTarget:self action:@selector(ledCountChanged:) forControlEvents:UIControlEventValueChanged];

    // Accessibility support
    _ledCount.isAccessibilityElement = YES;
    _ledCount.accessibilityLabel = @"Physical LED Count";
    _ledCount.accessibilityHint =
        @"Select Dual for devices with two physical LEDs or Quad for devices with four physical LEDs";
    _ledCount.accessibilityIdentifier = @"ledCountSegmentedControl";

    [self.view addSubview:_ledCount];

    _ledCountLabel = [[UILabel alloc] init];
    _ledCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _ledCountLabel.text = @"Physical LED Count";
    _ledCountLabel.textColor = [UIColor systemGrayColor];
    _ledCountLabel.textAlignment = NSTextAlignmentCenter;
    _ledCountLabel.font = [UIFont systemFontOfSize:14];

    // Accessibility support
    _ledCountLabel.isAccessibilityElement = NO; // Label is descriptive, control is interactive

    [self.view addSubview:_ledCountLabel];
}

- (void)configureLEDSliders:(int)sliderCount maximumValue:(int)maximumValue {
    _sliders = [[NSMutableArray alloc] init];
    _sliderConstraints = [[NSMutableArray alloc] init];
    _sliderLabels = [[NSMutableArray alloc] init];
    _sliderLabelConstraints = [[NSMutableArray alloc] init];
    _sliderValueLabels = [[NSMutableArray alloc] init];
    _sliderValueLabelConstraints = [[NSMutableArray alloc] init];

    for (NSInteger i = 0; i < sliderCount; i++) {
        UIColor *color = [self color:i];

        UISlider *slider = [[UISlider alloc] init];
        slider.translatesAutoresizingMaskIntoConstraints = NO;
        slider.minimumValue = 0;
        slider.maximumValue = maximumValue;
        slider.value = 0;
        slider.minimumTrackTintColor = color;
        slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
        slider.tag = i;
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

        // Accessibility support
        slider.isAccessibilityElement = YES;
        slider.accessibilityLabel = [self labelText:i];
        slider.accessibilityHint = @"Adjust LED brightness level. Double tap and hold to adjust the value.";
        slider.accessibilityIdentifier = [NSString stringWithFormat:@"ledSlider%ld", (long)i];

        [self.view addSubview:slider];
        [_sliders addObject:slider];

        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = [self labelText:i];
        label.textColor = color;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14];
        label.tag = i;

        // Accessibility support
        label.isAccessibilityElement = YES;
        label.accessibilityLabel = [NSString stringWithFormat:@"%@ label", [self labelText:i]];
        label.accessibilityHint = @"Tap to toggle this LED on or off";
        label.accessibilityTraits = UIAccessibilityTraitButton;
        label.accessibilityIdentifier = [NSString stringWithFormat:@"ledLabel%ld", (long)i];

        UITapGestureRecognizer *labelTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderValueTapped:)];
        labelTap.numberOfTapsRequired = 1;
        label.userInteractionEnabled = YES;
        [label addGestureRecognizer:labelTap];

        [self.view addSubview:label];
        [_sliderLabels addObject:label];

        UILabel *valueLabel = [[UILabel alloc] init];
        valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        valueLabel.text = @"0";
        valueLabel.textColor = color;
        valueLabel.textAlignment = NSTextAlignmentCenter;
        valueLabel.tag = i;

        // Accessibility support
        valueLabel.isAccessibilityElement = YES;
        valueLabel.accessibilityLabel = [NSString stringWithFormat:@"%@ value", [self labelText:i]];
        valueLabel.accessibilityHint = @"Current LED brightness value. Tap to toggle this LED on or off";
        valueLabel.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitUpdatesFrequently;
        valueLabel.accessibilityIdentifier = [NSString stringWithFormat:@"ledValue%ld", (long)i];

        UITapGestureRecognizer *valueLabelTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderValueTapped:)];
        valueLabelTap.numberOfTapsRequired = 1;
        valueLabel.userInteractionEnabled = YES;
        [valueLabel addGestureRecognizer:valueLabelTap];

        [self.view addSubview:valueLabel];
        [_sliderValueLabels addObject:valueLabel];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureTableView];

    NSString *currentError = _deviceManager.currentError;
    if (currentError) {
        [self printError:currentError];
        return;
    }

    BOOL isLegacyLEDs = [_deviceManager isLegacyLEDs];
    int sliderCount = isLegacyLEDs ? kTLLegacySliderCount : kTLQuadSliderCount;
    int maxValue = isLegacyLEDs ? kTLLegacyLEDMaxLevel : kTLQuadLEDMaxLevel;

    // Restore state before configuring UI
    [self restoreState];

    [self configureLockSwitch];
    if (!isLegacyLEDs)
        [self configureLEDCount];
    [self configureLEDSliders:sliderCount maximumValue:maxValue];

    // Apply restored state to UI elements
    [self applyRestoredStateToUI];

    if (_shortcutAction) {
        [self handleShortcutAction:_shortcutAction withParameters:nil];
        _shortcutAction = nil;
    }
}

/**
 * Layout pass for view. Optimized to only recreate constraints when view size changes.
 * This improves performance by avoiding unnecessary constraint calculations.
 */
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    NSString *currentError = _deviceManager.currentError;
    if (currentError)
        return;

    // Performance optimization: Only recreate constraints if view size changed
    if (constraintsCreated && CGSizeEqualToSize(lastViewSize, self.view.bounds.size)) {
        return;
    }

    lastViewSize = self.view.bounds.size;
    BOOL isLegacyLEDs = [_deviceManager isLegacyLEDs];

    // Deactivate and clear existing constraints
    [self deactivateAllConstraints:isLegacyLEDs];

    // Setup constraints for each UI element
    [self setupLockSwitchConstraints];
    if (!isLegacyLEDs) {
        [self setupLEDCountConstraints];
    }
    [self setupSliderConstraints:isLegacyLEDs];

    constraintsCreated = YES;
}

/**
 * Deactivates and clears all layout constraints.
 * Helper method to keep viewWillLayoutSubviews more readable.
 */
- (void)deactivateAllConstraints:(BOOL)isLegacyLEDs {
    [NSLayoutConstraint deactivateConstraints:_sliderConstraints];
    [NSLayoutConstraint deactivateConstraints:_sliderLabelConstraints];
    [NSLayoutConstraint deactivateConstraints:_sliderValueLabelConstraints];
    [NSLayoutConstraint deactivateConstraints:_lockSwitchConstraints];
    [NSLayoutConstraint deactivateConstraints:_lockSwitchLabelConstraints];

    [_sliderConstraints removeAllObjects];
    [_sliderLabelConstraints removeAllObjects];
    [_sliderValueLabelConstraints removeAllObjects];
    [_lockSwitchConstraints removeAllObjects];
    [_lockSwitchLabelConstraints removeAllObjects];

    if (!isLegacyLEDs) {
        [NSLayoutConstraint deactivateConstraints:_ledCountConstraints];
        [NSLayoutConstraint deactivateConstraints:_ledCountLabelConstraints];
        [_ledCountConstraints removeAllObjects];
        [_ledCountLabelConstraints removeAllObjects];
    }
}

/**
 * Sets up constraints for the lock switch and its label.
 */
- (void)setupLockSwitchConstraints {
    NSLayoutConstraint *lockSwitchCenterX = [_lockSwitch.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
    NSLayoutConstraint *lockSwitchTop = [_lockSwitch.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                                                              constant:kTLEdgeInset];

    [_lockSwitchConstraints addObjectsFromArray:@[ lockSwitchCenterX, lockSwitchTop ]];
    [NSLayoutConstraint activateConstraints:_lockSwitchConstraints];

    NSLayoutConstraint *lockSwitchLabelCenterX =
        [_lockSwitchLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
    NSLayoutConstraint *lockSwitchLabelTop =
        [_lockSwitchLabel.topAnchor constraintEqualToAnchor:_lockSwitch.bottomAnchor constant:kTLLayoutSpacing];
    NSLayoutConstraint *lockSwitchLabelWidth =
        [_lockSwitchLabel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.9];

    [_lockSwitchLabelConstraints
        addObjectsFromArray:@[ lockSwitchLabelCenterX, lockSwitchLabelTop, lockSwitchLabelWidth ]];
    [NSLayoutConstraint activateConstraints:_lockSwitchLabelConstraints];
}

/**
 * Sets up constraints for the LED count segmented control and its label.
 */
- (void)setupLEDCountConstraints {
    NSLayoutConstraint *ledCountCenterX = [_ledCount.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
    NSLayoutConstraint *ledCountBottom;
    if (@available(iOS 11.0, *)) {
        ledCountBottom = [_ledCount.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor
                                                                constant:-kTLEdgeInset];
    } else {
        ledCountBottom = [_ledCount.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-kTLEdgeInset];
    }

    [_ledCountConstraints addObjectsFromArray:@[ ledCountCenterX, ledCountBottom ]];
    [NSLayoutConstraint activateConstraints:_ledCountConstraints];

    NSLayoutConstraint *ledCountLabelCenterX =
        [_ledCountLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
    NSLayoutConstraint *ledCountLabelBottom = [_ledCountLabel.bottomAnchor constraintEqualToAnchor:_ledCount.topAnchor
                                                                                          constant:-kTLLayoutSpacing];

    [_ledCountLabelConstraints addObjectsFromArray:@[ ledCountLabelCenterX, ledCountLabelBottom ]];
    [NSLayoutConstraint activateConstraints:_ledCountLabelConstraints];
}

/**
 * Sets up constraints for LED sliders and their labels.
 * Calculates optimal spacing based on slider count and view width.
 */
- (void)setupSliderConstraints:(BOOL)isLegacyLEDs {
    CGFloat sliderWidth = kTLSliderWidth;
    CGFloat sliderHeightMultiplier = (IS_IPAD || isLegacyLEDs) ? kTLiPadLayoutMultiplier : kTLiPhoneLayoutMultiplier;
    CGFloat sliderHeight = self.view.bounds.size.height * sliderHeightMultiplier;
    CGFloat totalSlidersWidth = _sliders.count * sliderWidth;
    CGFloat spacing = (self.view.bounds.size.width - totalSlidersWidth) / (_sliders.count + 1);

    for (NSInteger i = 0; i < _sliders.count; i++) {
        UISlider *slider = _sliders[i];

        NSLayoutConstraint *centerX =
            [slider.centerXAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                                 constant:(i + 1) * spacing + i * sliderWidth + sliderWidth / 2];
        NSLayoutConstraint *centerY = [slider.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor];
        NSLayoutConstraint *width = [slider.widthAnchor constraintEqualToConstant:sliderHeight];
        NSLayoutConstraint *height = [slider.heightAnchor constraintEqualToConstant:sliderWidth];

        [_sliderConstraints addObjectsFromArray:@[ centerX, centerY, width, height ]];

        UILabel *label = _sliderLabels[i];

        NSLayoutConstraint *labelCenterX = [label.centerXAnchor constraintEqualToAnchor:slider.centerXAnchor];
        NSLayoutConstraint *labelTop = [label.topAnchor constraintEqualToAnchor:slider.bottomAnchor
                                                                       constant:sliderHeight / 2 + 10];

        [_sliderLabelConstraints addObjectsFromArray:@[ labelCenterX, labelTop ]];

        UILabel *valueLabel = _sliderValueLabels[i];

        NSLayoutConstraint *valueLabelCenterX = [valueLabel.centerXAnchor constraintEqualToAnchor:slider.centerXAnchor];
        NSLayoutConstraint *valueLabelTop = [valueLabel.topAnchor constraintEqualToAnchor:label.bottomAnchor
                                                                                 constant:10];

        [_sliderValueLabelConstraints addObjectsFromArray:@[ valueLabelCenterX, valueLabelTop ]];
    }

    [NSLayoutConstraint activateConstraints:_sliderConstraints];
    [NSLayoutConstraint activateConstraints:_sliderLabelConstraints];
    [NSLayoutConstraint activateConstraints:_sliderValueLabelConstraints];
}

- (void)ledCountChanged:(UISegmentedControl *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.selectedSegmentIndex == 1 forKey:kTLQuadLEDsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)sliderValueTapped:(UITapGestureRecognizer *)sender {
    if (!locked)
        return;
    UILabel *label = (UILabel *)sender.view;
    UISlider *slider = _sliders[label.tag];
    if (slider.value == 0)
        slider.value = slider.maximumValue;
    else
        slider.value = 0;
    [self sliderValueChanged:slider];
}

- (void)updateSliderValueLabel:(int)tag withValue:(int)value {
    UILabel *valueLabel = _sliderValueLabels[tag];
    valueLabel.text = [NSString stringWithFormat:@"%d", value];

    // Update accessibility value for better VoiceOver experience
    valueLabel.accessibilityValue = [NSString stringWithFormat:@"%d", value];

    // Update slider accessibility value
    UISlider *slider = _sliders[tag];
    slider.accessibilityValue = [NSString stringWithFormat:@"%d percent", (int)((value / slider.maximumValue) * 100)];
}

- (void)sliderValueChanged:(UISlider *)sender {
    int value = round(sender.value);
    if ([_deviceManager isLegacyLEDs]) {
        switch (sender.tag) {
            case 0:
                LEDLevel = sender.value / 100;
                break;
            case 1:
                WarmLEDPercentile = value;
                break;
        }
    } else {
        switch (sender.tag) {
            case 0:
                CoolLED0Level = value;
                break;
            case 1:
                CoolLED1Level = value;
                break;
            case 2:
                WarmLED0Level = value;
                break;
            case 3:
                WarmLED1Level = value;
                break;
        }
    }

    [self updateSliderValueLabel:sender.tag withValue:value];
    [self updateParameters];

    // Save state whenever slider value changes
    [self saveState];
}

- (void)lockStateChanged:(UISwitch *)sender {
    locked = sender.on;
    if (locked)
        [_deviceManager setupStream];
    else {
        [_deviceManager setProperty:kTLPropertyTorchLevel value:@(0)];
        [_deviceManager releaseStream];
    }
    _lockSwitchLabel.text = [self switchLabel];

    // Update accessibility for lock switch
    _lockSwitch.accessibilityValue = locked ? @"On" : @"Off";

    for (UISlider *slider in _sliders) {
        slider.value = 0;
        [self sliderValueChanged:slider];
        slider.enabled = locked;

        // Update accessibility traits based on enabled state
        if (locked) {
            slider.accessibilityTraits = UIAccessibilityTraitAdjustable;
        } else {
            slider.accessibilityTraits = UIAccessibilityTraitAdjustable | UIAccessibilityTraitNotEnabled;
        }

        [slider setNeedsLayout];
    }

    // Save state when lock state changes
    [self saveState];
}

- (void)updateParameters {
    if ([_deviceManager isLegacyLEDs]) {
        NSNumber *torchLevelValue = @(LEDLevel);
        NSDictionary *torchColorValue = @{@"WarmLEDPercentile" : @(WarmLEDPercentile)};
        [_deviceManager setProperty:kTLPropertyTorchLevel value:torchLevelValue];
        [_deviceManager setProperty:kTLPropertyTorchColor value:torchColorValue];
    } else {
        NSDictionary *params = @{
            @"CoolLED0Level" : @(CoolLED0Level),
            @"CoolLED1Level" : @(CoolLED1Level),
            @"WarmLED0Level" : @(WarmLED0Level),
            @"WarmLED1Level" : @(WarmLED1Level)
        };
        [_deviceManager setProperty:kTLPropertyTorchManualParameters value:params];
    }
}

@end
