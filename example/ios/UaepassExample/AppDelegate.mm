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
  // Swift-equivalent UAEPass redirect handler
  NSNumber *handled = [self handleUAEPassRedirect:url];
  if (handled != nil) {
    return handled.boolValue;
  }

  // Other link handler code goes here
  // return [RCTLinkingManager application:application openURL:url options:options];

  return YES;
}

#pragma mark - UAEPass redirect handler (Swift-equivalent)

- (NSNumber * _Nullable)handleUAEPassRedirect:(NSURL *)url
{
  UAEPass *uaepass = [[UAEPass alloc] init];

  NSString *successHost = [[[uaepass getSuccessHost] ?: @"" lowercaseString] copy];
  NSString *failureHost = [[[uaepass getFailureHost] ?: @"" lowercaseString] copy];

  NSString *urlString = [[url absoluteString] lowercaseString];
  NSString *host = [[url host] ?: @"" lowercaseString];

  BOOL isSuccess =
    (successHost.length > 0 && [urlString containsString:successHost]) ||
    [host isEqualToString:@"uaepasssuccess"];

  if (isSuccess) {
    BOOL didResolve = [self completeUAEPassSuccessFromURL:url];
    [uaepass handleLoginSuccess];
    if (didResolve) {
      [self dismissPresentedUAEPassFlow];
    }
    return @(YES);
  }

  BOOL isFailure =
    (failureHost.length > 0 && [urlString containsString:failureHost]) ||
    [host isEqualToString:@"uaepassfail"];

  if (isFailure) {
    [self completeUAEPassFailureFromURL:url];
    [uaepass handleLoginFailure];
    [self dismissPresentedUAEPassFlow];
    return @(YES);
  }

  return nil; // not handled
}

- (BOOL)completeUAEPassSuccessFromURL:(NSURL *)url
{
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  NSArray<NSURLQueryItem *> *items = components.queryItems;

  NSString *code = nil;
  for (NSURLQueryItem *item in items) {
    if ([item.name isEqualToString:@"code"]) {
      code = item.value;
      break;
    }
  }

  if (code.length == 0) {
    return NO;
  }

  // Swift: UAEPass.resolve(withAccessCode: code)
  [UAEPass resolveWithAccessCode:code];
  return YES;
}

- (void)completeUAEPassFailureFromURL:(NSURL *)url
{
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  NSArray<NSURLQueryItem *> *items = components.queryItems;

  NSString *message = nil;

  // Prefer error_description
  for (NSURLQueryItem *item in items) {
    if ([item.name isEqualToString:@"error_description"] && item.value.length > 0) {
      message = item.value;
      break;
    }
  }

  // Fallback to error
  if (message.length == 0) {
    for (NSURLQueryItem *item in items) {
      if ([item.name isEqualToString:@"error"] && item.value.length > 0) {
        message = item.value;
        break;
      }
    }
  }

  if (message.length == 0) {
    message = @"UAE PASS login failed";
  }

  // Swift: UAEPass.reject(withCode: "ERROR", message: message, error: nil)
  [UAEPass rejectWithCode:@"ERROR" message:message error:nil];
}

- (void)dismissPresentedUAEPassFlow
{
  UIViewController *topController = [self topMostViewController];
  if (!topController) return;

  NSString *presentedName = NSStringFromClass([topController class]);
  if ([presentedName containsString:@"UAEPass"]) {
    [topController dismissViewControllerAnimated:YES completion:nil];
  }
}

- (UIViewController *)topMostViewController
{
  UIViewController *root = self.window.rootViewController;
  if (!root) return nil;

  UIViewController *top = root;
  while (top.presentedViewController) {
    top = top.presentedViewController;
  }

  if ([top isKindOfClass:[UINavigationController class]]) {
    return ((UINavigationController *)top).topViewController ?: top;
  }

  if ([top isKindOfClass:[UITabBarController class]]) {
    UIViewController *selected = ((UITabBarController *)top).selectedViewController;
    if ([selected isKindOfClass:[UINavigationController class]]) {
      return ((UINavigationController *)selected).topViewController ?: selected;
    }
    return selected ?: top;
  }

  return top;
}

@end
