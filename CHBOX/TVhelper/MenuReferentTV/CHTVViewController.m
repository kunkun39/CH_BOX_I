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
@interface CHTVViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, PlayerControllerDelegate>
@property (nonatomic, strong)UIButton * channelPreBtn;
@property (nonatomic, strong)UITableView * channelTableView;
@property (nonatomic, strong)NSArray * channelAry;
@property (nonatomic, strong)NSArray * nameAry;
@property (nonatomic, strong)NSArray * tmpAry;
@property (nonatomic, strong)NSDictionary * nameImgDic;
@property (nonatomic, strong)MPMoviePlayerController * moviewPlayer;
@property (nonatomic, strong)UICollectionView * channelCollectionView;
@property (nonatomic, strong)CHTVSocketManager * socketManager;
@property (nonatomic, strong)NSString * channeStr;
@end

@implementation CHTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
        [objself.channelCollectionView reloadData];
    };
}


- (void)initUserInterface
{
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.view.backgroundColor = COLOR_RGB(50, 50, 50, 1);
    [self.view addSubview:self.channelCollectionView];
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
        _channelTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, NAV_BAR_HEIGHT + 30, SCREEN_WIDTH,SCREEN_HEIGHT - NAV_BAR_HEIGHT - 30) style:UITableViewStylePlain];
        _channelTableView.backgroundColor = [UIColor clearColor];
        _channelTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        UIImageView * channelTableBac = [[UIImageView alloc]initWithFrame:_channelTableView.frame];
        channelTableBac.image = [UIImage imageNamed:@"bk.png"];
        _channelTableView.backgroundView = channelTableBac;
//        _channelTableView.delegate = self;
//        _channelTableView.dataSource = self;
        _channelTableView.hidden = YES;

    }
    return _channelTableView;
}

- (UICollectionView *)channelCollectionView
{
    if (!_channelCollectionView) {
        UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc]init];
        layout.minimumInteritemSpacing = CHANNEL_Interitem;
        layout.minimumLineSpacing =  CHANNEL_LINE;
        layout.itemSize = CGSizeMake(SCREEN_WIDTH / 2 - 20, 80);
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _channelCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 100, SCREEN_WIDTH, SCREEN_HEIGHT - 100) collectionViewLayout:layout];
        _channelCollectionView.backgroundColor = [UIColor clearColor];
        [_channelCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"channel"];
        _channelCollectionView.delegate = self;
        _channelCollectionView.dataSource = self;
    }
    return _channelCollectionView;
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
    [self.channelCollectionView reloadData];
    
}

- (NSData *)transformData:(NSString *)str
{
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}


#pragma mark - delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _tmpAry.count;
}

///配置cellx
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"channel" forIndexPath:indexPath];
    for (UIView * view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    cell.backgroundColor = COLOR_RGB(60, 60, 60, 1);
    UILabel * nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetHeight(cell.frame) - 20, CGRectGetWidth(cell.frame), 20)];
    nameLabel.text = _tmpAry[indexPath.row];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.font = [UIFont systemFontOfSize:14];
    nameLabel.backgroundColor = COLOR_RGB(30, 30, 30, 1);
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH / 4 - 50, 5, 80, 45)];
    if ([_nameImgDic objectForKey:_tmpAry[indexPath.row]] != nil ) {
        UIImage * imgTmp = [UIImage imageNamed:[_nameImgDic objectForKey:_tmpAry[indexPath.row]]];
        [imgTmp imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        imageView.image = imgTmp;
    }else{
        imageView.image = [UIImage imageNamed:@"logotv.png"];
    }
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.selectedBackgroundView = [[UIView alloc]initWithFrame:cell.frame];
    cell.selectedBackgroundView.backgroundColor = COLOR_RGB(251, 255, 185, 1);
    [cell.contentView addSubview:nameLabel];
    [cell.contentView addSubview:imageView];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.channelTableView) {
        return 98;
    }
    return TABELVIEW_HEIGHT;
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


#pragma mark - PlayerControllerDelegate

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
