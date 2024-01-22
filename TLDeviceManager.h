#import "Header.h"

@interface TLDeviceManager : NSObject {
    BOOL initialized;
    pid_t pid;
    int client;
    Class BWFigCaptureDeviceVendorClass;
    BWFigCaptureDeviceVendor *vendor;
    BWFigCaptureDevice *device;
    BWFigCaptureStream *stream;
    OpaqueFigCaptureDeviceRef deviceRef;
    OpaqueFigCaptureStreamRef streamRef;
    CMBaseObjectSetPropertyFunction streamSetProperty;
    BOOL legacyLEDs;
    BOOL quadLEDs;
}
@property (nonatomic, strong) NSString *currentError;
- (BOOL)isLegacyLEDs;
- (BOOL)isQuadLEDs;
- (BOOL)setupStream;
- (void)releaseStream;
- (void)initVendor;
- (void)checkType;
- (void)setNumberProperty:(CFStringRef)property value:(id)value;
- (void)setDictionaryProperty:(CFStringRef)property value:(id)value;
@end
