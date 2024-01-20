#import "TLRootViewController.h"
#import "Header.h"
#import <UIKit/UIColor+Private.h>
#import <dlfcn.h>

@interface TLRootViewController () {
    BWFigCaptureStream *stream;
    OpaqueFigCaptureStreamRef streamRef;
    CMBaseObjectSetPropertyFunction streamSetProperty;
    BOOL dual;
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

- (BOOL)setupStream {
    pid_t pid = getpid();
    BWFigCaptureDeviceVendor *vendor;
    BWFigCaptureDevice *device;
    OpaqueFigCaptureDeviceRef deviceRef;
    int client;
    if (!dlopen("/System/Library/PrivateFrameworks/CMCapture.framework/CMCapture", RTLD_NOW))
        dlopen("/System/Library/PrivateFrameworks/Celestial.framework/Celestial", RTLD_NOW);
    Class BWFigCaptureDeviceVendorClass = NSClassFromString(@"BWFigCaptureDeviceVendor");
    if ([BWFigCaptureDeviceVendorClass respondsToSelector:@selector(sharedCaptureDeviceVendor)])
        vendor = [BWFigCaptureDeviceVendorClass sharedCaptureDeviceVendor];
    else
        vendor = [BWFigCaptureDeviceVendorClass sharedInstance];
    NSString *clientDescription = @"TrollLEDs application";
    if ([BWFigCaptureDeviceVendorClass respondsToSelector:@selector(copyDefaultVideoDeviceWithStealingBehavior:forPID:clientIDOut:withDeviceAvailabilityChangedHandler:)]) {
        deviceRef = [BWFigCaptureDeviceVendorClass copyDefaultVideoDeviceWithStealingBehavior:1 forPID:pid clientIDOut:&client withDeviceAvailabilityChangedHandler:NULL];
        streamRef = [BWFigCaptureDeviceVendorClass copyStreamForFlashlightWithPosition:1 deviceType:2 forDevice:deviceRef];
    } else {
        if ([vendor respondsToSelector:@selector(registerClientWithPID:clientDescription:clientPriority:canStealFromClientsWithSamePriority:deviceSharingWithOtherClientsAllowed:deviceAvailabilityChangedHandler:)])
            client = [vendor registerClientWithPID:pid clientDescription:clientDescription clientPriority:1 canStealFromClientsWithSamePriority:NO deviceSharingWithOtherClientsAllowed:NO deviceAvailabilityChangedHandler:NULL];
        else if ([vendor respondsToSelector:@selector(registerClientWithPID:clientDescription:stealingBehavior:deviceSharingWithOtherClientsAllowed:deviceAvailabilityChangedHandler:)])
            client = [vendor registerClientWithPID:pid clientDescription:clientDescription stealingBehavior:1 deviceSharingWithOtherClientsAllowed:NO deviceAvailabilityChangedHandler:NULL];
        else if ([vendor respondsToSelector:@selector(registerClientWithPID:stealingBehavior:deviceSharingWithOtherClientsAllowed:deviceAvailabilityChangedHandler:)])
            client = [vendor registerClientWithPID:pid stealingBehavior:1 deviceSharingWithOtherClientsAllowed:NO deviceAvailabilityChangedHandler:NULL];
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

- (void)viewDidLoad {
	[super viewDidLoad];
	if (![self setupStream]) return;
    [self checkType];

    self.sliders = [[NSMutableArray alloc] init];
    self.sliderConstraints = [[NSMutableArray alloc] init];
    self.sliderLabels = [[NSMutableArray alloc] init];
    self.sliderLabelConstraints = [[NSMutableArray alloc] init];
    self.sliderValueLabels = [[NSMutableArray alloc] init];
    self.sliderValueLabelConstraints = [[NSMutableArray alloc] init];
    int sliderCount = dual ? 2 : 4;

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

        [self.view addSubview:label];
        [self.sliderLabels addObject:label];

        UILabel *valueLabel = [[UILabel alloc] init];
        valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        valueLabel.text = @"0";
        valueLabel.textColor = color;
        valueLabel.textAlignment = NSTextAlignmentCenter;

        [self.view addSubview:valueLabel];
        [self.sliderValueLabels addObject:valueLabel];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [NSLayoutConstraint deactivateConstraints:self.sliderConstraints];
    [NSLayoutConstraint deactivateConstraints:self.sliderLabelConstraints];
    [NSLayoutConstraint deactivateConstraints:self.sliderValueLabelConstraints];
    [self.sliderConstraints removeAllObjects];
    [self.sliderLabelConstraints removeAllObjects];
    [self.sliderValueLabelConstraints removeAllObjects];

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
