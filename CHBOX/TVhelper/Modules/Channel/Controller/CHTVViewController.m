//
//  TVViewController.m
//  TVhelper
//
//  Created by shanshu on 15/4/2.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHTVViewController.h"
#import "UIButton+Create.h"
#import "CHTVSocketManager.h"
#import "CHChannelTableViewCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "PlayerControllerDelegate.h"
#import "PlayerController.h"
#import "CHChannelTableViewCell.h"
#import "CHTVProgramManager.h"
#import "CHProgram.h"
#import "CHTVProgramShowController.h"

#define TABELVIEW_HEIGHT 44
#define PORT 9002
#define PORT_CHANNEL 9005
#define CHANNEL_Interitem 0
#define CHANNEL_LINE 10
#define SOUND_ID 1114
#define TEST_STR @"http://192.168.0.222:8000/live.ts?freq=259000&pmtPid=500&aPid=520&vPid=510&dmxId=1&service_id=500"

typedef NS_ENUM(NSInteger, CHtag)
{
    TV = 3,
    channel = 4
};
@interface CHTVViewController ()<UITableViewDataSource, UITableViewDelegate, PlayerControllerDelegate>
@property (nonatomic, strong)UITableView * channelTableView;
@property (nonatomic, strong)MPMoviePlayerController * moviewPlayer;
@property (nonatomic, strong)CHTVSocketManager * socketManager;
@property (nonatomic, strong)NSString * channeStr;

//频道相关
@property (nonatomic, strong)NSArray * channelAry;
@property (nonatomic, strong)NSArray * nameAry;
@property (nonatomic, strong)NSArray * tmpAry;
@property (nonatomic, strong)NSDictionary * nameImgDic;

//节目相关
@property (nonatomic, strong)NSDictionary * programInfoDic;

//频道TAB选择相关
@property (nonatomic, copy) NSString *selectedTabIndex;
@end

@implementation CHTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSocketManager];
    [self initDataSource];
    [self initMenuBtn];
    [self initUserInterface];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"invatilPlayer" object:nil];
}
- (void)btnbtn
{
    PlayerController *playerCtrl;
    playerCtrl = [[PlayerController alloc] initWithNibName:nil bundle:nil];
    playerCtrl.delegate = self;
    [self presentViewController:playerCtrl animated:YES completion:nil];
}

- (void)initSocketManager
{
    __weak CHTVViewController * objself = self;
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
        _nameAry = [NSArray arrayWithArray:mutableAry];
        _tmpAry = [NSArray arrayWithArray:mutableAry];
        [objself.channelTableView reloadData];
    };
}

- (void)initUserInterface
{
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.view.backgroundColor = COLOR_RGB(50, 50, 50, 1);
    [self.view addSubview:self.channelTableView];
    [self.view bringSubviewToFront:self.view.subviews[1]];
}

- (void)initDataSource
{
    _nameImgDic = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForAuxiliaryExecutable:@"InfoDic.plist"]];
    NSString *filename=[NSTemporaryDirectory() stringByAppendingPathComponent:@"channel.plist"];
    _channelAry = [NSArray arrayWithContentsOfFile:filename];
    NSMutableArray * mutableAry = [NSMutableArray array];
    for (NSDictionary * obj in _channelAry) {
        if ([obj objectForKey:@"service_name"] != nil) {
            [mutableAry addObject:[obj objectForKey:@"service_name"]];
        }
    }
    _nameAry = [NSArray arrayWithArray:mutableAry];
    _tmpAry = [NSArray arrayWithArray:mutableAry];
    
    //初始化节目信息
    _programInfoDic = [CHTVProgramManager obtainAllChannelCurrentProgramInfo];
}

- (void)initMenuBtn
{
    _selectedTabIndex = @"0";
    NSArray * btnNames = @[@"全部", @"高清", @"卫视", @"少儿", @"央视"];
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat btnWidth = screenWidth / 5;
    
    for (int i = 0; i < 5; i ++) {
        //添加BUTTON
        UIButton *tabButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [tabButton setTitle:btnNames[i] forState:UIControlStateNormal];
        [tabButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [tabButton setBackgroundImage:[UIImage imageNamed:@"tab_bg"] forState:UIControlStateNormal];
        tabButton.frame = CGRectMake(0 + i * btnWidth, screenHeight - 40, btnWidth, 40);
        tabButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        tabButton.titleLabel.font = [UIFont systemFontOfSize:12];
        
        //设置BUTTON的事件
        tabButton.tag = 1000 + i + [_selectedTabIndex intValue];
        [tabButton addTarget:self action:@selector(processChannelBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        //判断是够选中
        if(i == 0) {
            [tabButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
        }
        
        [self.view addSubview:tabButton];
    }
}

#pragma mark - property

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - process
- (void)processGobackBtn
{
    AudioServicesPlaySystemSound(SOUND_ID);
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (NSData *)transformData:(NSString *)str
{
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma make - ***********************************处理TAB相关操作*********************************************

- (void)processChannelBtn:(UIButton *)btn
{
    AudioServicesPlaySystemSound(SOUND_ID);
    
    //设置按钮的状态
    for (int i = 0; i < 5; i ++) {
        UIButton *button = (UIButton *)[self.view viewWithTag:i + 1000];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    [btn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    
    //切换数据
    switch (btn.tag - 999) {
        case 1:
            _tmpAry = _nameAry;
            break;
        case 2:
        {
            NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF CONTAINS 'HD' OR SELF CONTAINS '高清'"];
            _tmpAry = [_nameAry filteredArrayUsingPredicate:pred];
        }
            break;
        case 3:
        {
            NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF CONTAINS '卫视'"];
            _tmpAry = [_nameAry filteredArrayUsingPredicate:pred];
            
        }
            break;
        case 4:
        {
            NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF CONTAINS '少儿' OR SELF CONTAINS '卡通' OR SELF CONTAINS '动漫' OR SELF CONTAINS '成长'"];
            _tmpAry = [_nameAry filteredArrayUsingPredicate:pred];
        }
            break;
        case 5:
        {
            NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF CONTAINS 'CCTV'"];
            _tmpAry = [_nameAry filteredArrayUsingPredicate:pred];
        }
            break;
        default:
            break;
    }
    [self.channelTableView reloadData];
}

#pragma mark - ********************************table view相关参数设置******************************************

- (UITableView *)channelTableView
{
    if (!_channelTableView) {
        _channelTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, NAV_BAR_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT - NAV_BAR_HEIGHT - 40)style:UITableViewStylePlain];
        _channelTableView.backgroundColor = [UIColor clearColor];
        UIImage *bgImage = [UIImage imageNamed:@"remote_bk.png"];
        _channelTableView.backgroundView = [[UIImageView alloc] initWithImage:bgImage];
        _channelTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _channelTableView.allowsSelection = NO;
        _channelTableView.delegate = self;
        _channelTableView.dataSource = self;
        
    }
    return _channelTableView;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tmpAry.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CHChannelTableViewCell *cell = [CHChannelTableViewCell chChannelTableViewCell:tableView];
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    for (UIView *view in cell.subviews) {
        [view removeFromSuperview];
    }
    
    //设置频道图标
    UIButton *channelIconButton = [UIButton buttonWithType:UIButtonTypeCustom];
    channelIconButton.frame = CGRectMake(10, 10, 60, 30);
    UIImage *imgTmp = [[UIImage alloc] init];
    if ([_nameImgDic objectForKey:_tmpAry[indexPath.row]] != nil ) {
        imgTmp = [UIImage imageNamed:[_nameImgDic objectForKey:_tmpAry[indexPath.row]]];
    } else {
        imgTmp  = [UIImage imageNamed:@"logotv.png"];
    }
    [channelIconButton setImage:imgTmp forState:UIControlStateNormal];
    [channelIconButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [cell addSubview:channelIconButton];
    
    //添加频道名称
    NSString *channelName = _tmpAry[indexPath.row];
    UILabel *channelNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 45, screenWidth, 20)];
    channelNameLabel.text = [NSString stringWithFormat:@"   %ld %@", indexPath.row + 1, channelName];
    channelNameLabel.textAlignment = NSTextAlignmentLeft;
    channelNameLabel.textColor = [UIColor whiteColor];
    channelNameLabel.font = [UIFont systemFontOfSize:11];
    channelNameLabel.backgroundColor = COLOR_RGB(27, 98, 160, 0.3);
    [cell addSubview:channelNameLabel];
    
    //添加节目信息播放时间
    CHProgram *currentProgramInfo = [_programInfoDic valueForKey:channelName];
    UILabel *programInfoLabel = [[UILabel alloc] init];
    if(currentProgramInfo == nil) {
        programInfoLabel.text = @"无节目信息";
        programInfoLabel.frame = CGRectMake(80, 5, screenWidth - 60, 40);
    } else {
        programInfoLabel.text = [NSString stringWithFormat:@"正在播放:%@ - %@", currentProgramInfo.eventStart, currentProgramInfo.eventEnd];
        programInfoLabel.frame = CGRectMake(80, 5, screenWidth - 60, 20);
    }
    programInfoLabel.textAlignment = NSTextAlignmentLeft;
    programInfoLabel.textColor = [UIColor whiteColor];
    programInfoLabel.font = [UIFont systemFontOfSize:11];
    [cell addSubview:programInfoLabel];
    
    //添加当前播放的时间
    UILabel *programPlayLabel = [[UILabel alloc] init];
    if(currentProgramInfo != nil) {
        programPlayLabel.text = [NSString stringWithFormat:@"%@", currentProgramInfo.eventName];
        programPlayLabel.frame = CGRectMake(80, 25, screenWidth - 60, 20);
    }
    programPlayLabel.textAlignment = NSTextAlignmentLeft;
    programPlayLabel.textColor = [UIColor whiteColor];
    programPlayLabel.font = [UIFont systemFontOfSize:11];
    [cell addSubview:programPlayLabel];
    
    //添加节目按钮
    UIButton *programDetailsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    programDetailsButton.titleLabel.lineBreakMode = 0;
    [programDetailsButton setTitle:@"节目信息" forState:UIControlStateNormal];
    [programDetailsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    programDetailsButton.frame = CGRectMake(screenWidth - 40, 5, 30, 40);
    programDetailsButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    programDetailsButton.titleLabel.font = [UIFont systemFontOfSize:11];
    [programDetailsButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    [cell addSubview:programDetailsButton];
    
    //添加事件
    [channelIconButton addTarget:self action:@selector(playProgram:)forControlEvents:UIControlEventTouchUpInside];
    channelIconButton.tag = indexPath.row + 1000;
    
    [programDetailsButton addTarget:self action:@selector(checkProgramDetails:)forControlEvents:UIControlEventTouchUpInside];
    programDetailsButton.tag = indexPath.row + 2000;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.channelTableView) {
        return 60;
    }
    return TABELVIEW_HEIGHT;
}

#pragma mark - *****************************播放相关参数设定************************************

- (void) playProgram:(UIButton *)clickButton
{
    //找到哪个频道准备播放
    NSInteger selectedRow = clickButton.tag - 1000;
    NSString *channelName = _tmpAry[selectedRow];
    NSLog(@"play for tag %ld for channel %@", selectedRow, channelName);
    
    //开始播放
    AudioServicesPlaySystemSound(SOUND_ID);
    for (NSDictionary * dic in _channelAry) {
        if ([[dic objectForKey:@"service_name"] isEqualToString:_tmpAry[selectedRow]]) {
            //:8000/live.tsfreq=259000&pmtPid=500&aPid=520&vPid=510&dmxId=1&service_id=500
            self.channeStr = [NSString stringWithFormat:@"http://%@:8000/live.ts?freq=%@&pmtPid=%@&aPid=%@&vPid=%@&dmxId=%@&service_id=%@", self.socketManager.selectedIP, [dic objectForKey:@"freqKHz"], [dic objectForKey:@"pmtPid"], [dic objectForKey:@"audio_pid"], [dic objectForKey:@"video_pid"], [dic objectForKey:@"demux_id"], [dic objectForKey:@"service_id"]];
            if (_tmpAry.count >0) {
                if ([_tmpAry[0] containsString:@"HD"] || [_tmpAry[0] containsString:@"高清"]) {
                    
                    
                    NSString * vStr = [self dealStrWithVStream:[dic objectForKey:@"vStreamType"]];
                    NSString * aStr = [self dealStrWithAStream:[dic objectForKey:@"aStreamType"]];
                    NSString * trainingStr = [NSString stringWithFormat:@"&encode=1&encSrc=0&aStreamType=%@&vStreamType=%@", aStr, vStr];
                    self.channeStr = [NSString stringWithString:[self.channeStr stringByAppendingString:trainingStr]];
                }
            }
            [self btnbtn];
        }
    }
}

- (void) checkProgramDetails:(UIButton *)clickButton
{
    AudioServicesPlaySystemSound(SOUND_ID);
    
    NSInteger selectedRow = clickButton.tag - 2000;
    NSString *channelName = _tmpAry[selectedRow];
    
    CHTVProgramShowController *controller = [[CHTVProgramShowController alloc] init];
    controller.channelName = channelName;
    [self presentViewController:controller animated:YES completion:nil];
    NSLog(@"details for tag %ld for channel %@", selectedRow, channelName);
}

#pragma mark - *****************************播放相关参数设定************************************

- (MPMoviePlayerController *)moviewPlayer
{
    if (_moviewPlayer) {
        _moviewPlayer = [[MPMoviePlayerController alloc] init];
        _moviewPlayer.movieSourceType = MPMovieSourceTypeStreaming;
        self.moviewPlayer.fullscreen = YES;
    }
    return _moviewPlayer;
}

- (NSURL *)playCtrlGetCurrMediaTitle:(NSString **)title lastPlayPos:(long *)lastPlayPos
{
    NSLog(@"%@", TEST_STR);
    NSLog(@"%@", self.channeStr);
    return [NSURL URLWithString:self.channeStr];
}

- (NSURL *)playCtrlGetNextMediaTitle:(NSString **)title lastPlayPos:(long *)lastPlayPos
{
    return nil;
}

- (NSURL *)playCtrlGetPrevMediaTitle:(NSString **)title lastPlayPos:(long *)lastPlayPos
{
    return nil;
}

- (NSString *)dealStrWithVStream:(NSString *)vStream
{
    if ([@"2" isEqualToString:vStream]) {
        return @"0x02";
    }else if([@"27" isEqualToString:vStream]){
        return @"0x1B";
    }
    return NULL;
}

- (NSString *)dealStrWithAStream:(NSString *)aStream
{
    if ([@"3" isEqualToString:aStream]) {
        return @"0x03";
    }else if([@"4" isEqualToString:aStream]){
        return @"0x04";
    }else if ([@"6" isEqualToString:aStream] || [@"129" isEqualToString:aStream])
    {
        return @"0x06";
    }
    return NULL;
}

@end
