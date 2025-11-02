#import "TLDeviceManager.h"
#import <dlfcn.h>

/**
 * TLDeviceManager
 *
 * Manages the camera device and LED control for TrollLEDs.
 * Handles initialization, stream setup, and property setting for flashlight LEDs.
 */

@implementation TLDeviceManager

@synthesize currentError = _currentError;

/**
 * Ensures resources are cleaned up when the object is deallocated.
 * Automatically releases the camera device stream if still initialized.
 */
- (void)dealloc {
    // Ensure resources are cleaned up when the object is deallocated
    if (initialized) {
        [self releaseStream];
    }
}

/**
 * Initializes the camera device vendor.
 * Loads the required framework (CMCapture or Celestial) and obtains the vendor instance.
 * Sets currentError if initialization fails.
 */
- (void)initVendor {
    void *cmCaptureHandle = dlopen("/System/Library/PrivateFrameworks/CMCapture.framework/CMCapture", RTLD_NOW);
    if (!cmCaptureHandle) {
        void *celestialHandle = dlopen("/System/Library/PrivateFrameworks/Celestial.framework/Celestial", RTLD_NOW);
        if (!celestialHandle) {
            _currentError = @"Failed to load camera framework. Your device may not be supported.";
            return;
        }
    }

    BWFigCaptureDeviceVendorClass = NSClassFromString(@"BWFigCaptureDeviceVendor");
    if (!BWFigCaptureDeviceVendorClass) {
        _currentError = @"Camera device vendor class not found. This iOS version may not be supported.";
        return;
    }

    if ([BWFigCaptureDeviceVendorClass respondsToSelector:@selector(sharedCaptureDeviceVendor)])
        vendor = [BWFigCaptureDeviceVendorClass sharedCaptureDeviceVendor];
    else if ([BWFigCaptureDeviceVendorClass respondsToSelector:@selector(sharedInstance)])
        vendor = [BWFigCaptureDeviceVendorClass sharedInstance];

    if (!vendor) {
        _currentError = @"Failed to obtain camera device vendor. The camera may be in use by another app.";
        return;
    }

    pid = getpid();
}

/**
 * Checks the device type to determine if it uses legacy LEDs or modern quad-LEDs.
 * Legacy devices use AppleH6CamIn or AppleH9CamIn IOKit services.
 * Sets currentError if IOKit framework cannot be loaded.
 */
- (void)checkType {
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    if (!IOKit) {
        _currentError = @"Failed to load IOKit framework.";
        return;
    }

    mach_port_t *kIOMasterPortDefault = (mach_port_t *)dlsym(IOKit, "kIOMasterPortDefault");
    CFMutableDictionaryRef (*IOServiceMatching)(const char *name) =
        (CFMutableDictionaryRef(*)(const char *))dlsym(IOKit, "IOServiceMatching");
    mach_port_t (*IOServiceGetMatchingService)(mach_port_t masterPort, CFDictionaryRef matching) =
        (mach_port_t(*)(mach_port_t, CFDictionaryRef))dlsym(IOKit, "IOServiceGetMatchingService");
    kern_return_t (*IOObjectRelease)(mach_port_t object) =
        (kern_return_t(*)(mach_port_t))dlsym(IOKit, "IOObjectRelease");

    if (!kIOMasterPortDefault || !IOServiceMatching || !IOServiceGetMatchingService || !IOObjectRelease) {
        _currentError = @"Failed to load required IOKit symbols.";
        return;
    }

    mach_port_t h9 = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching("AppleH9CamIn"));
    mach_port_t h6 = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching("AppleH6CamIn"));
    legacyLEDs = h9 || h6;
    if (h9)
        IOObjectRelease(h9);
    if (h6)
        if (h6)
            IOObjectRelease(h6);
}

/**
 * Sets up the camera device stream for LED control.
 * This is the main initialization method that establishes connection to the camera device.
 *
 * @return YES if setup was successful, NO if it failed (with currentError set)
 *
 * The method handles multiple iOS versions and API variations, trying different
 * selectors based on what's available. Properly cleans up resources on failure.
 */
- (BOOL)setupStream {
    if (initialized)
        return YES;

    // Clear any previous errors
    _currentError = nil;

    if (!vendor && !BWFigCaptureDeviceVendorClass) {
        _currentError = @"Device vendor not initialized. Please restart the app.";
        return NO;
    }

    NSString *clientDescription = @"TrollLEDs application";
    if ([BWFigCaptureDeviceVendorClass
            respondsToSelector:@selector
            (copyDefaultVideoDeviceWithStealingBehavior:forPID:clientIDOut:withDeviceAvailabilityChangedHandler:)]) {
        deviceRef = [BWFigCaptureDeviceVendorClass copyDefaultVideoDeviceWithStealingBehavior:1
                                                                                       forPID:pid
                                                                                  clientIDOut:&client
                                                         withDeviceAvailabilityChangedHandler:NULL];
        if (!deviceRef) {
            _currentError = @"Failed to access camera device. The camera may be in use by another app.";
            return NO;
        }

        if ([BWFigCaptureDeviceVendorClass
                respondsToSelector:@selector(copyStreamForFlashlightWithPosition:deviceType:forDevice:)])
            streamRef = [BWFigCaptureDeviceVendorClass copyStreamForFlashlightWithPosition:1
                                                                                deviceType:2
                                                                                 forDevice:deviceRef];
        else
            streamRef = [BWFigCaptureDeviceVendorClass copyStreamWithPosition:1 deviceType:2 forDevice:deviceRef];

        if (!streamRef) {
            _currentError = @"Failed to create flashlight stream. Your device may not have controllable LEDs.";
            // Clean up deviceRef before returning
            if (deviceRef) {
                CFRelease(deviceRef);
                deviceRef = NULL;
            }
            return NO;
        }
    } else {
        if ([vendor respondsToSelector:@selector
                    (registerClientWithPID:
                         clientDescription:clientPriority:canStealFromClientsWithSamePriority
                                          :deviceSharingWithOtherClientsAllowed:deviceAvailabilityChangedHandler:)])
            client = [vendor registerClientWithPID:pid
                                   clientDescription:clientDescription
                                      clientPriority:1
                 canStealFromClientsWithSamePriority:NO
                deviceSharingWithOtherClientsAllowed:YES
                    deviceAvailabilityChangedHandler:NULL];
        else if ([vendor respondsToSelector:@selector
                         (registerClientWithPID:
                              clientDescription:stealingBehavior:deviceSharingWithOtherClientsAllowed
                                               :deviceAvailabilityChangedHandler:)])
            client = [vendor registerClientWithPID:pid
                                   clientDescription:clientDescription
                                    stealingBehavior:1
                deviceSharingWithOtherClientsAllowed:YES
                    deviceAvailabilityChangedHandler:NULL];
        else if ([vendor respondsToSelector:@selector(registerClientWithPID:
                                                           stealingBehavior:deviceSharingWithOtherClientsAllowed
                                                                           :deviceAvailabilityChangedHandler:)])
            client = [vendor registerClientWithPID:pid
                                    stealingBehavior:1
                deviceSharingWithOtherClientsAllowed:YES
                    deviceAvailabilityChangedHandler:NULL];
        else {
            _currentError = @"Unsupported iOS version. Cannot register camera client.";
            return NO;
        }

        if (client == 0) {
            _currentError = @"Failed to register as camera client. Try closing other camera apps.";
            return NO;
        }

        int error = 0;
        if ([vendor respondsToSelector:@selector(copyDeviceForClient:informClientWhenDeviceAvailableAgain:error:)])
            device = [vendor copyDeviceForClient:client informClientWhenDeviceAvailableAgain:NO error:&error];
        else if ([vendor respondsToSelector:@selector(copyDeviceForClient:error:)])
            device = [vendor copyDeviceForClient:client error:&error];
        else if ([vendor respondsToSelector:@selector(copyDeviceForClient:)]) {
            deviceRef = [vendor copyDeviceForClient:client];
            if (!deviceRef) {
                _currentError = @"Failed to obtain camera device. The camera may be locked by another app.";
                return NO;
            }

            SEL selector = @selector(copyStreamForFlashlightWithPosition:deviceType:forDevice:);
            NSInvocation *inv =
                [NSInvocation invocationWithMethodSignature:[vendor methodSignatureForSelector:selector]];
            inv.selector = selector;
            inv.target = vendor;
            int position = 1;
            [inv setArgument:&position atIndex:2];
            int deviceType = 2;
            [inv setArgument:&deviceType atIndex:3];
            [inv setArgument:&deviceRef atIndex:4];
            [inv invoke];
            [inv getReturnValue:&streamRef];

            if (!streamRef) {
                _currentError = @"Failed to create flashlight stream. Your device may not support LED control.";
                if (deviceRef) {
                    CFRelease(deviceRef);
                    deviceRef = NULL;
                }
                return NO;
            }
        } else {
            _currentError = @"Cannot access camera device on this iOS version.";
            return NO;
        }

        // Check if device was obtained successfully for non-deviceRef path
        if (!device && !deviceRef) {
            _currentError =
                error != 0
                    ? [NSString
                          stringWithFormat:@"Failed to get camera device (error code: %d). Try restarting the app.",
                                           error]
                    : @"Failed to get camera device. The camera may be in use.";
            return NO;
        }
    }

    if (streamRef) {
        @try {
            if (@available(iOS 11.0, *)) {
                const CMBaseVTable *vtable = CMBaseObjectGetVTable((CMBaseObjectRef)streamRef);
                if (vtable && vtable->baseClass) {
                    streamSetProperty = vtable->baseClass->setProperty;
                }
            } else {
                const CMBaseVTable_iOS10 *vtable =
                    (const CMBaseVTable_iOS10 *)CMBaseObjectGetVTable((CMBaseObjectRef)streamRef);
                if (vtable && vtable->baseClass) {
                    streamSetProperty = vtable->baseClass->setProperty;
                }
            }

            if (!streamSetProperty) {
                _currentError = @"Failed to obtain stream property setter. Device may not support this feature.";
                [self releaseStream];
                return NO;
            }
        } @catch (NSException *exception) {
            _currentError = [NSString stringWithFormat:@"Exception while setting up stream: %@", exception.reason];
            [self releaseStream];
            return NO;
        }
    } else if (device) {
        stream = [vendor copyStreamForFlashlightWithPosition:1 deviceType:2 forDevice:device];
        if (!stream) {
            _currentError = @"Failed to create flashlight stream. Your device may not support LED control.";
            [self releaseStream];
            return NO;
        }
    }

    if (!streamSetProperty && !stream) {
        _currentError = @"Could not initialize LED control. Your device may not be supported.";
        [self releaseStream];
        return NO;
    }

    initialized = YES;
    return YES;
}

/**
 * Releases the camera device stream and cleans up all resources.
 * Should be called when the app no longer needs to control the LEDs,
 * allowing other apps (like Camera) to use the device.
 *
 * Uses exception handling to ensure cleanup continues even if errors occur.
 * Safely releases Core Foundation objects with NULL checks.
 */
- (void)releaseStream {
    // Only attempt to take back the device if it was successfully initialized
    if (initialized) {
        @try {
            if ([vendor respondsToSelector:@selector(takeBackDevice:forClient:informClientWhenDeviceAvailableAgain:)])
                [vendor takeBackDevice:device forClient:client informClientWhenDeviceAvailableAgain:NO];
            else if ([vendor respondsToSelector:@selector(takeBackFlashlightDevice:forPID:)] && deviceRef)
                [vendor takeBackFlashlightDevice:deviceRef forPID:pid];
            else if ([vendor respondsToSelector:@selector(takeBackDevice:forClient:)] && deviceRef)
                [vendor takeBackDevice:deviceRef forClient:client];
            else if ([BWFigCaptureDeviceVendorClass
                         respondsToSelector:@selector
                         (takeBackVideoDevice:forPID:requestDeviceWhenAvailableAgain:informOtherClients:)] &&
                     deviceRef)
                [BWFigCaptureDeviceVendorClass takeBackVideoDevice:deviceRef
                                                            forPID:pid
                                   requestDeviceWhenAvailableAgain:NO
                                                informOtherClients:YES];
        } @catch (NSException *exception) {
            NSLog(@"TrollLEDs: Exception while releasing device: %@", exception.reason);
        }
    }

    // Safely release Core Foundation objects
    if (deviceRef) {
        CFRelease(deviceRef);
        deviceRef = NULL;
    }
    if (streamRef) {
        CFRelease(streamRef);
        streamRef = NULL;
    }

    // Clear all state
    streamSetProperty = NULL;
    device = nil;
    stream = nil;
    client = 0;
    initialized = NO;
}

/**
 * Returns whether the device uses legacy LED control (dual-LEDs).
 *
 * @return YES if device uses legacy LED API, NO for modern quad-LED API
 */
- (BOOL)isLegacyLEDs {
    return legacyLEDs;
}

/**
 * Sets a property on the camera device stream.
 * Used to control LED levels and behavior.
 *
 * @param property Core Foundation string key for the property to set
 * @param value The value to set for the property
 *
 * Handles both object-based and function pointer-based stream property setting.
 * Includes error handling to prevent crashes from invalid parameters.
 */
- (void)setProperty:(CFStringRef)property value:(id)value {
    if (!property || !value) {
        NSLog(@"TrollLEDs: Attempted to set property with nil property or value");
        return;
    }

    @try {
        if (stream) {
            [stream setProperty:property value:value];
        } else if (streamRef && streamSetProperty) {
            streamSetProperty((CMBaseObjectRef)streamRef, property, (__bridge CFTypeRef)value);
        } else {
            NSLog(@"TrollLEDs: Cannot set property - stream not initialized");
        }
    } @catch (NSException *exception) {
        NSLog(@"TrollLEDs: Exception while setting property: %@", exception.reason);
    }
}

@end
