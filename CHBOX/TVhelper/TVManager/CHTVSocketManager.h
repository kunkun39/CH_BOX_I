//
//  TVSocketManager.h
//  TVhelper
//
//  Created by shanshu on 15/4/27.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHTVSocketDel.h"
static NSString * exup = @"key:up";
static NSString * exdown = @"key:down";
static NSString * exleft = @"key:left";
static NSString * exright = @"key:right";
static NSString * excenter = @"key:ok";
static NSString * exvolumedown = @"key:volumedown";
static NSString * exvolumeup = @"key:volumeup";
static NSString * exdtv = @"key:dtv";
static NSString * exchannel = @"";
static NSString * exhome = @"key:home";
static NSString * exback = @"key:back";
static NSString * exlist = @"key:list";
static NSString * expower = @"key:power";

typedef void (^PlistBack)();

@interface CHTVSocketManager : NSObject
@property (strong, nonatomic) NSMutableArray * IPlistAry;
@property (strong, nonatomic) NSString * selectedIP;
@property (strong, nonatomic) CHTVSocketDel * socket;
@property (copy, nonatomic) PlistBack  plistBack;
+ (CHTVSocketManager *)shareTVSocketManager;
- (void)socketChannelInfo;
- (void)observeTVIP;
@end
