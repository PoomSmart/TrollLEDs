#import "TLAppDelegate.h"
#import "TLRootViewController.h"

@implementation TLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (@available(iOS 13.0, *)) {
		return YES;
	}
	_window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
	_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[TLRootViewController alloc] init]];
	_window.rootViewController = _rootViewController;
	_rootViewController.navigationBarHidden = YES;
	[_window makeKeyAndVisible];
	return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

@end
