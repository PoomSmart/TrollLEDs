#import "Header.h"
#import "TLFlashCapability.h"

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
    CMBaseObjectCopyPropertyFunction streamCopyProperty;
    BOOL legacyLEDs;
    TLFlashAPI flashAPI;
}
@property (nonatomic, strong) NSString *currentError;
- (TLFlashAPI)flashAPI;
- (BOOL)isLegacyLEDs;
- (BOOL)isInitialized;
- (BOOL)setupStream;
- (void)releaseStream;
- (void)initVendor;
- (void)checkType;
- (void)refineFlashAPIWithStream;
- (void)setProperty:(CFStringRef)property value:(id)value;
- (id)getProperty:(CFStringRef)property;
@end
