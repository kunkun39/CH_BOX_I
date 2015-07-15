//
//  CHTipsViewController.m
//  TVhelper
//
//  Created by shanshu on 15/6/15.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHTipsViewController.h"
#define CONTENT_REMOTE @"        1、手指上下左右滑动，能得到上下左右按键一样的效果\n\n        2、电视键可以实现在任何界面下切换到全屏播放电视\n\n        3、频道键可以实现在手机上快速选择切换机顶盒上的节目\n\n        4、关机键可以使机顶盒处于低功耗模式，并且不影响数字电视节目分享到移动设备"
#define CONTENT_SYSTEM @"        1、为了保证手机播放的质量，请使用有线连接机顶盒\n\n        2、为了保证手机播放的质量，请保证手机连接到5G以上频率的网络"
@interface CHTipsViewController ()
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITextView *detailTextView;
@end

@implementation CHTipsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.CHBoxBtn.hidden = YES;
    self.CHBoxImageView.hidden = YES;
    self.titleLabel.text = self.titleStr;
    self.detailTextView.text = [self.titleStr isEqualToString:@"系统帮助"] ? CONTENT_SYSTEM:[self.titleStr isEqualToString:@"遥控器帮助"] ? CONTENT_REMOTE: nil;
}

- (void)processGobackBtn
{
    AudioServicesPlaySystemSound(SOUND_ID);
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
