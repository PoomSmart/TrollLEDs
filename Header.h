//
//  Header.h
//  TrollLEDs
//
//

#ifndef Header_h
#define Header_h

#import <Foundation/Foundation.h>

typedef struct OpaqueFigCaptureDevice *OpaqueFigCaptureDeviceRef;
typedef struct OpaqueFigCaptureStream *OpaqueFigCaptureStreamRef;

typedef struct OpaqueCMBaseObject *CMBaseObjectRef;
typedef struct OpaqueCMBaseClass *CMBaseClassID;

typedef uint32_t CMBaseClassVersion;

typedef struct CMBaseProtocolTable CMBaseProtocolTable;

typedef OSStatus (*CMBaseObjectCopyPropertyFunction)(CMBaseObjectRef object, CFStringRef propertyKey, CFAllocatorRef allocator, void *propertyValueOut);
typedef OSStatus (*CMBaseObjectSetPropertyFunction)(CMBaseObjectRef object, CFStringRef propertyKey, CFTypeRef propertyValue);

typedef struct __attribute__((packed)) {
    CMBaseClassVersion version;
    size_t derivedStorageSize;
    Boolean (*equal)(CMBaseObjectRef o, CMBaseObjectRef compareTo);
    OSStatus (*invalidate)(CMBaseObjectRef o);
    void (*finalize)(CMBaseObjectRef o);
    CFStringRef (*copyDebugDescription)(CMBaseObjectRef o);
    CMBaseObjectCopyPropertyFunction copyProperty;
    CMBaseObjectSetPropertyFunction setProperty;
    OSStatus (*notificationBarrier)(CMBaseObjectRef o);
    const CMBaseProtocolTable *protocolTable;
} CMBaseClass;

typedef struct {
    const struct OpaqueCMBaseVTableReserved *reserved;
    const CMBaseClass *baseClass;
} CMBaseVTable;

const CMBaseVTable *CMBaseObjectGetVTable(CMBaseObjectRef o);

@interface BWFigCaptureStream : NSObject
- (int)setProperty:(CFStringRef)property value:(id)value;
@end

@interface BWFigCaptureDevice : NSObject
- (id)getProperty:(CFStringRef)property error:(int *)error;
@end

@interface BWFigCaptureDeviceVendor : NSObject
+ (instancetype)sharedInstance;
+ (instancetype)sharedCaptureDeviceVendor;
+ (OpaqueFigCaptureDeviceRef)copyDefaultVideoDeviceWithStealingBehavior:(int)stealingBehavior forPID:(pid_t)pid clientIDOut:(int *)clientIDOut withDeviceAvailabilityChangedHandler:(/*^block*/ id)deviceAvailabilityChangedHandler;
+ (OpaqueFigCaptureStreamRef)copyStreamForFlashlightWithPosition:(int)position deviceType:(int)deviceType forDevice:(OpaqueFigCaptureDeviceRef)device;
+ (OpaqueFigCaptureStreamRef)copyStreamWithPosition:(int)position deviceType:(int)deviceType forDevice:(OpaqueFigCaptureDeviceRef)device;
- (OpaqueFigCaptureDeviceRef)copyDeviceForClient:(int)client;
- (void)_registerNewDeviceClientForPID:(pid_t)clientPID clientIDOut:(int *)clientIDOut deviceAvailabilityChangedHandler:(/*^block*/ id)deviceAvailabilityChangedHandler;
- (int)registerClientWithPID:(pid_t)clientPID stealingBehavior:(int)stealingBehavior deviceSharingWithOtherClientsAllowed:(BOOL)deviceSharingWithOtherClientsAllowed deviceAvailabilityChangedHandler:(/*^block*/ id)deviceAvailabilityChangedHandler;
- (int)registerClientWithPID:(pid_t)clientPID clientDescription:(NSString *)clientDescription stealingBehavior:(int)stealingBehavior deviceSharingWithOtherClientsAllowed:(BOOL)deviceSharingWithOtherClientsAllowed deviceAvailabilityChangedHandler:(/*^block*/ id)deviceAvailabilityChangedHandler;
- (int)registerClientWithPID:(pid_t)clientPID clientDescription:(NSString *)clientDescription clientPriority:(int)clientPriority canStealFromClientsWithSamePriority:(BOOL)canStealFromClientWithSamePriority deviceSharingWithOtherClientsAllowed:(BOOL)deviceSharingWithOtherClientsAllowed deviceAvailabilityChangedHandler:(/*^block*/ id)deviceAvailabilityChangedHandler;
// iOS 13, conflicting definition
// - (OpaqueFigCaptureStreamRef)copyStreamForFlashlightWithPosition:(int)position deviceType:(int)deviceType forDevice:(OpaqueFigCaptureDeviceRef)device;
- (BWFigCaptureStream *)copyStreamForFlashlightWithPosition:(int)position deviceType:(int)deviceType forDevice:(BWFigCaptureDevice *)device;
- (BWFigCaptureDevice *)copyDeviceForClient:(int)client error:(int *)error;
- (BWFigCaptureDevice *)copyDeviceForClient:(int)client informClientWhenDeviceAvailableAgain:(BOOL)informClientWhenDeviceAvailableAgain error:(int *)error;
- (void)takeBackDevice:(OpaqueFigCaptureDeviceRef)device forClient:(int)client;
- (void)takeBackFlashlightDevice:(OpaqueFigCaptureDeviceRef)device forPID:(pid_t)pid;
- (void)takeBackDevice:(BWFigCaptureDevice *)device forClient:(int)client informClientWhenDeviceAvailableAgain:(BOOL)informClientWhenDeviceAvailableAgain;
+ (void)takeBackVideoDevice:(OpaqueFigCaptureDeviceRef)device forPID:(pid_t)pid requestDeviceWhenAvailableAgain:(BOOL)requestDeviceWhenAvailableAgain informOtherClients:(BOOL)informOtherClients;
@end

#endif /* Header_h */
