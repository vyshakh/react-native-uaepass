#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
//#import <React/RCTLinkingManager.h>

#import "UAEPass-Swift.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"UaepassExample";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
  UAEPass *uaepass = [[UAEPass alloc] init];
  NSNumber *handled = [uaepass handleRedirectUrl:url];
  if (handled != nil) {
    return YES; // handled by UAEPass
  }

  // Other link handler code goes here
  // return [RCTLinkingManager application:application openURL:url options:options];

  return YES;
}

@end
