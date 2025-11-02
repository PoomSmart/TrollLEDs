#import <Foundation/Foundation.h>

/**
 * TLLEDReader
 *
 * Bridge class to read current LED values from hardware or UserDefaults.
 * Provides a Swift-accessible interface for the GetLEDLevelsIntent.
 */
@interface TLLEDReader : NSObject

/**
 * Gets the current LED levels and state.
 * Attempts to read from hardware if the device is locked, otherwise falls back to UserDefaults.
 *
 * @return Dictionary containing LED levels and state:
 *   - coolLED0: NSNumber (0-255)
 *   - coolLED1: NSNumber (0-255)
 *   - warmLED0: NSNumber (0-255)
 *   - warmLED1: NSNumber (0-255)
 *   - torchLevel: NSNumber (0.0-1.0)
 *   - warmth: NSNumber (0-100)
 *   - isLocked: NSNumber (BOOL)
 *   - source: NSString ("hardware" or "defaults")
 */
+ (NSDictionary *)getCurrentLEDLevels;

@end
