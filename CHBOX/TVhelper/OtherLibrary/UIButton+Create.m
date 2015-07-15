//
//  UIButton+Create.m
//  TVhelper
//
//  Created by shanshu on 15/4/30.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "UIButton+Create.h"

@implementation UIButton (Create)

+ (UIButton*) createButtonWithFrame: (CGRect) frame Title:(NSString *)title Target:(id)target Tag:(NSInteger)tag Selector:(SEL)selector
{
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    [button setTitle:title forState:UIControlStateNormal];
    [button setFrame:frame];
    [button setTag:tag];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

+ (UIButton*) createButtonWithFrame: (CGRect) frame Target:(id)target Tag:(NSInteger)tag Selector:(SEL)selector Image:(NSString *)image ImagePressed:(NSString *)imagePressed
{
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:frame];
    [button setTag:tag];
    UIImage *newImage = [UIImage imageNamed: image];
    [button setImage:newImage forState:UIControlStateNormal];
    UIImage *newPressedImage = [UIImage imageNamed: imagePressed];
    [button setImage:newPressedImage forState:UIControlStateHighlighted];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end
