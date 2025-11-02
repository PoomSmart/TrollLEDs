#import "TLLEDReader.h"
#import <UIKit/UIKit.h>
#import "TLAppDelegate.h"
#import "TLRootViewController.h"
#import "TLDeviceManager.h"
#import "TLConstants.h"

@implementation TLLEDReader

+ (NSDictionary *)getCurrentLEDLevels {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Try to get the device manager from the app delegate
    TLDeviceManager *deviceManager = nil;
    TLAppDelegate *appDelegate = (TLAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate && appDelegate.myViewController) {
        deviceManager = appDelegate.myViewController.deviceManager;
    }

    BOOL isLocked = [defaults boolForKey:kTLLockStateKey];
    result[@"isLocked"] = @(isLocked);

    // If device is locked and we have a device manager, try to read from hardware
    if (isLocked && deviceManager && [deviceManager isInitialized]) {
        @try {
            if ([deviceManager isLegacyLEDs]) {
                // For legacy devices, read torch level and warmth
                NSNumber *torchLevel = [deviceManager getProperty:kTLPropertyTorchLevel];
                NSDictionary *torchColor = [deviceManager getProperty:kTLPropertyTorchColor];

                if (torchLevel) {
                    result[@"torchLevel"] = torchLevel;
                }
                if (torchColor && torchColor[@"WarmLEDPercentile"]) {
                    result[@"warmth"] = torchColor[@"WarmLEDPercentile"];
                }

                // Fill in defaults for quad LED values (not applicable for legacy)
                result[@"coolLED0"] = @(0);
                result[@"coolLED1"] = @(0);
                result[@"warmLED0"] = @(0);
                result[@"warmLED1"] = @(0);

                result[@"source"] = @"hardware";
            } else {
                // For quad-LED devices, read manual parameters
                NSDictionary *manualParams = [deviceManager getProperty:kTLPropertyTorchManualParameters];

                if (manualParams) {
                    result[@"coolLED0"] = manualParams[@"CoolLED0Level"] ?: @(0);
                    result[@"coolLED1"] = manualParams[@"CoolLED1Level"] ?: @(0);
                    result[@"warmLED0"] = manualParams[@"WarmLED0Level"] ?: @(0);
                    result[@"warmLED1"] = manualParams[@"WarmLED1Level"] ?: @(0);
                    result[@"source"] = @"hardware";
                }

                // Fill in defaults for legacy values (not applicable for quad)
                result[@"torchLevel"] = @(0);
                result[@"warmth"] = @(0);
            }
        } @catch (NSException *exception) {
            NSLog(@"TrollLEDs: Exception reading hardware LED values: %@", exception.reason);
            // Fall through to UserDefaults
        }
    }

    // If we don't have hardware values, read from UserDefaults
    if (!result[@"source"]) {
        result[@"coolLED0"] = @([defaults integerForKey:kTLCoolLED0LevelKey]);
        result[@"coolLED1"] = @([defaults integerForKey:kTLCoolLED1LevelKey]);
        result[@"warmLED0"] = @([defaults integerForKey:kTLWarmLED0LevelKey]);
        result[@"warmLED1"] = @([defaults integerForKey:kTLWarmLED1LevelKey]);
        result[@"torchLevel"] = @([defaults doubleForKey:kTLTorchLevelKey]);
        result[@"warmth"] = @([defaults integerForKey:kTLWarmthPercentileKey]);
        result[@"source"] = @"defaults";
    }

    return [result copy];
}

@end
