//
//  RemoteControlViewController.h
//  TVhelper
//
//  Created by shanshu on 15/4/2.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHBaseDetailViewController.h"
@class BDVRCustomRecognitonViewController;
@interface CHRemoteControlViewController : CHBaseDetailViewController
@property (nonatomic, retain) BDVRCustomRecognitonViewController *audioViewController;

- (void)logOutToLogStr:(NSString *)str;
- (void)logOutToManualResut:(NSString *)aResult;
@end
