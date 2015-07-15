//
//  noticeAlert.h
//  TVhelper
//
//  Created by shanshu on 15/5/14.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CHNoticeAlert : UIWindow
@property (nonatomic, strong)UILabel * tittleLabel;
- (void)setLabelString:(NSString *)str;
- (instancetype)initWithTittle:(NSString *)tittle;
- (void)show;
- (void)dismiss;
@end
