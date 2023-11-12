//
//  UAEPass-Swift.h
//
//  Created by Vyshakh on 07/11/2023.
//

#ifndef UAEPass_Swift_h
#define UAEPass_Swift_h


@class UAEPass;

@interface UAEPass : NSObject
- (NSString *)getSuccessHost;
- (NSString *)getFailureHost;
- (void)handleLoginSuccess;
- (void)handleLoginFailure;
@end


#endif /* UAEPass_Swift_h */
