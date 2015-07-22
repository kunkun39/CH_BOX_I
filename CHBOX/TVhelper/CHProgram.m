//
//  CHProgram.m
//  TVhelper
//
//  Created by Jack Wang on 15/7/21.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHProgram.h"

@interface CHProgram ()

@end

@implementation CHProgram

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (CHProgram *) initWithChannel:(NSString *)channelName andEventName:(NSString *)eventName andEventStart:(NSString *)eventStart andEventEnd:(NSString *)eventEnd {
    if(self = [super init]) {
        _channelName = channelName;
        _eventName = eventName;
        _eventStart = eventStart;
        _eventEnd  = eventEnd;
    }
    return self;
}

+ (CHProgram *) programWithChannel:(NSString *)channelName andEventName:(NSString *)eventName andEventStart:(NSString *)eventStart andEventEnd:(NSString *)eventEnd {
    return [[CHProgram alloc] initWithChannel:channelName andEventName:eventName andEventStart:eventStart andEventEnd:eventEnd];
}

+ (CHProgram *) programWithChannel:(NSString *)channelName andEventName:(NSString *)eventName andEventStart:(NSString *)eventStart andEventEnd:(NSString *)eventEnd andWeekIndex:(NSString *)weekIndex
{
    CHProgram *program = [CHProgram programWithChannel:channelName andEventName:eventName andEventStart:eventStart andEventEnd:eventEnd];
    program.weekIndex = weekIndex;
    return program;
}

@end
