//
//  CHTVProgramShowController.m
//  TVhelper
//
//  Created by Jack Wang on 15/7/22.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHTVProgramShowController.h"
#import "UIButton+Create.h"
#import "CHTVProgramManager.h"
#import "CHTVSocketManager.h"
#import "CHProgramTableViewCell.h"
#import "CHDateUtils.h"
#import "CHProgram.h"

@interface CHTVProgramShowController () <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) NSArray *programDetails;

@property(nonatomic, strong) NSArray *selectedProgramDetails;

@property(nonatomic, copy) NSString *currentSelectedWeekIndex;

@property(nonatomic, copy) NSString *firstSelectedWeekIndex;

@property(nonatomic, strong) UIButton *currentTab;

@property(nonatomic, strong) CHTVSocketManager *socketManager;

@property(nonatomic, strong) UITableView * programTableView;

@end

@implementation CHTVProgramShowController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSocketManager];
    [self initDataSource];
    [self initUserInterface];
    [self initMenuBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma init *******************************系统初始化的一些操作*******************************
- (void)initSocketManager
{
    __weak CHTVProgramShowController *objself = self;
    self.socketManager = [CHTVSocketManager shareTVSocketManager];
    self.socketManager.plistBack = ^{
        NSString *filename=[NSTemporaryDirectory() stringByAppendingPathComponent:@"channel.plist"];
        NSArray * channelArytmp = [NSArray arrayWithContentsOfFile:filename];
        NSMutableArray * mutableAry = [NSMutableArray array];
        for (NSDictionary * obj in channelArytmp) {
            if ([obj objectForKey:@"service_name"] != nil) {
                [mutableAry addObject:[obj objectForKey:@"service_name"]];
            }
        }
    };
}

- (void)initDataSource
{
    _firstSelectedWeekIndex = [CHDateUtils obtainCurrentWeekIndex];
    _currentSelectedWeekIndex = [CHDateUtils obtainCurrentWeekIndex];
    
    //初始化节目信息
    _programDetails = [CHTVProgramManager obtainAllProgramInfoForOneChannel:_channelName];
    
    //初始化当前选中的节目信息
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    if(_programDetails != nil) {
        for(CHProgram *program in _programDetails) {
            NSString *weekIndex = program.weekIndex;
            if([_currentSelectedWeekIndex compare:weekIndex] == NSOrderedSame) {
                [temp addObject:program];
            }
        }
    }
    _selectedProgramDetails = temp;
}

- (void)initUserInterface
{
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.view.backgroundColor = COLOR_RGB(50, 50, 50, 1);
    [self.view addSubview:self.programTableView];
    [self.view bringSubviewToFront:self.view.subviews[1]];
}

- (void)initMenuBtn
{
    NSArray *btnNames = [CHDateUtils obtainFurtherSixDaysIncludeSelf];
    NSLog(@"all program tab names is %@", btnNames);
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat btnWidth = screenWidth / 7;
    
    for (int i = 0; i < 7; i ++) {
        //添加BUTTON
        UIButton *tabButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [tabButton setTitle:btnNames[i] forState:UIControlStateNormal];
        [tabButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [tabButton setBackgroundImage:[UIImage imageNamed:@"tab_bg"] forState:UIControlStateNormal];
        tabButton.frame = CGRectMake(0 + i * btnWidth, screenHeight - 40, btnWidth, 40);
        tabButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        tabButton.titleLabel.font = [UIFont systemFontOfSize:12];
        
        //设置BUTTON的事件
        tabButton.tag = 3000 + i + [_firstSelectedWeekIndex intValue];
        [tabButton addTarget:self action:@selector(processProgramBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        //判断是够选中
        if(i == 0) {
            [tabButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
        }
        
        [self.view addSubview:tabButton];
    }
}

#pragma 基类 ***************************处理基类的方法***************************************

- (void)processGobackBtn
{
    AudioServicesPlaySystemSound(SOUND_ID);
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma TABLE **************************处理tableview的方法**********************************

- (UITableView *)programTableView
{
    if (!_programTableView) {
        _programTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, NAV_BAR_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT - NAV_BAR_HEIGHT - 40)style:UITableViewStylePlain];
        _programTableView.backgroundColor = [UIColor clearColor];
        _programTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _programTableView.allowsSelection = NO;
        _programTableView.delegate = self;
        _programTableView.dataSource = self;
        _programTableView.rowHeight = 50;
        
    }
    return _programTableView;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _selectedProgramDetails.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CHProgramTableViewCell *cell = [CHProgramTableViewCell chProgramTableViewCell:tableView];
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    for (UIView *view in cell.subviews) {
        [view removeFromSuperview];
    }
   
    //添加节目信息播放时间
    CHProgram *currentProgramInfo = _selectedProgramDetails[indexPath.row];
    UILabel *programInfoLabel = [[UILabel alloc] init];
    programInfoLabel.text = [NSString stringWithFormat:@"时间:%@ - %@", currentProgramInfo.eventStart, currentProgramInfo.eventEnd];
    programInfoLabel.frame = CGRectMake(10, 5, screenWidth - 20, 20);

    programInfoLabel.textAlignment = NSTextAlignmentLeft;
    programInfoLabel.textColor = [UIColor whiteColor];
    programInfoLabel.font = [UIFont systemFontOfSize:11];
    [cell addSubview:programInfoLabel];
    
    //添加当前播放的名称
    UILabel *programPlayLabel = [[UILabel alloc] init];
    programPlayLabel.text = [NSString stringWithFormat:@"节目:%@", currentProgramInfo.eventName];
    programPlayLabel.frame = CGRectMake(10, 20, screenWidth - 20, 20);
    programPlayLabel.textAlignment = NSTextAlignmentLeft;
    programPlayLabel.textColor = [UIColor whiteColor];
    programPlayLabel.font = [UIFont systemFontOfSize:11];
    [cell addSubview:programPlayLabel];
    
    //添加中间间隔线
    UILabel *middleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 40, screenWidth, 10)];
    middleLabel.text = @"";
    middleLabel.backgroundColor = COLOR_RGB(30, 30, 30, 1);
    [cell addSubview:middleLabel];
    
    return cell;
}

- (void) processProgramBtn:(UIButton *) tabButton
{
    AudioServicesPlaySystemSound(SOUND_ID);
    NSInteger tag = tabButton.tag;
    
    //设置按钮的状态
    NSLog(@"click tab for week index %ld", tag);
    for (int i = 0; i < 7; i ++) {
        UIButton *button = (UIButton *)[self.view viewWithTag:i + 3000 + [_firstSelectedWeekIndex intValue]];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    [tabButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    
    //设置数据源
    NSInteger index = (tag - 3000) % 7 == 0 ? 7 : (tag - 3000) % 7;
    _currentSelectedWeekIndex = [NSString stringWithFormat:@"%ld", index];
    NSLog(@"new selected week index is %@", _currentSelectedWeekIndex);
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    if(_programDetails != nil) {
        for(CHProgram *program in _programDetails) {
            NSString *weekIndex = program.weekIndex;
            if([_currentSelectedWeekIndex compare:weekIndex] == NSOrderedSame) {
                [temp addObject:program];
            }
        }
    }
    _selectedProgramDetails = temp;
    [_programTableView reloadData];
    
}

@end
