//
//  InforCenter.m
//  SL_LoveStored
//
//  Created by rimi on 15/3/5.
//  Copyright (c) 2015年 SL_Team. All rights reserved.
//

#import "CHInforCenter.h"

static CHInforCenter * inforCenter = nil;

@implementation CHInforCenter

+ (CHInforCenter *)sharedInforCenter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inforCenter = [[CHInforCenter alloc]init];
    });
    return inforCenter;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    if (!inforCenter) {
        inforCenter = [super allocWithZone:zone];
    }
    return inforCenter;
}
- (id)copy
{
    return self;
}

@end
