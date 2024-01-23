#import "TLAppDelegate.h"
#import "TLRootViewController.h"

@implementation TLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (@available(iOS 13.0, *)) {
        return YES;
    }
    _window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    _myViewController = [[TLRootViewController alloc] init];
    if (launchOptions[UIApplicationLaunchOptionsShortcutItemKey])
        _myViewController.shortcutAction = launchOptions[UIApplicationLaunchOptionsShortcutItemKey];
    _rootViewController = [[UINavigationController alloc] initWithRootViewController:_myViewController];
    _rootViewController.navigationBarHidden = YES;
    _window.rootViewController = _rootViewController;
    [_window makeKeyAndVisible];
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options API_AVAILABLE(ios(13.0)) {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
    [_myViewController handleShortcutAction:shortcutItem.type];
}

- (void)appWillEnterForeground:(UIApplication *)application {
    [application endBackgroundTask:UIBackgroundTaskInvalid];
}

- (void)appDidEnterBackground:(UIApplication *)application {
    __block UIBackgroundTaskIdentifier task;
    task = [application beginBackgroundTaskWithExpirationHandler:^ {
        [application endBackgroundTask:task];
        task = UIBackgroundTaskInvalid;
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(KILL_TIMEOUT * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        exit(0);
    });
}

@end
