//
//  RemoteControlViewController.m
//  TVhelper
//
//  Created by shanshu on 15/4/2.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHRemoteControlViewController.h"
#import "UIButton+Create.h"
#import "CHTVSocketManager.h"
#import "CHNoticeAlert.h"
#import "BDVoiceRecognitionClient.h"
#import "BDVRCustomRecognitonViewController.h"
#import "BDVRSConfig.h"
#warning 请修改为您在百度开发者平台申请的API_KEY和SECRET_KEY
#define API_KEY @"5RtF4Yh8DSbqUgSEwGy3F2WR" // 请修改为您在百度开发者平台申请的API_KEY
#define SECRET_KEY @"444456dc997a3f6d9b3990e95b93b99b" // 请修改您在百度开发者平台申请的SECRET_KEY
#define USEFUL_VOICE 10002

#define PORT 9002
#define PORT_CHANNEL 9005
#define CHANNEL_Interitem 0
#define CHANNEL_LINE 10
#define __IPHONE4__ SCREEN_HEIGHT == 480
#define __IPHONEPLUS__ SCREEN_HEIGHT == 736

typedef NS_ENUM(NSInteger, controlOptions)
{
    left = 1000,
    up = 1001,
    center = 1002,
    down = 1003,
    right = 1004,
    volumedown = 1005,
    volumeup = 1006,
    dtv = 1007,
    channel = 1008,
    numberBac = 1009,
    
    home = 1019,
    back = 1020,
    list = 1021,
    power = 1022,
    
    allChannel = 1030,
    HDChannel = 1031,
    starChannel = 1032,
    childChannel = 1033,
    CCTVChannel = 1034
};

typedef NS_OPTIONS(NSUInteger, swipeDirection) {
    swipeRight = 1 << 0,
    swipeLeft  = 1 << 1,
    swipeUp    = 1 << 2,
    swipeDown  = 1 << 3
};
@interface CHRemoteControlViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIAlertViewDelegate>
@property (nonatomic, assign)long sendTag;
@property (nonatomic, strong)UIImageView * controlImage;
@property (nonatomic, strong)UIImageView * menuImage;
@property (nonatomic, strong)UICollectionView * numberCollectionView;
@property (nonatomic, strong)UICollectionView * channelCollectionView;
@property (nonatomic, strong)CHTVSocketManager * socketManager;
@property (nonatomic, strong)NSArray * numberAry;
@property (nonatomic, strong)NSArray * numberSelectedAry;
@property (nonatomic, strong)NSArray * instructAry;
@property (nonatomic, strong)NSArray * channelBtnName;
@property (nonatomic, strong)NSArray * channelAry;
@property (nonatomic, strong)NSArray * nameAry;
@property (nonatomic, strong)NSArray * tmpAry;
@property (nonatomic, strong)NSDictionary * nameImgDic;
@property (nonatomic, strong)UIButton * numberBtn;
@property (nonatomic, strong)UIButton * channelPreBtn;
@property (nonatomic, strong)UIView * numberBackView;
@property (nonatomic, strong)UIView * channelBac;
@property (nonatomic, strong)CHNoticeAlert * noticeAlert;
@property (nonatomic, strong)UIImageView * ballImg;
@property (nonatomic, assign)BOOL screened;
@property (nonatomic, assign)BOOL counted;
@property (nonatomic, strong)NSString * countCommandStr;
@end

@implementation CHRemoteControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSocketManager];
    [self initDataSource];
    [self initWithUserInterface];
}
- (void)initDataSource
{
    _numberAry = [NSArray arrayWithObjects:@"nofocus1", @"nofocus2", @"nofocus3", @"nofocus4", @"nofocus5", @"nofocus6", @"nofocus7", @"nofocus8", @"nofocus9", @"nofocusok", @"nofucos0", @"nofocuscancle", nil];
    _numberSelectedAry = [NSArray arrayWithObjects:@"h_1_focus", @"h_2_focus", @"h_3_focus", @"h_4_focus", @"h_5_focus", @"h_6_focus", @"h_7_focus", @"h_8_focus", @"h_9_focus", @"", @"h_0_focus", @"", nil];
    _instructAry = [NSArray arrayWithObjects:@"key:1", @"key:2", @"key:3", @"key:4", @"key:5", @"key:6", @"key:7", @"key:8", @"key:9", @"key:ok", @"key:0", @"", nil];
    _channelBtnName = [NSArray arrayWithObjects:@"全部", @"高清", @"卫视", @"少儿", @"央视", nil];
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

- (void)loadView
{
    UIImageView *tmpView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    tmpView.image = [UIImage imageNamed:@"remote_bk"];
    tmpView.userInteractionEnabled = YES;
    self.view = tmpView;
}
- (void)initWithUserInterface
{
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self initFuctionBtn];
    [self.view addSubview:self.controlImage];
    [self.view addSubview:self.menuImage];
    [self.view addSubview:self.numberCollectionView];
    [self.view addSubview:self.channelBac];
    [self.view addSubview:self.numberBackView];
    [self.channelBac addSubview:self.channelCollectionView];
    [self.view sendSubviewToBack:self.menuImage];
    [self initchannelBac];

}

- (void)initGesture
{
    for (int i = 0 ; i < 4; i++) {
        UISwipeGestureRecognizer * swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeGesture:)];
        [swipe setDirection:(1 << i)];
        [self.view addGestureRecognizer:swipe];
    }
}
- (void)swipeGesture:(UISwipeGestureRecognizer *)swip
{
    
    UIImageView * ball = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 50, 50)];
    ball.image = [UIImage imageNamed:@"list_focus.png"];
    ball.center = self.view.center;
    [self.view addSubview:ball];
    ball.hidden = NO;
    _controlImage.image = [UIImage imageNamed:@"h_d.png"];
    _menuImage.image = [UIImage imageNamed:@"tv_control_menu.png"];
    switch (swip.direction) {
        case swipeRight:
        {
            [UIView animateWithDuration:1 animations:^{
                ball.center = CGPointMake(self.view.center.x + SCREEN_WIDTH/2, self.view.center.y);
            } completion:^(BOOL finished) {
                ball.hidden = YES;
                [ball removeFromSuperview];
            }];
            [self.socketManager.socket writeBuffer:[self transformData:exright] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
        }
            break;
        case swipeLeft:
        {
            [UIView animateWithDuration:1 animations:^{
                ball.center = CGPointMake(self.view.center.x - SCREEN_WIDTH/2, self.view.center.y);
            } completion:^(BOOL finished) {
                ball.hidden = YES;
                [ball removeFromSuperview];
            }];
            [self.socketManager.socket writeBuffer:[self transformData:exleft] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
        }
            break;
        case swipeUp:
        {
            [UIView animateWithDuration:1 animations:^{
                ball.center = CGPointMake(self.view.center.x , self.view.center.y - SCREEN_HEIGHT/2);
            } completion:^(BOOL finished) {
                ball.hidden = YES;
                [ball removeFromSuperview];
            }];
            [self.socketManager.socket writeBuffer:[self transformData:exup] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
        }
            break;
        case swipeDown:
        {
            [UIView animateWithDuration:1 animations:^{
                ball.center = CGPointMake(self.view.center.x, self.view.center.y + SCREEN_WIDTH/2);
            } completion:^(BOOL finished) {
                ball.hidden = YES;
                [ball removeFromSuperview];
            }];
            [self.socketManager.socket writeBuffer:[self transformData:exdown] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
        }
            break;
            
        default:
            break;
    }
    _counted = NO;
}
- (void)initSocketManager
{
    __weak CHRemoteControlViewController * objself = self;
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

- (void)initFuctionBtn
{
    UIButton * viewBacBtn = [UIButton createButtonWithFrame:CGRectMake(0, SCREEN_HEIGHT - 120, 160, 100) Target:self Tag:back Selector:@selector(processControlBtn:) Image:@"h_b.png" ImagePressed:@"h_b_focus.png"];
    viewBacBtn.center = CGPointMake(self.view.center.x, viewBacBtn.center.y);
    [self.view addSubview:viewBacBtn];
    
    UIButton * homeBtn = [UIButton createButtonWithFrame:CGRectMake(CGRectGetMinX(viewBacBtn.frame) - 100, CGRectGetMinY(viewBacBtn.frame), 120, 100) Target:self Tag:home Selector:@selector(processControlBtn:) Image:@"h_home.png" ImagePressed:@"h_home_focus.png"];
    [self.view addSubview:homeBtn];
    
    UIButton * listBtn = [UIButton createButtonWithFrame:CGRectMake(CGRectGetMaxX(viewBacBtn.frame) - 20, CGRectGetMinY(viewBacBtn.frame), 120, 100) Target:self Tag:list Selector:@selector(processControlBtn:) Image:@"h_menu.png" ImagePressed:@"h_menu_focus.png"];
    [self.view addSubview:listBtn];
    
    UIButton * closeBtn = [UIButton createButtonWithFrame:CGRectMake(SCREEN_WIDTH - 75, 15, 70, 70) Target:self Tag:power Selector:@selector(processControlBtn:) Image:@"power.png" ImagePressed:@"power_focus.png"];
    [self.navigationBarView addSubview:closeBtn];
    
    for (int i = 0; i < 5; i ++) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTag:left + i];
        [button addTarget:self action:@selector(stateHighlighted:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(processControlBtn:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(processOutConttrolBtn) forControlEvents:UIControlEventTouchUpOutside];
        [self.controlImage addSubview:button];
        if (button.tag == center) {
            UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(performJudge:)];
            longPress.minimumPressDuration = 1;
            NSLog(@"======================");
            [button addGestureRecognizer:longPress];
        }
        if ((i  >= 1) && (i <= 3)) {
            [button setFrame:CGRectMake(25 + 70, 95 * (i - 1) , 70, 70)];
            continue;
        }
        [button setFrame:CGRectMake(i/ 4 * 190, 95, 70, 70)];
    }
    
    for (int i = 0; i < 5; i ++) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:CGRectMake(i * 64, 10, 64, 60)];
        [button setTag:volumedown + i];
        if (button.tag == numberBac) {
            self.numberBtn = button;
        }
        [button addTarget:self action:@selector(stateHighlighted:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(processControlBtn:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(processOutConttrolBtn) forControlEvents:UIControlEventTouchUpOutside];
        [self.menuImage addSubview:button];
    }
    _noticeAlert = [[CHNoticeAlert alloc]initWithTittle:@"频道列表为空"];
    _noticeAlert.center = CGPointMake(self.view.center.x, SCREEN_HEIGHT - 150);
    //    [self.view bringSubviewToFront:self.numberCollectionView];
    //    [self.view bringSubviewToFront:self.channelBac];
}

#pragma mark - property
- (UIImageView *)controlImage
{
    if (!_controlImage) {
        _controlImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 260, 260)];
        if (__IPHONEPLUS__) {
            _controlImage.frame = CGRectMake(0, 0, 280, 280);
        }
        _controlImage.center = CGPointMake(self.view.center.x, self.view.center.y + 20);
        _controlImage.image = [UIImage imageNamed:@"h_d.png"];
        _controlImage.userInteractionEnabled = YES;
    }
    return _controlImage;
}
- (UIImageView *)menuImage
{
    if (!_menuImage) {
        if (__IPHONE4__) {
            _menuImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, CGRectGetMinY(self.controlImage.frame) - 70, CGRectGetWidth(self.controlImage.frame) + 60, 80)];
        }else if (__IPHONEPLUS__ ){
            _menuImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, CGRectGetMinY(self.controlImage.frame) - 140, CGRectGetWidth(self.controlImage.frame) + 60, 80)];
        }
        else  _menuImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, CGRectGetMinY(self.controlImage.frame) - 110, CGRectGetWidth(self.controlImage.frame) + 60, 80)];
        _menuImage.center = CGPointMake(self.view.center.x, _menuImage.center.y);
        _menuImage.image = [UIImage imageNamed:@"tv_control_menu.png"];
        _menuImage.userInteractionEnabled = YES;
    }
    return _menuImage;
}
-(UICollectionView *)numberCollectionView
{
    if (!_numberCollectionView) {
        UICollectionViewFlowLayout *flowLayout =
        [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.itemSize = CGSizeMake(SCREEN_WIDTH /3, SCREEN_HEIGHT / 8);
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _numberCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT , SCREEN_WIDTH, SCREEN_HEIGHT / 2) collectionViewLayout:flowLayout];
        UIImageView * collectionBac = [[UIImageView alloc]initWithFrame:_numberCollectionView.frame];
        collectionBac.image = [UIImage imageNamed:@"numback.png"];
        _numberCollectionView.backgroundColor = [UIColor clearColor];
        _numberCollectionView.backgroundView = collectionBac;
        [_numberCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        _numberCollectionView.hidden = YES;
        _numberCollectionView.dataSource = self;
        _numberCollectionView.delegate = self;
    }
    return _numberCollectionView;
}

- (UIView *)numberBackView
{
    if (!_numberBackView) {
        _numberBackView = [[UIView alloc]initWithFrame:CGRectMake(0, 20, SCREEN_WIDTH, SCREEN_HEIGHT - self.numberCollectionView.frame.size.height - 20)];
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureRecognizer)];
        _numberBackView.backgroundColor = [UIColor clearColor];
        _numberBackView.hidden = YES;
        [_numberBackView addGestureRecognizer:tap];
    }
    return _numberBackView;
}

- (UIView *)channelBac
{
    if (!_channelBac) {
        _channelBac = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
        _channelBac.backgroundColor = [UIColor colorWithRed:30/255.0 green:94/255.0 blue:130/255.0 alpha:0.8];
        _channelBac.hidden = YES;
    }
    return _channelBac;
}

- (void)initchannelBac
{
    UIButton * channelBack = [UIButton createButtonWithFrame:CGRectMake(SCREEN_WIDTH - 50, 20, 50, 40) Target:self Tag:channel Selector:@selector(processControlBtn:) Image:@"nofocuscancle" ImagePressed:nil];
    [_channelBac addSubview:channelBack];
    UIButton * currentBtn = nil;
    for (int i = 0; i < 5; i ++) {
        UIButton * btn = [UIButton createButtonWithFrame:CGRectZero Title:_channelBtnName[i] Target:self Tag:allChannel + i Selector:@selector(processChannelBtn:)];
        [btn setTitleColor:[UIColor orangeColor] forState:UIControlStateSelected];
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [[UIColor whiteColor] CGColor];
        [_channelBac addSubview:btn];
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
    [self initGesture];
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

//#pragma mark - process
- (void)tapGestureRecognizer
{
    [self processControlBtn:self.numberBtn];
}
- (void)processGobackBtn
{
    AudioServicesPlaySystemSound(SOUND_ID);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)processControlBtn:(UIButton *)btn
{
    if (btn.tag >= dtv) {
        AudioServicesPlaySystemSound(SOUND_ID);
    }
    btn.selected = !btn.selected;
    switch (btn.tag) {
        case left:
            //            [self.socketManager.socket writeBuffer:[self transformData:exleft] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            NSLog(@"%@", self.socketManager.selectedIP);
            break;
        case right:
            //            [self.socketManager.socket writeBuffer:[self transformData:exright] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            break;
        case up:
            //            [self.socketManager.socket writeBuffer:[self transformData:exup] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            break;
        case down:
            //            [self.socketManager.socket writeBuffer:[self transformData:exdown] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            break;
        case center:
            [self.socketManager.socket writeBuffer:[self transformData:excenter] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            break;
        case volumedown:
            //            [self.socketManager.socket writeBuffer:[self transformData:exvolumedown] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            break;
        case volumeup:
            //            [self.socketManager.socket writeBuffer:[self transformData:exvolumeup] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            break;
        case dtv:
        {
            [self.socketManager.socket writeBuffer:[self transformData:exdtv] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            self.screened = YES;
        }
            break;
        case channel:
        {
            static BOOL channelSelected = NO;
            channelSelected = !channelSelected;
            if (_tmpAry.count == 0 && channelSelected) {
                [_noticeAlert setLabelString:@"频道列表为空"];
                [_noticeAlert show];
                [self performSelector:@selector(dismissAlert) withObject:nil afterDelay:2];
            }
            self.channelBac.hidden = !channelSelected;
            
            break;
        }
        case numberBac:
        {
            self.numberCollectionView.hidden = NO;
            self.numberBackView.hidden = NO;
            if (!btn.selected) {
                self.numberBackView.hidden = YES;
            }
            [UIView animateWithDuration:0.5 animations:^{
                self.numberCollectionView.center = CGPointMake(self.numberCollectionView.center.x, self.numberCollectionView.center.y- (btn.selected ? SCREEN_HEIGHT/2 : -SCREEN_HEIGHT/2));
            } completion:^(BOOL finished) {
                if (!btn.selected) {
                    self.numberCollectionView.hidden = YES;
                    self.numberBackView.hidden = YES;
                }
            }];
        }
            break;
        case home:
        {
            [self.socketManager.socket writeBuffer:[self transformData:exhome] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            self.screened = NO;
        }
            break;
        case back:
        {
            [self.socketManager.socket writeBuffer:[self transformData:exback] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            self.screened = NO;
            break;
        }
        case list:
            [self.socketManager.socket writeBuffer:[self transformData:exlist] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
            break;
        case power:
        {
            UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"是否开/关机顶盒" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            alertView.delegate = self;
            [alertView show];
            break;
        }
            
        default:
            break;
    }
    _controlImage.image = [UIImage imageNamed:@"h_d.png"];
    _menuImage.image = [UIImage imageNamed:@"tv_control_menu.png"];
    _sendTag ++;
    _counted = NO;
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

- (void)stateHighlighted:(UIButton *)btn
{
    switch (btn.tag) {
        case up:
            self.controlImage.image = [UIImage imageNamed:@"h_d_up.png"];
            break;
        case right:
            self.controlImage.image = [UIImage imageNamed:@"h_d_right.png"];
            break;
        case down:
            self.controlImage.image = [UIImage imageNamed:@"h_d_down.png"];
            break;
        case left:
            self.controlImage.image = [UIImage imageNamed:@"h_d_left.png"];
            break;
        case center:
            self.controlImage.image = [UIImage imageNamed:@"h_d_center.png"];
            break;
        case volumedown:
            self.menuImage.image = [UIImage imageNamed:@"tv_control_menu_volumminus.png"];
            break;
        case volumeup:
            self.menuImage.image = [UIImage imageNamed:@"tv_control_menu_volumplus.png"];
            break;
        case dtv:
            self.menuImage.image = [UIImage imageNamed:@"tv_control_menu_tv.png"];
            break;
        case channel:
            self.menuImage.image = [UIImage imageNamed:@"tv_control_menu_channel.png"];
            break;
        case numberBac:
            self.menuImage.image = [UIImage imageNamed:@"tv_control_menu_num.png"];
            break;
        default:
            break;
    }
    if (btn.tag == center) {
        return;
    }
    
    if (btn.tag < dtv) {
        NSLog(@"%@", self.socketManager.selectedIP);
        NSArray * countCommandAry = [NSArray arrayWithObjects:exleft,exup,@"",exdown,exright,exvolumedown,exvolumeup, nil];
        self.countCommandStr = countCommandAry[btn.tag - 1000];
        dispatch_queue_t serialQueue=dispatch_queue_create("myThreadQueue2", DISPATCH_QUEUE_SERIAL);
        _counted = YES;
        dispatch_async(serialQueue, ^{
            NSLog(@"%@", self.socketManager.selectedIP);
            while (_counted) {
                NSLog(@"%@ %@", self.socketManager.selectedIP, self.countCommandStr);
                AudioServicesPlaySystemSound(SOUND_ID);
                [self.socketManager.socket writeBuffer:[self transformData:self.countCommandStr] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
                [NSThread sleepForTimeInterval:0.5];
            }
        });
        
        NSLog(@"%@", NSStringFromSelector(_cmd));
    }
}

- (void)processOutConttrolBtn
{
    _counted = NO;
}

- (void)processOutSide:(UIButton *)btn
{
    
    NSLog(@"%ld", btn.tag);
}

- (NSData *)transformData:(NSString *)str
{
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dismissAlert
{
    [_noticeAlert dismiss];
}

#pragma mark data source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == self.numberCollectionView) {
        return self.numberAry.count;
    }
    return _tmpAry.count;
}

///配置cellx
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    if (collectionView == self.numberCollectionView) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
        UIImageView * cellImg = [[UIImageView alloc]initWithFrame:cell.frame];
        cellImg.image = [UIImage imageNamed:self.numberAry[indexPath.row]];
        cell.backgroundView = cellImg;
        UIImageView * cellSelected = [[UIImageView alloc]initWithFrame:cell.frame];
        cellSelected.image = [UIImage imageNamed:self.numberSelectedAry[indexPath.row]];
        cell.selectedBackgroundView = cellSelected;
        return cell;
    }
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"channel" forIndexPath:indexPath];
    for (UIView * view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    cell.backgroundColor = COLOR_RGB(37, 74, 94, 1);
    UILabel * nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetHeight(cell.frame) - 20, CGRectGetWidth(cell.frame), 20)];
    nameLabel.text = _tmpAry[indexPath.row];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.font = [UIFont systemFontOfSize:14];
    nameLabel.backgroundColor = COLOR_RGB(17, 58, 80, 1);
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH / 4 - 50, 5, 80, 45)];
    if ([_nameImgDic objectForKey:_tmpAry[indexPath.row]] != nil ) {
        UIImage * imgTmp = [UIImage imageNamed:[_nameImgDic objectForKey:_tmpAry[indexPath.row]]];
        [imgTmp imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        imageView.image = imgTmp;
    }else{
        imageView.frame = CGRectMake(SCREEN_WIDTH / 4 - 50, 5, 80, 35);
        imageView.image = [UIImage imageNamed:@"logotv.png"];
    }
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.selectedBackgroundView = [[UIView alloc]initWithFrame:cell.frame];
    cell.selectedBackgroundView.backgroundColor = COLOR_RGB(251, 255, 185, 1);
    [cell.contentView addSubview:nameLabel];
    [cell.contentView addSubview:imageView];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AudioServicesPlaySystemSound(SOUND_ID);
    if (collectionView == self.numberCollectionView) {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        [self.socketManager.socket writeBuffer:[self transformData:_instructAry[indexPath.row]] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
        if (indexPath.row == _instructAry.count - 1) {
            [self processControlBtn:self.numberBtn];
        }
    }
    if (collectionView == self.channelCollectionView) {
        for (NSDictionary * dic in _channelAry) {
            [collectionView deselectItemAtIndexPath:indexPath animated:YES];
            if ([[dic objectForKey:@"service_name"] isEqualToString:_tmpAry[indexPath.row]]) {
                NSString * order = [NSString stringWithFormat:@"%@#%@#%@", [dic objectForKey:@"service_id"], [dic objectForKey:@"tsId"], [dic objectForKey:@"orgNId"]];
                if (!_screened) {
                    [self.socketManager.socket writeBuffer:[self transformData:exdtv] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
                    _screened = YES;
                }
                [self.socketManager.socket writeBuffer:[self transformData:order] onHost:self.socketManager.selectedIP port:PORT_CHANNEL inTimeout:-1 tag:_sendTag];
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self.socketManager.socket writeBuffer:[self transformData:expower] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
    }
}

- (void)performJudge:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {//判断开始
        _controlImage.image = [UIImage imageNamed:@"h_d.png"];
        [self judgeTheVoice];
    }

}

- (void)judgeTheVoice
{
    
    // 设置开发者信息
    [[BDVoiceRecognitionClient sharedInstance] setApiKey:API_KEY withSecretKey:SECRET_KEY];
    
    // 设置语音识别模式，默认是输入模式
    [[BDVoiceRecognitionClient sharedInstance] setPropertyList:@[@(USEFUL_VOICE)]];
    
    // 设置城市ID，当识别属性包含EVoiceRecognitionPropertyMap时有效
    [[BDVoiceRecognitionClient sharedInstance] setCityID: 1];
    
    // 设置是否需要语义理解，只在搜索模式有效
    [[BDVoiceRecognitionClient sharedInstance] setConfig:@"nlu" withFlag:[BDVRSConfig sharedInstance].isNeedNLU];
    
    // 开启联系人识别
    //    [[BDVoiceRecognitionClient sharedInstance] setConfig:@"enable_contacts" withFlag:YES];
    
    // 设置识别语言
    [[BDVoiceRecognitionClient sharedInstance] setLanguage:[BDVRSConfig sharedInstance].recognitionLanguage];
    
    // 是否打开语音音量监听功能，可选
    if ([BDVRSConfig sharedInstance].voiceLevelMeter)
    {
        BOOL res = [[BDVoiceRecognitionClient sharedInstance] listenCurrentDBLevelMeter];
        
        if (res == NO)  // 如果监听失败，则恢复开关值
        {
            [BDVRSConfig sharedInstance].voiceLevelMeter = NO;
        }
    }
    else
    {
        [[BDVoiceRecognitionClient sharedInstance] cancelListenCurrentDBLevelMeter];
    }
    
    // 设置播放开始说话提示音开关，可选
    [[BDVoiceRecognitionClient sharedInstance] setPlayTone:EVoiceRecognitionPlayTonesRecStart isPlay:[BDVRSConfig sharedInstance].playStartMusicSwitch];
    // 设置播放结束说话提示音开关，可选
    [[BDVoiceRecognitionClient sharedInstance] setPlayTone:EVoiceRecognitionPlayTonesRecEnd isPlay:[BDVRSConfig sharedInstance].playEndMusicSwitch];
    
    // 创建语音识别界面，在其viewdidload方法中启动语音识别
    BDVRCustomRecognitonViewController *tmpAudioViewController = [[BDVRCustomRecognitonViewController alloc] initWithNibName:nil bundle:nil];
    tmpAudioViewController.clientSampleViewController = self;
    self.audioViewController = tmpAudioViewController;
    //    [tmpAudioViewController release];
    
    [[UIApplication sharedApplication].keyWindow addSubview:_audioViewController.view];
    
}



#pragma mark - log & result

- (void)logOutToContinusManualResut:(NSString *)aResult
{
    
}

- (void)logOutToManualResut:(NSString *)aResult
{

}

- (void)logOutToLogView:(NSString *)aLog
{
    
}



- (void)logOutToLogStr:(NSString *)str
{
    str = [str stringByReplacingOccurrencesOfString :@"cctv" withString:@"CCTV-"];
    str = [str stringByReplacingOccurrencesOfString :@"中央" withString:@"CCTV-"];
    str = [str stringByReplacingOccurrencesOfString :@"四川" withString:@"SCTV-"];
    str = [str stringByReplacingOccurrencesOfString :@"成都" withString:@"CDTV-"];
    str = [str stringByReplacingOccurrencesOfString :@"一" withString:@"1"];
    str = [str stringByReplacingOccurrencesOfString :@"二" withString:@"2"];
    str = [str stringByReplacingOccurrencesOfString :@"三" withString:@"3"];
    str = [str stringByReplacingOccurrencesOfString :@"四" withString:@"4"];
    str = [str stringByReplacingOccurrencesOfString :@"五" withString:@"5"];
    str = [str stringByReplacingOccurrencesOfString :@"六" withString:@"6"];
    str = [str stringByReplacingOccurrencesOfString :@"七" withString:@"7"];
    str = [str stringByReplacingOccurrencesOfString :@"八" withString:@"8"];
    str = [str stringByReplacingOccurrencesOfString :@"九" withString:@"9"];
    str = [str stringByReplacingOccurrencesOfString :@"十" withString:@"10"];
    str = [str stringByReplacingOccurrencesOfString :@"十一" withString:@"11"];
    str = [str stringByReplacingOccurrencesOfString :@"十二" withString:@"12"];
    str = [str stringByReplacingOccurrencesOfString :@"十三" withString:@"13"];
    str = [str stringByReplacingOccurrencesOfString :@"台" withString:@""];
    str = [str stringByReplacingOccurrencesOfString :@"套" withString:@""];
    str = [str stringByReplacingOccurrencesOfString :@"电视" withString:@""];
    str = [str stringByReplacingOccurrencesOfString :@"电视台" withString:@""];
    str = [str stringByReplacingOccurrencesOfString :@"频道" withString:@""];
    str = [str stringByReplacingOccurrencesOfString :@"卫视" withString:@""];
    str = [str stringByReplacingOccurrencesOfString :@"高清" withString:@""];
    NSLog(@"=======>%@", str);
    [self sendVoiceCommand:str];
}

- (void)sendVoiceCommand:(NSString *)originalStr
{
    NSInteger indexLengh = 10;
    NSMutableArray * array = [[NSMutableArray alloc]init];
    for (NSString * obj in _tmpAry) {
        if ([obj containsString:originalStr]) {
            if (indexLengh > obj.length) {
                [array insertObject:obj atIndex:0];
            }else{
                [array addObject:obj];
                NSLog(@"%@", array.lastObject);
            }
            indexLengh = obj.length;
        }
    }
    NSMutableArray * arrayTarge = [[NSMutableArray alloc]init];
    NSString * str = [originalStr substringToIndex:1];
    NSLog(@"%@", str);
    for (NSString * obj in arrayTarge) {
        if ([obj hasPrefix:str]) {
            [arrayTarge addObject:obj];
        }
    }
    if (array.count > 0) {
        NSString * targeStr = arrayTarge.count > 0 ? arrayTarge[0] : array[0];
        NSLog(@"%@", targeStr);
        for (NSDictionary * dic in _channelAry) {
            if ([[dic objectForKey:@"service_name"] isEqualToString:targeStr]) {
                NSString * tmpStr = [NSString stringWithFormat:@"正在跳转至%@", targeStr];
                [_noticeAlert setLabelString:tmpStr];
                [_noticeAlert show];
                [self performSelector:@selector(dismissAlert) withObject:nil afterDelay:2];
                NSString * order = [NSString stringWithFormat:@"%@#%@#%@", [dic objectForKey:@"service_id"], [dic objectForKey:@"tsId"], [dic objectForKey:@"orgNId"]];
                if (!_screened) {
                    [self.socketManager.socket writeBuffer:[self transformData:exdtv] onHost:self.socketManager.selectedIP port:PORT inTimeout:-1 tag:_sendTag];
                    _screened = YES;
                }
                [self.socketManager.socket writeBuffer:[self transformData:order] onHost:self.socketManager.selectedIP port:PORT_CHANNEL inTimeout:-1 tag:_sendTag];
            }
        }
    }else{
        [_noticeAlert setLabelString:@"未能识别出语音"];
        [_noticeAlert show];
        [self performSelector:@selector(dismissAlert) withObject:nil afterDelay:2];
    }
}


@end
