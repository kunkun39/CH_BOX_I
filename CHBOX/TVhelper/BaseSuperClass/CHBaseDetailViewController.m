//
//  BaseDetailViewController.m
//  TVhelper
//
//  Created by shanshu on 15/4/2.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHBaseDetailViewController.h"
#import "Reachability.h"
#import "CHTVSocketManager.h"

enum controlBtn {gobackBtn, CHBoxBtn};
@interface CHBaseDetailViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) CHTVSocketManager * socketManager;
@end

@implementation CHBaseDetailViewController
- (void)dealloc{
    if (self.socketManager != nil) {
        [self.socketManager removeObserver:self forKeyPath:@"IPlistAry" context:nil];
        [self.socketManager removeObserver:self forKeyPath:@"selectedIP" context:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addobserverToSocket];
    [self initInterface];
}

- (void)addobserverToSocket
{
    self.socketManager = [CHTVSocketManager shareTVSocketManager];
    self.socketManager.plistBack  = ^{
    };
    [self.socketManager addObserver:self forKeyPath:@"IPlistAry" options:NSKeyValueObservingOptionNew context:nil];
    [self.socketManager addObserver:self forKeyPath:@"selectedIP" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)initInterface
{
    self.navigationController.navigationBarHidden = YES;
    [self.view addSubview:self.navigationBarView];
    [self.navigationBarView addSubview:self.gobackBtn];
    [self.navigationBarView addSubview:self.CHBoxBtn];
    [self.view addSubview:self.CHBoxTableView];
    self.CHBoxTableView.hidden = YES;
    _CHBoxImageView = [[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetWidth(_CHBoxBtn.frame) - 16, 13, 15, 10)];
    _CHBoxImageView.image = [UIImage imageNamed:@"h_select.png"];
    [self.CHBoxBtn addSubview:_CHBoxImageView];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - property

- (UIView *)navigationBarView
{
    if (!_navigationBarView) {
        _navigationBarView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, NAV_BAR_HEIGHT)];
        _navigationBarView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"banner.png"]];
    }
    return _navigationBarView;
}

- (UIButton *)gobackBtn
{
    if (!_gobackBtn) {
        _gobackBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 20, 70, 60)];
        _gobackBtn.tag = gobackBtn;
        _gobackBtn.clipsToBounds = YES;
        [_gobackBtn setTintColor:[UIColor whiteColor]];
        [_gobackBtn setImage:[[UIImage imageNamed:@"h_back.png"] imageWithRenderingMode:UIImageRenderingModeAutomatic]forState:UIControlStateNormal];
        [_gobackBtn setImage:[UIImage imageNamed:@"h_back_focus.png"] forState:UIControlStateHighlighted];
        [_gobackBtn addTarget:self action:@selector(processGobackBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _gobackBtn;
}

- (UIButton *)CHBoxBtn
{
    if (!_CHBoxBtn) {
        _CHBoxBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 20, 100, 35)];
        _CHBoxBtn.center = CGPointMake(self.view.center.x - 8, _CHBoxBtn.center.y);
        _CHBoxBtn.tag = CHBoxBtn;
        [_CHBoxBtn setTitle: self.socketManager.selectedIP == nil? @"未连接" : @"CHBOX" forState:UIControlStateNormal];
        NSLog(@"%@", self.socketManager.selectedIP);
        [_CHBoxBtn addTarget:self action:@selector(processControlBtnWithBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _CHBoxBtn;
}

- (UITableView *)CHBoxTableView
{
    if (!_CHBoxTableView) {
        _CHBoxTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, NAV_BAR_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT - NAV_BAR_HEIGHT) style:UITableViewStylePlain];
        _CHBoxTableView.backgroundColor = [UIColor clearColor];
        self.CHBoxTableView.dataSource = self;
        self.CHBoxTableView.delegate = self;
        UIImageView * tableBac = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - NAV_BAR_HEIGHT)];
        tableBac.image = [UIImage imageNamed:@"listback.png"];
        _CHBoxTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _CHBoxTableView.bounces = NO;
        [_CHBoxTableView addSubview:tableBac];
        [_CHBoxTableView sendSubviewToBack:tableBac];
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hidTableView)];
        tap.delegate = self;
        [_CHBoxTableView addGestureRecognizer:tap];
    }
    return _CHBoxTableView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - process
- (void)processGobackBtn
{
    AudioServicesPlaySystemSound(SOUND_ID);
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)hidTableView
{
    self.CHBoxTableView.hidden = YES;
}
- (void)processControlBtnWithBtn:(UIButton *)btn
{
    switch (btn.tag) {
        case gobackBtn:
            
            break;
        case CHBoxBtn:
        {
            btn.selected = !btn.selected;
            if (btn.selected) {
                NSString* site = @"www.apple.com";
                // 创建访问指定站点的Reachability
                __weak typeof(self) wself = self;
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(queue, ^{
                    Reachability* reach = [Reachability reachabilityWithHostName:site];
                    switch ([reach currentReachabilityStatus])
                    {
                            // 不能访问
                        case NotReachable:
                        [wself performSelectorOnMainThread:@selector(showAlert:) withObject:@"不能访问网络" waitUntilDone:NO];
                            break;
                        case ReachableViaWWAN:
                            break;
                        default:
                        [wself performSelectorOnMainThread:@selector(showAlert:) withObject:@"请使用WiFi网络访问" waitUntilDone:NO];
                            break;
                    }
                });

                // 判断该设备的网络状态

            }
            self.CHBoxTableView.hidden = !self.CHBoxTableView.hidden;
            NSLog(@"%@", self.socketManager.selectedIP);
            
        }
            break;
            
        default:
            break;
    }
}

- (void)tableviewReload
{
    [self.CHBoxTableView reloadData];
}

- (void)updateCHBoxBtn
{
    [_CHBoxBtn setTitle: self.socketManager.selectedIP == nil? @"未连接" : @"CHBOX" forState:UIControlStateNormal];
}

- (void) showAlert:(NSString*)msg
{
    UIAlertView* alert = [[UIAlertView alloc]
                          initWithTitle:@"网络状态" message:msg delegate:nil
                          cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}


#pragma mark - delegate
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"IPlistAry"]) {
        [self performSelectorOnMainThread:@selector(tableviewReload) withObject:nil waitUntilDone:NO];
    }
    if ([keyPath isEqualToString:@"selectedIP"]) {
        [self performSelectorOnMainThread:@selector(updateCHBoxBtn) withObject:nil waitUntilDone:NO];
        if (self.socketManager.selectedIP != nil) {
            dispatch_queue_t queue = dispatch_get_main_queue();
            dispatch_async(queue, ^{
                [self.socketManager socketChannelInfo];
            });
        }
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.socketManager.IPlistAry.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellID = @"cellID";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = self.socketManager.IPlistAry[indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.CHBoxBtn setTitle:@"CHBOX" forState:UIControlStateNormal];
    self.socketManager.selectedIP = nil;
    self.socketManager.selectedIP = self.socketManager.IPlistAry[indexPath.row];
    [self processControlBtnWithBtn:self.CHBoxBtn];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return  YES;
}

@end
