//
//  ProjectionViewController.m
//  TVhelper
//
//  Created by shanshu on 15/4/2.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHProjectionViewController.h"

@interface CHProjectionViewController ()

@end

@implementation CHProjectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUserInterface];
}
- (void)initUserInterface
{
    self.view.backgroundColor = [UIColor orangeColor];
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - process
- (void)processGobackBtn
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
