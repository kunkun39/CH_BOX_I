//
//  CHTVProgramManager.h
//  TVhelper
//
//  Created by Jack Wang on 15/7/16.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHTVProgramManager : NSObject

- (void)obtainProgramInfo:(NSString *)selectedIP withServerVersion:(NSString *)serverVersion;

//获取当前所有频道正在播放的节目
+ (NSDictionary *)obtainAllChannelCurrentProgramInfo;

+ (void)obtainCurrentProgramInfoByChannelName:(NSString *)channelName;

+ (NSArray *)obtainAllProgramInfoForOneChannel:(NSString *)channelName;

@end
