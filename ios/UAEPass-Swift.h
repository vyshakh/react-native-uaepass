//
//  UAEPass-Swift.h
//
//  Created by Vyshakh on 07/11/2023.
//

#ifndef UAEPass_Swift_h
#define UAEPass_Swift_h

#import <Foundation/Foundation.h>

@class UAEPass;

@interface UAEPass : NSObject
- (NSString * _Nullable)getSuccessHost;
- (NSString * _Nullable)getFailureHost;
- (NSNumber * _Nullable)handleRedirectUrl:(NSURL * _Nonnull)url;
- (void)handleLoginSuccess;
- (void)handleLoginFailure;
+ (void)clearPromiseHandlers;
+ (void)resolveWithAccessCode:(NSString * _Nonnull)accessCode;
+ (void)rejectWithCode:(NSString * _Nonnull)code message:(NSString * _Nonnull)message error:(NSError * _Nullable)error;
@end


#endif /* UAEPass_Swift_h */
