//
//  Header.h
//  TrollLEDs
//
//

#ifndef Header_h
#define Header_h

#import <Foundation/Foundation.h>

@interface BWFigCaptureStream : NSObject
- (int)setProperty:(CFStringRef)property value:(id)value;
@end

@interface BWFigCaptureDevice : NSObject
- (NSArray <BWFigCaptureStream *> *)streams;
@end

@interface BWFigCaptureDeviceVendor : NSObject
+ (instancetype)sharedInstance;
+ (instancetype)sharedCaptureDeviceVendor;
- (void)_registerNewDeviceClientForPID:(pid_t)clientPID clientIDOut:(int *)clientIDOut deviceAvailabilityChangedHandler:(/*^block*/ id)deviceAvailabilityChangedHandler;
- (int)registerClientWithPID:(pid_t)clientPID stealingBehavior:(int)stealingBehavior deviceSharingWithOtherClientsAllowed:(BOOL)deviceSharingWithOtherClientsAllowed deviceAvailabilityChangedHandler:(/*^block*/ id)deviceAvailabilityChangedHandler;
- (int)registerClientWithPID:(pid_t)clientPID clientDescription:(NSString *)clientDescription stealingBehavior:(int)stealingBehavior deviceSharingWithOtherClientsAllowed:(BOOL)deviceSharingWithOtherClientsAllowed deviceAvailabilityChangedHandler:(/*^block*/ id)deviceAvailabilityChangedHandler;
- (int)registerClientWithPID:(pid_t)clientPID clientDescription:(NSString *)clientDescription clientPriority:(int)clientPriority canStealFromClientsWithSamePriority:(BOOL)canStealFromClientWithSamePriority deviceSharingWithOtherClientsAllowed:(BOOL)deviceSharingWithOtherClientsAllowed deviceAvailabilityChangedHandler:(/*^block*/ id)deviceAvailabilityChangedHandler;
- (BWFigCaptureDevice *)copyDeviceForClient:(int)client error:(int *)error;
- (BWFigCaptureDevice *)copyDeviceForClient:(int)client informClientWhenDeviceAvailableAgain:(BOOL)informClientWhenDeviceAvailableAgain error:(int *)error;
@end

#endif /* Header_h */
