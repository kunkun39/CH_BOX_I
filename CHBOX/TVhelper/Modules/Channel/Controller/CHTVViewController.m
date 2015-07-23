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

typedef NS_ENUM(NSInteger, channelTag)
{
    allChannel = 1030,
    HDChannel = 1031,
    starChannel = 1032,
    childChannel = 1033,
    CCTVChannel = 1034
    
};

typedef NS_ENUM(NSInteger, CHtag)
{
    TV = 3,
    channel = 4
};
@interface CHTVViewController ()<UITableViewDataSource, UITableViewDelegate, PlayerControllerDelegate>
@property (nonatomic, strong)UIButton * channelPreBtn;
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
    NSArray * btnNames = @[@"全部", @"高清", @"卫视", @"少儿", @"央视"];
    UIButton * currentBtn = nil;
    for (int i = 0; i < 5; i ++) {
        UIButton * btn = [UIButton createButtonWithFrame:CGRectZero Title:btnNames[i] Target:self Tag:allChannel + i Selector:@selector(processChannelBtn:)];
        [btn setTitleColor:[UIColor orangeColor] forState:UIControlStateSelected];
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [[UIColor whiteColor] CGColor];
        [self.view addSubview:btn];
        if (i == 0) {
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-aboutSpacing-[btn]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"aboutSpacing":@(LINE_SPACING)} views:NSDictionaryOfVariableBindings(btn)]];
            btn.selected = YES;
            _channelPreBtn = btn;
        }else if (i == 4){
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[currentBtn]-aboutSpacing-[btn(==currentBtn)]-aboutSpacing-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"aboutSpacing":@(LINE_SPACING)} views:NSDictionaryOfVariableBindings(btn,currentBtn)]];
        }else{
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[currentBtn]-aboutSpacing-[btn(==currentBtn)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"aboutSpacing":@(LINE_SPACING)} views:NSDictionaryOfVariableBindings(btn,currentBtn)]];
        }
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-aboutSpacing-[btn(30)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"aboutSpacing":@(NAV_BAR_HEIGHT)} views:NSDictionaryOfVariableBindings(btn)]];
        currentBtn = btn;
        [btn layoutIfNeeded];
    }
}

#pragma mark - property
- (UITableView *)channelTableView
{
    if (!_channelTableView) {
        _channelTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, NAV_BAR_HEIGHT + 30, SCREEN_WIDTH,SCREEN_HEIGHT - NAV_BAR_HEIGHT - 30)style:UITableViewStylePlain];
        _channelTableView.backgroundColor = [UIColor clearColor];
        _channelTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _channelTableView.allowsSelection = NO;
        _channelTableView.delegate = self;
        _channelTableView.dataSource = self;

    }
    return _channelTableView;
}

- (MPMoviePlayerController *)moviewPlayer
{
    if (_moviewPlayer) {
        _moviewPlayer = [[MPMoviePlayerController alloc] init];
        _moviewPlayer.movieSourceType = MPMovieSourceTypeStreaming;
        self.moviewPlayer.fullscreen = YES;
    }
    return _moviewPlayer;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - process
- (void)processGobackBtn
{
    AudioServicesPlaySystemSound(SOUND_ID);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)processChannelBtn:(UIButton *)btn
{
    AudioServicesPlaySystemSound(SOUND_ID);
    _channelPreBtn.selected = NO;
    btn.selected = YES;
    _channelPreBtn = btn;
    switch (btn.tag) {
        case allChannel:
            _tmpAry = _nameAry;
            break;
        case HDChannel:
        {
            NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF CONTAINS 'HD' OR SELF CONTAINS '高清'"];
            _tmpAry = [_nameAry filteredArrayUsingPredicate:pred];
        }
            break;
        case starChannel:
        {
            NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF CONTAINS '卫视'"];
            _tmpAry = [_nameAry filteredArrayUsingPredicate:pred];
            
        }
            break;
        case childChannel:
        {
            NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF CONTAINS '少儿' OR SELF CONTAINS '卡通' OR SELF CONTAINS '动漫' OR SELF CONTAINS '成长'"];
            _tmpAry = [_nameAry filteredArrayUsingPredicate:pred];
        }
            break;
        case CCTVChannel:
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

- (NSData *)transformData:(NSString *)str
{
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}


#pragma mark - ********************************table view相关参数设置******************************************

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
    channelNameLabel.backgroundColor = COLOR_RGB(30, 30, 30, 1);
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
    NSInteger selectedRow = clickButton.tag - 2000;
    NSString *channelName = _tmpAry[selectedRow];
    
    CHTVProgramShowController *controller = [[CHTVProgramShowController alloc] init];
    controller.channelName = channelName;
    [self presentViewController:controller animated:YES completion:nil];
    NSLog(@"details for tag %ld for channel %@", selectedRow, channelName);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    AudioServicesPlaySystemSound(SOUND_ID);
    for (NSDictionary * dic in _channelAry) {
        if ([[dic objectForKey:@"service_name"] isEqualToString:_tmpAry[indexPath.row]]) {
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


#pragma mark - *****************************播放相关参数设定************************************

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
