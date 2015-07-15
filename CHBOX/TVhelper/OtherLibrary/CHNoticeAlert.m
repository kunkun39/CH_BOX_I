//
//  noticeAlert.m
//  TVhelper
//
//  Created by shanshu on 15/5/14.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHNoticeAlert.h"

@implementation CHNoticeAlert

-(instancetype)initWithTittle:(NSString *)tittle
{

    self = [super init];
    if (self) {
        UIFont * font = [UIFont systemFontOfSize:30];
        CGRect contexRect = [tittle boundingRectWithSize:CGSizeMake(300, 2000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil];
        [self setFrame:CGRectMake(0, 0, contexRect.size.width, contexRect.size.height)];
        self.windowLevel = UIWindowLevelAlert;
        _tittleLabel = [[UILabel alloc]init];
        _tittleLabel.text = tittle;
        _tittleLabel.textAlignment = NSTextAlignmentCenter;
        _tittleLabel.font = [UIFont systemFontOfSize:30];
        _tittleLabel.textColor = [UIColor whiteColor];
        [_tittleLabel sizeToFit];
        [self addSubview:_tittleLabel];
    }
    return self;
}

- (void)setLabelString:(NSString *)str
{
    _tittleLabel.text = str;
    [_tittleLabel sizeToFit];
}
- (void)show
{
    [self makeKeyAndVisible];
    [UIView animateWithDuration:0.3 animations:^{
        self.transform = CGAffineTransformMakeScale(0.7, 0.7);
    } completion:^(BOOL finished) {
        nil;
    }];
}

- (void)dismiss
{
    [self resignKeyWindow];
    [UIView animateWithDuration:0.3 animations:^{
        self.transform = CGAffineTransformMakeScale(0.1, 0.1);
        
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
    
}

@end
