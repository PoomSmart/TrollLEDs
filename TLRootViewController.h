#import <UIKit/UIKit.h>
#import "TLDeviceManager.h"

@interface TLRootViewController : UITableViewController {
    TLDeviceManager *deviceManager;
}
@property (nonatomic, retain) NSString *shortcutAction;
- (void)handleShortcutAction:(NSString *)action withParameters:(NSArray <NSURLQueryItem *> *)params;
- (void)setupStream;
- (void)releaseStream;
@end

#define KILL_TIMEOUT 300
