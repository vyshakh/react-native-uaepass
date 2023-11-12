#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>

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


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
//  THIS block of code handles the UAE Pass success or failure redirects(links)
    UAEPass * obj = [[UAEPass alloc] init];
    NSString *successHost = [obj getSuccessHost];
    NSString *failureHost = [obj getFailureHost];
    if ([url.absoluteString containsString: successHost]) {
      [obj handleLoginSuccess];
      return YES;
    }else if ([url.absoluteString containsString: failureHost]){
      [obj handleLoginFailure];
      return NO;
    }
  // UAE pass link handler ends here
  // Other link handler code goes here

  return YES;
// return [RCTLinkingManager application:application openURL:url options:options];
}

@end
