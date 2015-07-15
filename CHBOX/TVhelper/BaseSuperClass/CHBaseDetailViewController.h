//
//  BaseDetailViewController.h
//  TVhelper
//
//  Created by shanshu on 15/4/2.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CHBaseDetailViewController : UIViewController
@property (nonatomic,strong)UIView * navigationBarView;
@property (nonatomic,strong)UIButton * gobackBtn;
@property (nonatomic,strong)UIButton * CHBoxBtn;
@property (nonatomic,strong)UITableView * CHBoxTableView;
@property (nonatomic,strong)UIImageView * CHBoxImageView;
@end
