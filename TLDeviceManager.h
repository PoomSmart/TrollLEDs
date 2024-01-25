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
}
@property (nonatomic, strong) NSString *currentError;
- (BOOL)isLegacyLEDs;
- (BOOL)setupStream;
- (void)releaseStream;
- (void)initVendor;
- (void)checkType;
- (void)setProperty:(CFStringRef)property value:(id)value;
@end
