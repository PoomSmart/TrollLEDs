#import "TLDeviceManager.h"
#import <dlfcn.h>

@implementation TLDeviceManager

@synthesize currentError = _currentError;

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

- (void)checkType {
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    mach_port_t *kIOMasterPortDefault = (mach_port_t *)dlsym(IOKit, "kIOMasterPortDefault");
    CFMutableDictionaryRef (*IOServiceMatching)(const char *name) = (CFMutableDictionaryRef (*)(const char *))dlsym(IOKit, "IOServiceMatching");
    mach_port_t (*IOServiceGetMatchingService)(mach_port_t masterPort, CFDictionaryRef matching) = (mach_port_t (*)(mach_port_t, CFDictionaryRef))dlsym(IOKit, "IOServiceGetMatchingService");
    kern_return_t (*IOObjectRelease)(mach_port_t object) = (kern_return_t (*)(mach_port_t))dlsym(IOKit, "IOObjectRelease");
    mach_port_t h9 = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching("AppleH9CamIn"));
    mach_port_t h6 = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching("AppleH6CamIn"));
    legacyLEDs = h9 || h6;
    if (h9) IOObjectRelease(h9);
    if (h6) IOObjectRelease(h6);
}

- (BOOL)setupStream {
    if (initialized) return YES;
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
            _currentError = @"Could not register client";
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
            _currentError = @"Could not get device";
            return NO;
        }
    }
    if (streamRef) {
        const CMBaseVTable *vtable = CMBaseObjectGetVTable((CMBaseObjectRef)streamRef);
        streamSetProperty = vtable->baseClass->setProperty;
    } else
        stream = [vendor copyStreamForFlashlightWithPosition:1 deviceType:2 forDevice:device];
    if (!streamSetProperty && !stream) {
        _currentError = @"Could not get stream";
        return NO;
    }
    initialized = YES;
    return YES;
}

- (void)releaseStream {
    if ([vendor respondsToSelector:@selector(takeBackDevice:forClient:informClientWhenDeviceAvailableAgain:)])
        [vendor takeBackDevice:device forClient:client informClientWhenDeviceAvailableAgain:NO];
    else if ([vendor respondsToSelector:@selector(takeBackFlashlightDevice:forPID:)])
        [vendor takeBackFlashlightDevice:deviceRef forPID:pid];
    else if ([vendor respondsToSelector:@selector(takeBackDevice:forClient:)])
        [vendor takeBackDevice:deviceRef forClient:client];
    if (deviceRef)
        CFRelease(deviceRef);
    if (streamRef)
        CFRelease(streamRef);
    deviceRef = NULL;
    streamRef = NULL;
    streamSetProperty = NULL;
    device = nil;
    stream = nil;
    client = 0;
    initialized = NO;
}

- (BOOL)isLegacyLEDs {
    return legacyLEDs;
}

- (void)setProperty:(CFStringRef)property value:(id)value {
    if (stream)
        [stream setProperty:property value:value];
    else if (streamRef)
        streamSetProperty((CMBaseObjectRef)streamRef, property, (__bridge CFTypeRef)value);
}

@end
