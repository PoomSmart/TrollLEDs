#import <UIKit/UIKit.h>
#import "TLDeviceManager.h"

@interface TLRootViewController : UITableViewController
@property (nonatomic, strong, readonly) TLDeviceManager *deviceManager;
@property (nonatomic, retain) NSString *shortcutAction;
- (void)handleShortcutAction:(NSString *)action withParameters:(NSArray <NSURLQueryItem *> *)params;
- (void)setupStream;
- (void)releaseStream;
@end

#define KILL_TIMEOUT 300
