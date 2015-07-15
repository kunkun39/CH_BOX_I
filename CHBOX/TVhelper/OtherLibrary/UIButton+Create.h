//
//  UIButton+Create.h
//  TVhelper
//
//  Created by shanshu on 15/4/30.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (Create)

+ (UIButton*) createButtonWithFrame: (CGRect) frame Target:(id)target Tag:(NSInteger)tag Selector:(SEL)selector Image:(NSString *)image ImagePressed:(NSString *)imagePressed;
+ (UIButton *) createButtonWithFrame:(CGRect)frame Title:(NSString *)title Target:(id)target Tag:(NSInteger)tag Selector:(SEL)selector;

@end
