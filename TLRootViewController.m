#import <objc/objc.h>
#import <UIKit/UIColor+Private.h>
#import "TLRootViewController.h"

@interface TLRootViewController () {
    BOOL locked;
    double LEDLevel;
    int WarmLEDPercentile;
    int CoolLED0Level;
    int CoolLED1Level;
    int WarmLED0Level;
    int WarmLED1Level;
}
@property (nonatomic, strong) TLDeviceManager *deviceManager;
@property (nonatomic, strong) NSMutableArray <UISlider *> *sliders;
@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *sliderConstraints;
@property (nonatomic, strong) NSMutableArray <UILabel *> *sliderLabels;
@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *sliderLabelConstraints;
@property (nonatomic, strong) NSMutableArray <UILabel *> *sliderValueLabels;
@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *sliderValueLabelConstraints;
@property (nonatomic, strong) UISwitch *lockSwitch;
@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *lockSwitchConstraints;
@property (nonatomic, strong) UILabel *lockSwitchLabel;
@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *lockSwitchLabelConstraints;
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
    [_deviceManager setupStream];
    [_deviceManager checkType];
}

- (void)setupStream {
    [_deviceManager setupStream];
}

- (void)releaseStream {
    [_deviceManager releaseStream];
}

- (void)handleShortcutAction:(NSString *)shortcutType {
    BOOL legacy = [_deviceManager isLegacyLEDs];
    BOOL quad = [_deviceManager isQuadLEDs];
    if ([shortcutType isEqualToString:@"com.ps.TrollLEDs.AmberOn"]) {
        if (legacy) {
            LEDLevel = 100;
            WarmLEDPercentile = 100;
        } else {
            CoolLED0Level = 0;
            CoolLED1Level = 0;
            WarmLED0Level = 255;
            WarmLED1Level = quad ? 255 : 0;
        } 
    } else if ([shortcutType isEqualToString:@"com.ps.TrollLEDs.WhiteOn"]) {
        if (legacy) {
            LEDLevel = 100;
            WarmLEDPercentile = 0;
        } else {
            CoolLED0Level = 255;
            CoolLED1Level = quad ? 255 : 0;
            WarmLED0Level = 0;
            WarmLED1Level = 0;
        }
    } else if ([shortcutType isEqualToString:@"com.ps.TrollLEDs.AllOn"]) {
        if (!legacy) {
            CoolLED0Level = 255;
            CoolLED1Level = quad ? 255 : 0;
            WarmLED0Level = 255;
            WarmLED1Level = quad ? 255 : 0;
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
    [self.view addSubview:error];
    [NSLayoutConstraint activateConstraints:@[
        [error.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [error.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
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
    return locked ? @"On: Only TrollLEDs can control the LEDs" : @"Off: Release the LEDs to other apps (this may take few seconds)";
}

- (void)viewDidLoad {
	[super viewDidLoad];

    NSString *currentError = _deviceManager.currentError;
    if (currentError) {
        [self printError:currentError];
        return;
    }
    
    BOOL isLegacyLEDs = [_deviceManager isLegacyLEDs];

    UITableView *tableView = (UITableView *)self.view;
    tableView.scrollEnabled = NO;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = [UIColor blackColor];

    _sliders = [[NSMutableArray alloc] init];
    _sliderConstraints = [[NSMutableArray alloc] init];
    _sliderLabels = [[NSMutableArray alloc] init];
    _sliderLabelConstraints = [[NSMutableArray alloc] init];
    _sliderValueLabels = [[NSMutableArray alloc] init];
    _sliderValueLabelConstraints = [[NSMutableArray alloc] init];
    _lockSwitchConstraints = [[NSMutableArray alloc] init];
    _lockSwitchLabelConstraints = [[NSMutableArray alloc] init];
    int sliderCount = isLegacyLEDs ? 2 : 4;

    _lockSwitch = [[UISwitch alloc] init];
    _lockSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    _lockSwitch.on = locked = YES;
    [_lockSwitch addTarget:self action:@selector(lockStateChanged:) forControlEvents:UIControlEventValueChanged];

    [self.view addSubview:_lockSwitch];

    _lockSwitchLabel = [[UILabel alloc] init];
    _lockSwitchLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _lockSwitchLabel.text = [self switchLabel];
    _lockSwitchLabel.textColor = [UIColor systemGrayColor];
    _lockSwitchLabel.textAlignment = NSTextAlignmentCenter;
    _lockSwitchLabel.numberOfLines = 2;
    _lockSwitchLabel.font = [UIFont systemFontOfSize:14];

    [self.view addSubview:_lockSwitchLabel];

    for (NSInteger i = 0; i < sliderCount; i++) {
        UIColor *color = [self color:i];

        UISlider *slider = [[UISlider alloc] init];
        slider.translatesAutoresizingMaskIntoConstraints = NO;
        slider.minimumValue = 0;
        slider.maximumValue = isLegacyLEDs ? 100 : 255;
        slider.value = 0;
        slider.minimumTrackTintColor = color;
        slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
        slider.tag = i;
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

        [self.view addSubview:slider];
        [_sliders addObject:slider];

        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = [self labelText:i];
        label.textColor = color;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14];
        label.tag = i;

        UITapGestureRecognizer *labelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderValueTapped:)];
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

        UITapGestureRecognizer *valueLabelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderValueTapped:)];
        valueLabelTap.numberOfTapsRequired = 1;
        valueLabel.userInteractionEnabled = YES;
        [valueLabel addGestureRecognizer:valueLabelTap];

        [self.view addSubview:valueLabel];
        [_sliderValueLabels addObject:valueLabel];
    }

    if (_shortcutAction) {
        [self handleShortcutAction:_shortcutAction];
        _shortcutAction = nil;
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

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

    UISwitch *lockSwitch = _lockSwitch;

    NSLayoutConstraint *lockSwitchCenterX = [lockSwitch.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
    NSLayoutConstraint *lockSwitchTop = [lockSwitch.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20];

    [_lockSwitchConstraints addObjectsFromArray:@[lockSwitchCenterX, lockSwitchTop]];
    [NSLayoutConstraint activateConstraints:_lockSwitchConstraints];

    UILabel *lockSwitchLabel = _lockSwitchLabel;

    NSLayoutConstraint *lockSwitchLabelCenterX = [lockSwitchLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
    NSLayoutConstraint *lockSwitchLabelTop = [lockSwitchLabel.topAnchor constraintEqualToAnchor:lockSwitch.bottomAnchor constant:10];
    NSLayoutConstraint *lockSwitchLabelWidth = [lockSwitchLabel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.9];

    [_lockSwitchLabelConstraints addObjectsFromArray:@[lockSwitchLabelCenterX, lockSwitchLabelTop, lockSwitchLabelWidth]];
    [NSLayoutConstraint activateConstraints:_lockSwitchLabelConstraints];

    CGFloat sliderWidth = 30.0;
    CGFloat sliderHeight = self.view.bounds.size.height * 0.4;
    CGFloat totalSlidersWidth = _sliders.count * sliderWidth;
    CGFloat spacing = (self.view.bounds.size.width - totalSlidersWidth) / (_sliders.count + 1);

    for (NSInteger i = 0; i < _sliders.count; i++) {
        UISlider *slider = _sliders[i];

        NSLayoutConstraint *centerX = [slider.centerXAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:(i + 1) * spacing + i * sliderWidth + sliderWidth / 2];
        NSLayoutConstraint *centerY = [slider.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor];
        NSLayoutConstraint *width = [slider.widthAnchor constraintEqualToConstant:sliderHeight];
        NSLayoutConstraint *height = [slider.heightAnchor constraintEqualToConstant:sliderWidth];

        [_sliderConstraints addObjectsFromArray:@[centerX, centerY, width, height]];

        UILabel *label = _sliderLabels[i];

        NSLayoutConstraint *labelCenterX = [label.centerXAnchor constraintEqualToAnchor:slider.centerXAnchor];
        NSLayoutConstraint *labelTop = [label.topAnchor constraintEqualToAnchor:slider.bottomAnchor constant:sliderHeight / 2 + 10];

        [_sliderLabelConstraints addObjectsFromArray:@[labelCenterX, labelTop]];

        UILabel *valueLabel = _sliderValueLabels[i];

        NSLayoutConstraint *valueLabelCenterX = [valueLabel.centerXAnchor constraintEqualToAnchor:slider.centerXAnchor];
        NSLayoutConstraint *valueLabelTop = [valueLabel.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:10];

        [_sliderValueLabelConstraints addObjectsFromArray:@[valueLabelCenterX, valueLabelTop]];
    }

    [NSLayoutConstraint activateConstraints:_sliderConstraints];
    [NSLayoutConstraint activateConstraints:_sliderLabelConstraints];
    [NSLayoutConstraint activateConstraints:_sliderValueLabelConstraints];
}

- (void)sliderValueTapped:(UITapGestureRecognizer *)sender {
    if (!locked) return;
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
}

- (void)lockStateChanged:(UISwitch *)sender {
    locked = sender.on;
    if (locked)
        [_deviceManager setupStream];
    else {
        [_deviceManager setNumberProperty:CFSTR("TorchLevel") value:@(0)];
        [_deviceManager releaseStream];
    }
    _lockSwitchLabel.text = [self switchLabel];
    for (UISlider *slider in _sliders) {
        slider.value = 0;
        [self sliderValueChanged:slider];
        slider.enabled = locked;
        [slider setNeedsLayout];
    }
}

- (void)updateParameters {
    if ([_deviceManager isLegacyLEDs]) {
        NSNumber *torchLevelValue = @(LEDLevel);
        NSDictionary *torchColorValue = @{
            @"WarmLEDPercentile": @(WarmLEDPercentile)
        };
        [_deviceManager setNumberProperty:CFSTR("TorchLevel") value:torchLevelValue];
        [_deviceManager setDictionaryProperty:CFSTR("TorchColor") value:torchColorValue];
    } else {
        NSDictionary *params = @{
            @"CoolLED0Level": @(CoolLED0Level),
            @"CoolLED1Level": @(CoolLED1Level),
            @"WarmLED0Level": @(WarmLED0Level),
            @"WarmLED1Level": @(WarmLED1Level)
        };
        [_deviceManager setDictionaryProperty:CFSTR("TorchManualParameters") value:params];
    }
}

@end
