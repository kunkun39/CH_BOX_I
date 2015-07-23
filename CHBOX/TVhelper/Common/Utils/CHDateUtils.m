//
//  CHDateUtils.m
//  TVhelper
//
//  Created by Jack Wang on 15/7/22.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHDateUtils.h"

@implementation CHDateUtils

+ (NSArray *) obtainFurtherSixDaysIncludeSelf
{
    NSString *currentDay = [CHDateUtils obtainCurrentWeekIndex];
    NSLog(@"current day week index is %@", currentDay);
    
    if([currentDay compare:@"7"] == NSOrderedSame) {
        NSArray *allDays = @[@"周天", @"周一", @"周二", @"周三", @"周四", @"周五", @"周六"];
        return allDays;
    } else if ([currentDay compare:@"1"] == NSOrderedSame) {
        NSArray *allDays = @[@"周一", @"周二", @"周三", @"周四", @"周五", @"周六", @"周天"];
        return allDays;
    } else if ([currentDay compare:@"2"] == NSOrderedSame) {
        NSArray *allDays = @[@"周二", @"周三", @"周四", @"周五", @"周六", @"周天", @"周一"];
        return allDays;
    } else if ([currentDay compare:@"3"] == NSOrderedSame) {
        NSArray *allDays = @[@"周三", @"周四", @"周五", @"周六", @"周天", @"周一", @"周二"];
        return allDays;
    } else if ([currentDay compare:@"4"] == NSOrderedSame) {
        NSArray *allDays = @[@"周四", @"周五", @"周六", @"周天", @"周一", @"周二", @"周三"];
        return allDays;
    } else if ([currentDay compare:@"5"] == NSOrderedSame) {
        NSArray *allDays = @[@"周五", @"周六", @"周天", @"周一", @"周二", @"周三", @"周四"];
        return allDays;
    } else if ([currentDay compare:@"6"] == NSOrderedSame) {
        NSArray *allDays = @[@"周六", @"周天", @"周一", @"周二", @"周三", @"周四", @"周五"];
        return allDays;
    }
    
    return nil;
}

+ (NSString *) obtainCurrentWeekIndex
{
    NSArray *weekdays = [NSArray arrayWithObjects:[NSNull null], @"7", @"1", @"2", @"3", @"4", @"5", @"6", nil];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSTimeZone *timeZone = [[NSTimeZone alloc] initWithName:@"Asia/Shanghai"];
    
    [calendar setTimeZone: timeZone];
    
    NSCalendarUnit calendarUnit = NSWeekdayCalendarUnit;
    
    NSDate *today = [NSDate date];
    
    NSDateComponents *theComponents = [calendar components:calendarUnit fromDate:today];
    
    return [weekdays objectAtIndex:theComponents.weekday];
}

@end
