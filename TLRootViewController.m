#import "TLRootViewController.h"
#include <objc/objc.h>
#import "Header.h"
#import <UIKit/UIColor+Private.h>
#import <dlfcn.h>

@interface TLRootViewController () {
    pid_t pid;
    int client;
    Class BWFigCaptureDeviceVendorClass;
    BWFigCaptureDeviceVendor *vendor;
    BWFigCaptureDevice *device;
    BWFigCaptureStream *stream;
    OpaqueFigCaptureDeviceRef deviceRef;
    OpaqueFigCaptureStreamRef streamRef;
    CMBaseObjectSetPropertyFunction streamSetProperty;
    BOOL dual;
    BOOL locked;
    double LEDLevel;
    int WarmLEDPercentile;
    int CoolLED0Level;
    int CoolLED1Level;
    int WarmLED0Level;
    int WarmLED1Level;
}
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

- (void)checkType {
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    mach_port_t *kIOMasterPortDefault = (mach_port_t *)dlsym(IOKit, "kIOMasterPortDefault");
    CFMutableDictionaryRef (*IOServiceMatching)(const char *name) = (CFMutableDictionaryRef (*)(const char *))dlsym(IOKit, "IOServiceMatching");
    mach_port_t (*IOServiceGetMatchingService)(mach_port_t masterPort, CFDictionaryRef matching) = (mach_port_t (*)(mach_port_t, CFDictionaryRef))dlsym(IOKit, "IOServiceGetMatchingService");
    kern_return_t (*IOObjectRelease)(mach_port_t object) = (kern_return_t (*)(mach_port_t))dlsym(IOKit, "IOObjectRelease");
    mach_port_t h9 = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching("AppleH9CamIn"));
    mach_port_t h6 = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching("AppleH6CamIn"));
    dual = h9 || h6;
    if (h9) IOObjectRelease(h9);
    if (h6) IOObjectRelease(h6);
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

- (void)initVendor {
    if (!dlopen("/System/Library/PrivateFrameworks/CMCapture.framework/CMCapture", RTLD_NOW))
        dlopen("/System/Library/PrivateFrameworks/Celestial.framework/Celestial", RTLD_NOW);
    BWFigCaptureDeviceVendorClass = NSClassFromString(@"BWFigCaptureDeviceVendor");
    if ([BWFigCaptureDeviceVendorClass respondsToSelector:@selector(sharedCaptureDeviceVendor)])
        vendor = [BWFigCaptureDeviceVendorClass sharedCaptureDeviceVendor];
    else
        vendor = [BWFigCaptureDeviceVendorClass sharedInstance];
    pid = getpid();
}

- (BOOL)setupStream {
    NSString *clientDescription = @"TrollLEDs application";
    if ([BWFigCaptureDeviceVendorClass respondsToSelector:@selector(copyDefaultVideoDeviceWithStealingBehavior:forPID:clientIDOut:withDeviceAvailabilityChangedHandler:)]) {
        deviceRef = [BWFigCaptureDeviceVendorClass copyDefaultVideoDeviceWithStealingBehavior:1 forPID:pid clientIDOut:&client withDeviceAvailabilityChangedHandler:NULL];
        streamRef = [BWFigCaptureDeviceVendorClass copyStreamForFlashlightWithPosition:1 deviceType:2 forDevice:deviceRef];
    } else {
        if ([vendor respondsToSelector:@selector(registerClientWithPID:clientDescription:clientPriority:canStealFromClientsWithSamePriority:deviceSharingWithOtherClientsAllowed:deviceAvailabilityChangedHandler:)])
            client = [vendor registerClientWithPID:pid clientDescription:clientDescription clientPriority:1 canStealFromClientsWithSamePriority:NO deviceSharingWithOtherClientsAllowed:YES deviceAvailabilityChangedHandler:NULL];
        else if ([vendor respondsToSelector:@selector(registerClientWithPID:clientDescription:stealingBehavior:deviceSharingWithOtherClientsAllowed:deviceAvailabilityChangedHandler:)])
            client = [vendor registerClientWithPID:pid clientDescription:clientDescription stealingBehavior:1 deviceSharingWithOtherClientsAllowed:YES deviceAvailabilityChangedHandler:NULL];
        else if ([vendor respondsToSelector:@selector(registerClientWithPID:stealingBehavior:deviceSharingWithOtherClientsAllowed:deviceAvailabilityChangedHandler:)])
            client = [vendor registerClientWithPID:pid stealingBehavior:1 deviceSharingWithOtherClientsAllowed:YES deviceAvailabilityChangedHandler:NULL];
        else {
            [self printError:@"Could not register client"];
            return NO;
        }
        int error;
        if ([vendor respondsToSelector:@selector(copyDeviceForClient:informClientWhenDeviceAvailableAgain:error:)])
            device = [vendor copyDeviceForClient:client informClientWhenDeviceAvailableAgain:NO error:&error];
        else if ([vendor respondsToSelector:@selector(copyDeviceForClient:error:)])
            device = [vendor copyDeviceForClient:client error:&error];
        else if ([vendor respondsToSelector:@selector(copyDeviceForClient:)]) {
            deviceRef = [vendor copyDeviceForClient:client];
            SEL selector = @selector(copyStreamForFlashlightWithPosition:deviceType:forDevice:);
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[vendor methodSignatureForSelector:selector]];
            inv.selector = selector;
            inv.target = vendor;
            int position = 1;
            [inv setArgument:&position atIndex:2];
            int deviceType = 2;
            [inv setArgument:&deviceType atIndex:3];
            [inv setArgument:&deviceRef atIndex:4];
            [inv invoke];
            [inv getReturnValue:&streamRef];
        } else {
            [self printError:@"Could not get device"];
            return NO;
        }
    }
    if (streamRef) {
        const CMBaseVTable *vtable = CMBaseObjectGetVTable((CMBaseObjectRef)streamRef);
        streamSetProperty = vtable->baseClass->setProperty;
    } else
        stream = [vendor copyStreamForFlashlightWithPosition:1 deviceType:2 forDevice:device];
    if (!streamSetProperty && !stream) {
        [self printError:@"Could not get stream"];
        return NO;
    }
    return YES;
}

- (void)releaseStream {
    if ([vendor respondsToSelector:@selector(takeBackDevice:forClient:informClientWhenDeviceAvailableAgain:)])
        [vendor takeBackDevice:device forClient:client informClientWhenDeviceAvailableAgain:NO];
    else if ([vendor respondsToSelector:@selector(takeBackFlashlightDevice:forPID:)])
        [vendor takeBackFlashlightDevice:deviceRef forPID:pid];
    else if ([vendor respondsToSelector:@selector(takeBackDevice:forClient:)])
        [vendor takeBackDevice:deviceRef forClient:client];
    if (streamRef)
        CFRelease(streamRef);
    deviceRef = NULL;
    streamRef = NULL;
    streamSetProperty = NULL;
    device = nil;
    stream = nil;
    client = 0;
}

- (NSString *)labelText:(int)index {
    if (dual) {
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
    BOOL isWarm = dual ? index == 1 : (index == 2 || index == 3);
    return isWarm ? [UIColor systemOrangeColor] : [UIColor whiteColor];
}

- (NSString *)switchLabel {
    return locked ? @"On: Only TrollLEDs can control the LEDs" : @"Off: Release the LEDs to other apps (this may take few seconds)";
}

- (void)viewDidLoad {
	[super viewDidLoad];
    [self initVendor];
	if (![self setupStream]) return;
    [self checkType];

    UITableView *tableView = (UITableView *)self.view;
    tableView.scrollEnabled = NO;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = [UIColor blackColor];

    self.sliders = [[NSMutableArray alloc] init];
    self.sliderConstraints = [[NSMutableArray alloc] init];
    self.sliderLabels = [[NSMutableArray alloc] init];
    self.sliderLabelConstraints = [[NSMutableArray alloc] init];
    self.sliderValueLabels = [[NSMutableArray alloc] init];
    self.sliderValueLabelConstraints = [[NSMutableArray alloc] init];
    self.lockSwitchConstraints = [[NSMutableArray alloc] init];
    self.lockSwitchLabelConstraints = [[NSMutableArray alloc] init];
    int sliderCount = dual ? 2 : 4;

    self.lockSwitch = [[UISwitch alloc] init];
    self.lockSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.lockSwitch.on = locked = YES;
    [self.lockSwitch addTarget:self action:@selector(lockStateChanged:) forControlEvents:UIControlEventValueChanged];

    [self.view addSubview:self.lockSwitch];

    self.lockSwitchLabel = [[UILabel alloc] init];
    self.lockSwitchLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.lockSwitchLabel.text = [self switchLabel];
    self.lockSwitchLabel.textColor = [UIColor systemGrayColor];
    self.lockSwitchLabel.textAlignment = NSTextAlignmentCenter;
    self.lockSwitchLabel.numberOfLines = 2;
    self.lockSwitchLabel.font = [UIFont systemFontOfSize:14];

    [self.view addSubview:self.lockSwitchLabel];

    for (NSInteger i = 0; i < sliderCount; i++) {
        UIColor *color = [self color:i];

        UISlider *slider = [[UISlider alloc] init];
        slider.translatesAutoresizingMaskIntoConstraints = NO;
        slider.minimumValue = 0;
        slider.maximumValue = dual ? 100 : 255;
        slider.value = 0;
        slider.minimumTrackTintColor = color;
        slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
        slider.tag = i;
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

        [self.view addSubview:slider];
        [self.sliders addObject:slider];

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
        [self.sliderLabels addObject:label];

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
        [self.sliderValueLabels addObject:valueLabel];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [NSLayoutConstraint deactivateConstraints:self.sliderConstraints];
    [NSLayoutConstraint deactivateConstraints:self.sliderLabelConstraints];
    [NSLayoutConstraint deactivateConstraints:self.sliderValueLabelConstraints];
    [NSLayoutConstraint deactivateConstraints:self.lockSwitchConstraints];
    [NSLayoutConstraint deactivateConstraints:self.lockSwitchLabelConstraints];
    [self.sliderConstraints removeAllObjects];
    [self.sliderLabelConstraints removeAllObjects];
    [self.sliderValueLabelConstraints removeAllObjects];
    [self.lockSwitchConstraints removeAllObjects];
    [self.lockSwitchLabelConstraints removeAllObjects];

    UISwitch *lockSwitch = self.lockSwitch;

    NSLayoutConstraint *lockSwitchCenterX = [lockSwitch.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
    NSLayoutConstraint *lockSwitchTop = [lockSwitch.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20];

    [self.lockSwitchConstraints addObjectsFromArray:@[lockSwitchCenterX, lockSwitchTop]];
    [NSLayoutConstraint activateConstraints:self.lockSwitchConstraints];

    UILabel *lockSwitchLabel = self.lockSwitchLabel;

    NSLayoutConstraint *lockSwitchLabelCenterX = [lockSwitchLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
    NSLayoutConstraint *lockSwitchLabelTop = [lockSwitchLabel.topAnchor constraintEqualToAnchor:lockSwitch.bottomAnchor constant:10];
    NSLayoutConstraint *lockSwitchLabelWidth = [lockSwitchLabel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.9];

    [self.lockSwitchLabelConstraints addObjectsFromArray:@[lockSwitchLabelCenterX, lockSwitchLabelTop, lockSwitchLabelWidth]];
    [NSLayoutConstraint activateConstraints:self.lockSwitchLabelConstraints];

    CGFloat sliderWidth = 30.0;
    CGFloat sliderHeight = self.view.bounds.size.height * 0.4;
    CGFloat totalSlidersWidth = self.sliders.count * sliderWidth;
    CGFloat spacing = (self.view.bounds.size.width - totalSlidersWidth) / (self.sliders.count + 1);

    for (NSInteger i = 0; i < self.sliders.count; i++) {
        UISlider *slider = self.sliders[i];

        NSLayoutConstraint *centerX = [slider.centerXAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:(i + 1) * spacing + i * sliderWidth + sliderWidth / 2];
        NSLayoutConstraint *centerY = [slider.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor];
        NSLayoutConstraint *width = [slider.widthAnchor constraintEqualToConstant:sliderHeight];
        NSLayoutConstraint *height = [slider.heightAnchor constraintEqualToConstant:sliderWidth];

        [self.sliderConstraints addObjectsFromArray:@[centerX, centerY, width, height]];

        UILabel *label = self.sliderLabels[i];

        NSLayoutConstraint *labelCenterX = [label.centerXAnchor constraintEqualToAnchor:slider.centerXAnchor];
        NSLayoutConstraint *labelTop = [label.topAnchor constraintEqualToAnchor:slider.bottomAnchor constant:sliderHeight / 2 + 10];

        [self.sliderLabelConstraints addObjectsFromArray:@[labelCenterX, labelTop]];

        UILabel *valueLabel = self.sliderValueLabels[i];

        NSLayoutConstraint *valueLabelCenterX = [valueLabel.centerXAnchor constraintEqualToAnchor:slider.centerXAnchor];
        NSLayoutConstraint *valueLabelTop = [valueLabel.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:10];

        [self.sliderValueLabelConstraints addObjectsFromArray:@[valueLabelCenterX, valueLabelTop]];
    }

    [NSLayoutConstraint activateConstraints:self.sliderConstraints];
    [NSLayoutConstraint activateConstraints:self.sliderLabelConstraints];
    [NSLayoutConstraint activateConstraints:self.sliderValueLabelConstraints];
}

- (void)sliderValueTapped:(UITapGestureRecognizer *)sender {
    if (!locked) return;
    UILabel *label = (UILabel *)sender.view;
    UISlider *slider = self.sliders[label.tag];
    if (slider.value == 0)
        slider.value = slider.maximumValue;
    else
        slider.value = 0;
    [self sliderValueChanged:slider];
}

- (void)sliderValueChanged:(UISlider *)sender {
    int value = round(sender.value);
    if (dual) {
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

    UILabel *valueLabel = self.sliderValueLabels[sender.tag];
    valueLabel.text = [NSString stringWithFormat:@"%d", value];

    [self updateParameters];
}

- (void)lockStateChanged:(UISwitch *)sender {
    locked = sender.on;
    if (locked)
        [self setupStream];
    else {
        if (stream)
            [stream setProperty:CFSTR("TorchLevel") value:@(0)];
        else if (streamRef)
            streamSetProperty((CMBaseObjectRef)streamRef, CFSTR("TorchLevel"), (__bridge CFNumberRef)@(0));
        [self releaseStream];
    }
    self.lockSwitchLabel.text = [self switchLabel];
    for (UISlider *slider in self.sliders) {
        slider.value = 0;
        [self sliderValueChanged:slider];
        slider.enabled = locked;
        [slider setNeedsLayout];
    }
    for (UILabel *label in self.sliderValueLabels) {
        label.text = @"0";
    }
}

- (void)updateParameters {
    if (dual) {
        NSNumber *torchLevelValue = @(LEDLevel);
        NSDictionary *torchColorValue = @{
            @"WarmLEDPercentile": @(WarmLEDPercentile)
        };
        if (stream) {
            [stream setProperty:CFSTR("TorchLevel") value:torchLevelValue];
            [stream setProperty:CFSTR("TorchColor") value:torchColorValue];
        } else if (streamRef) {
            streamSetProperty((CMBaseObjectRef)streamRef, CFSTR("TorchLevel"), (__bridge CFNumberRef)torchLevelValue);
            streamSetProperty((CMBaseObjectRef)streamRef, CFSTR("TorchColor"), (__bridge CFDictionaryRef)torchColorValue);
        }
    } else {
        NSDictionary *params = @{
            @"CoolLED0Level": @(CoolLED0Level),
            @"CoolLED1Level": @(CoolLED1Level),
            @"WarmLED0Level": @(WarmLED0Level),
            @"WarmLED1Level": @(WarmLED1Level)
        };
        if (stream)
            [stream setProperty:CFSTR("TorchManualParameters") value:params];
        else if (streamRef)
            streamSetProperty((CMBaseObjectRef)streamRef, CFSTR("TorchManualParameters"), (__bridge CFDictionaryRef)params);
    }
}

@end
