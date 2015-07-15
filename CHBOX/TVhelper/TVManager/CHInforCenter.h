//
//  InforCenter.h
//  SL_LoveStored
//
//  Created by rimi on 15/3/5.
//  Copyright (c) 2015年 SL_Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHInforCenter : NSObject

@property (nonatomic,assign)BOOL isLogIn;

@property (nonatomic,assign)BOOL isShowLeft;

@property (nonatomic,strong)NSString *userName;

@property (nonatomic,strong)NSString *userPassword;
/**
 *  单例创建
 *
 *  @return 返回一个实例化对象
 */
+ (CHInforCenter *)sharedInforCenter;

@end
