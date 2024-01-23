#import "TLSceneDelegate.h"

@implementation TLSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions API_AVAILABLE(ios(13.0)) {    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    _window = [[UIWindow alloc] initWithWindowScene:windowScene];
    _myViewController = [[TLRootViewController alloc] init];
    if (connectionOptions.shortcutItem)
        _myViewController.shortcutAction = connectionOptions.shortcutItem.type;
    _rootViewController = [[UINavigationController alloc] initWithRootViewController:_myViewController];
    _rootViewController.navigationBarHidden = YES;
    _window.rootViewController = _rootViewController;
    [_window makeKeyAndVisible];
}

- (void)windowScene:(UIWindowScene *)windowScene performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler API_AVAILABLE(ios(13.0)) {
    [_myViewController handleShortcutAction:shortcutItem.type];
    completionHandler(YES);
}

- (void)sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    [[UIApplication sharedApplication] endBackgroundTask:UIBackgroundTaskInvalid];
}

- (void)sceneDidEnterBackground:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    __block UIBackgroundTaskIdentifier task;
    UIApplication *application = [UIApplication sharedApplication];
    task = [application beginBackgroundTaskWithExpirationHandler:^ {
        [application endBackgroundTask:task];
        task = UIBackgroundTaskInvalid;
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(KILL_TIMEOUT * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        exit(0);
    });
}

@end
