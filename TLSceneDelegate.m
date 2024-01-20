#import "TLSceneDelegate.h"
#import "TLRootViewController.h"

@implementation TLSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    _window = [[UIWindow alloc] initWithWindowScene:windowScene];
    _rootViewController = [[TLRootViewController alloc] init];
    _window.rootViewController = _rootViewController;
    [_window makeKeyAndVisible];
}

@end
