#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(UAEPass, NSObject)

RCT_EXTERN_METHOD(login: (NSDictionary *)params resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(logout: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
