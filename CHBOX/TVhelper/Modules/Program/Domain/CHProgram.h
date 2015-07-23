//
//  CHProgram.h
//  TVhelper
//
//  Created by Jack Wang on 15/7/21.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CHProgram : UIViewController

@property(nonatomic, copy) NSString *channelName;
@property(nonatomic, copy) NSString *eventName;
@property(nonatomic, copy) NSString *eventStart;
@property(nonatomic, copy) NSString *eventEnd;
@property(nonatomic, copy) NSString *weekIndex;

- (CHProgram *) initWithChannel:(NSString *)channelName andEventName:(NSString *)eventName andEventStart:(NSString *)eventStart andEventEnd:(NSString *)eventEnd;

+ (CHProgram *) programWithChannel:(NSString *)channelName andEventName:(NSString *)eventName andEventStart:(NSString *)eventStart andEventEnd:(NSString *)eventEnd;

+ (CHProgram *) programWithChannel:(NSString *)channelName andEventName:(NSString *)eventName andEventStart:(NSString *)eventStart andEventEnd:(NSString *)eventEnd andWeekIndex:(NSString *)weekIndex;

@end
