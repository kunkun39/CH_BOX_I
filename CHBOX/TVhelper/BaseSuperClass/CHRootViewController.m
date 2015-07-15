//
//  RootViewController.m
//  TVhelper
//
//  Created by shanshu on 15/4/2.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHRootViewController.h"
//菜单详情类
#import "CHRemoteControlViewController.h"
#import "CHTVViewController.h"
#import "CHProjectionViewController.h"
#import "CHSearchViewController.h"
#import "CHFavoriteViewController.h"
#import "CHSettingViewController.h"
#import "CHFeedbackViewController.h"
#import "CHTVSocketManager.h"

#define ABOUT_SPACING 20
#define UP_SPACING (-45)
#define DOWN_SPACING 15
typedef NS_ENUM(NSInteger, menuOption)
{
    settings = 0,
    TV,
    remotecontrol
};
@interface CHRootViewController ()

@end

@implementation CHRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUserInterface];
}

- (void)initUserInterface
{
    self.navigationBarView.backgroundColor = COLOR_RGB(34, 38, 52, 1);
    self.view.backgroundColor = [UIColor whiteColor];
    self.gobackBtn.hidden = YES;
    UIImageView * BackImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, NAV_BAR_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT - NAV_BAR_HEIGHT)];
    BackImage.image = [UIImage imageNamed:@"底图_1.png"];
    CGFloat height = CGRectGetHeight(BackImage.frame);
    CGFloat height_item = (SCREEN_HEIGHT -64)/(667 - 64) * 180;
    NSArray * array_tmp = [NSArray arrayWithObjects:@"0000_设置.png", @"0001_数字电视.png", @"0002_遥控器.png", nil];
    NSArray * array_selected = [NSArray arrayWithObjects:@"设置_selected.png", @"数字电视_selected.png", @"遥控器_selected.png", nil];
    for (int i = 0; i < array_tmp.count; i ++) {
        UIButton * settingBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, height - height_item * (i + 1), SCREEN_WIDTH, height_item - 1)];
        settingBtn.tag = i;
        [settingBtn setImage:[UIImage imageNamed:array_tmp[i]] forState:UIControlStateNormal];
       [settingBtn setImage:[UIImage imageNamed:array_selected[i]] forState:UIControlStateHighlighted];
        [settingBtn addTarget:self action:@selector(processMenuBtn:) forControlEvents:UIControlEventTouchUpInside];
        [BackImage addSubview:settingBtn];
    }
    [self.view addSubview:BackImage];
    [self.view sendSubviewToBack:BackImage];
    [self.view bringSubviewToFront:self.CHBoxTableView];
    BackImage.userInteractionEnabled = YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - process
- (void)processMenuBtn:(UIButton *)btn
{
    AudioServicesPlaySystemSound(SOUND_ID);    
    switch (btn.tag) {
        case settings:
            [self presentViewController:[[CHSettingViewController alloc]init] animated:YES completion:nil];
            break;
        case remotecontrol:
            NSLog(@"remotecontrol");
            [self presentViewController:[[CHRemoteControlViewController alloc]init] animated:YES completion:nil];
            break;
        case TV:
            NSLog(@"Tv");
            [self presentViewController:[[CHTVViewController alloc]init] animated:YES completion:nil];
            break;


        default:
            break;
    }

}

@end
