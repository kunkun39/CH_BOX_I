//
//  PlayerController.m
//  Vitamio-Demo
//
//  Created by erlz nuo(nuoerlz@gmail.com) on 7/8/13.
//  Copyright (c) 2013 yixia. All rights reserved.
//

#import "Utilities.h"
#import "PlayerController.h"
#import "VSegmentSlider.h"


@interface PlayerController ()
{
    VMediaPlayer       *mMPayer;
    long               mDuration;
    long               mCurPostion;
    NSTimer            *mSyncSeekTimer;
    NSTimer            *justTimer;
}

@property (nonatomic, assign) IBOutlet UIButton *startPause;
@property (nonatomic, assign) IBOutlet UIButton *reset;
@property (nonatomic, assign) IBOutlet VSegmentSlider *progressSld;
@property (nonatomic, assign) IBOutlet UILabel  *curPosLbl;
@property (nonatomic, assign) IBOutlet UILabel  *durationLbl;
@property (nonatomic, assign) IBOutlet UILabel  *bubbleMsgLbl;
@property (nonatomic, assign) IBOutlet UILabel  *downloadRate;
@property (nonatomic, assign) IBOutlet UIView  	*activityCarrier;
@property (nonatomic, assign) IBOutlet UIView  	*backView;
@property (nonatomic, assign) IBOutlet UIView  	*carrier;
@property (nonatomic, copy)   NSURL *videoURL;
@property (nonatomic, retain) UIActivityIndicatorView *activityView;
@property (nonatomic, assign) BOOL progressDragging;
@property (strong, nonatomic) IBOutlet UIView *controlBac;
@property (strong, nonatomic) IBOutlet UILabel *tipLabel;
@property (assign, nonatomic) BOOL happenedError;
@property (assign, nonatomic) BOOL isInvatil;
@end



@implementation PlayerController


#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.bounds = [[UIScreen mainScreen] bounds];
    self.activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                          UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    [self.activityCarrier addSubview:self.activityView];
    
    UITapGestureRecognizer *gr = [[[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(progressSliderTapped:)] autorelease];
    [self.progressSld addGestureRecognizer:gr];
    [self.progressSld setThumbImage:[UIImage imageNamed:@"pb-seek-bar-btn"] forState:UIControlStateNormal];
    [self.progressSld setMinimumTrackImage:[UIImage imageNamed:@"pb-seek-bar-fr"] forState:UIControlStateNormal];
    [self.progressSld setMaximumTrackImage:[UIImage imageNamed:@"pb-seek-bar-bg"] forState:UIControlStateNormal];
    self.controlBac.hidden = YES;
    if (!mMPayer) {
        mMPayer = [VMediaPlayer sharedInstance];
        [mMPayer setupPlayerWithCarrierView:self.carrier withDelegate:self];
        [self setupObservers];
    }
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGesture)];
    [self.carrier addGestureRecognizer:tap];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(doInvatilPlayer) name:@"invatilPlayer" object:nil];
}

- (void)doInvatilPlayer
{
    if (!_isInvatil) {
        justTimer = nil;
        [self unSetupObservers];
        [mMPayer unSetupPlayer];
        _isInvatil = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    [self currButtonAction:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
   
    [_videoURL release];
    [_activityView release];
    if (!_isInvatil) {
        justTimer = nil;
        [self unSetupObservers];
        [mMPayer unSetupPlayer];
        _isInvatil = YES;
    }
    [super dealloc];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)to duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(to)) {
        self.controlBac.hidden = YES;
    } else {
        self.controlBac.hidden = NO;
    }
    NSLog(@"NAL 1HUI &&&&&&&&& frame=%@", NSStringFromCGRect(self.carrier.frame));
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSLog(@"NAL 2HUI &&&&&&&&& frame=%@", NSStringFromCGRect(self.carrier.frame));
}


#pragma mark - Respond to the Remote Control Events

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)tapGesture
{
    self.controlBac.hidden = !self.controlBac.hidden;
}


- (void)applicationDidEnterForeground:(NSNotification *)notification
{
    [mMPayer setVideoShown:YES];
    if (![mMPayer isPlaying]) {
        [mMPayer start];
        [self.startPause setTitle:@"暂停" forState:UIControlStateNormal];
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    if ([mMPayer isPlaying]) {
        [mMPayer pause];
        [mMPayer setVideoShown:NO];
    }
}

- (void)clearCache
{
    [mMPayer clearCache];
}

#pragma mark - VMediaPlayerDelegate Implement

#pragma mark VMediaPlayerDelegate Implement / Required

- (void)mediaPlayer:(VMediaPlayer *)player didPrepared:(id)arg
{
    [player setVideoFillMode:VMVideoFillModeStretch];
    
    mDuration = [player getDuration];
    [player start];
    
    [self setBtnEnableStatus:YES];
    [self stopActivity];
    mSyncSeekTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/3
                                                      target:self
                                                    selector:@selector(syncUIStatus)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)mediaPlayer:(VMediaPlayer *)player playbackComplete:(id)arg
{
    [self goBackButtonAction:nil];
}

- (void)mediaPlayer:(VMediaPlayer *)player error:(id)arg
{
    NSLog(@"NAL 1RRE &&&& VMediaPlayer Error: %@", arg);
    _happenedError = YES;
    //	[self stopActivity];
    //	[self showVideoLoadingError];
    [self setBtnEnableStatus:YES];
}

#pragma mark VMediaPlayerDelegate Implement / Optional

- (void)mediaPlayer:(VMediaPlayer *)player setupManagerPreference:(id)arg
{
    player.decodingSchemeHint = VMDecodingSchemeSoftware;
    player.autoSwitchDecodingScheme = NO;
}

- (void)mediaPlayer:(VMediaPlayer *)player setupPlayerPreference:(id)arg
{
    // Set buffer size, default is 1024KB(1*1024*1024).
    //	[player setBufferSize:256*1024];
    [player setBufferSize:1*1];
    //	[player setAdaptiveStream:YES];
    
    [player setVideoQuality:VMVideoQualityMedium];
    
    player.useCache = YES;
    [player setCacheDirectory:[self getCacheRootDirectory]];
}

- (void)mediaPlayer:(VMediaPlayer *)player seekComplete:(id)arg
{
}

- (void)mediaPlayer:(VMediaPlayer *)player notSeekable:(id)arg
{
    self.progressDragging = NO;
    NSLog(@"NAL 1HBT &&&&&&&&&&&&&&&&.......&&&&&&&&&&&&&&&&&");
}

- (void)mediaPlayer:(VMediaPlayer *)player bufferingStart:(id)arg
{
    self.progressDragging = YES;
    NSLog(@"NAL 2HBT &&&&&&&&&&&&&&&&.......&&&&&&&&&&&&&&&&&");
    if (![Utilities isLocalMedia:self.videoURL]) {
        [player pause];
        [self.startPause setTitle:@"继续" forState:UIControlStateNormal];
        [self startActivityWithMsg:@"Buffering... 0%"];
    }
}

- (void)mediaPlayer:(VMediaPlayer *)player bufferingUpdate:(id)arg
{
    if (!self.bubbleMsgLbl.hidden) {
        self.bubbleMsgLbl.text = [NSString stringWithFormat:@"Buffering... %d%%",
                                  [((NSNumber *)arg) intValue]];
    }
}

- (void)mediaPlayer:(VMediaPlayer *)player bufferingEnd:(id)arg
{
    if (![Utilities isLocalMedia:self.videoURL]) {
        [player start];
        [self.startPause setTitle:@"暂停" forState:UIControlStateNormal];
        [self stopActivity];
    }
    self.progressDragging = NO;
    NSLog(@"NAL 3HBT &&&&&&&&&&&&&&&&.......&&&&&&&&&&&&&&&&&");
}

- (void)mediaPlayer:(VMediaPlayer *)player downloadRate:(id)arg
{
    if (![Utilities isLocalMedia:self.videoURL]) {
        self.downloadRate.text = [NSString stringWithFormat:@"%dKB/s", [arg intValue]];
    } else {
        self.downloadRate.text = nil;
    }
}

- (void)mediaPlayer:(VMediaPlayer *)player videoTrackLagging:(id)arg
{
    //	NSLog(@"NAL 1BGR video lagging....");
}

#pragma mark VMediaPlayerDelegate Implement / Cache

- (void)mediaPlayer:(VMediaPlayer *)player cacheNotAvailable:(id)arg
{
    NSLog(@"NAL .... media can't cache.");
    self.progressSld.segments = nil;
}

- (void)mediaPlayer:(VMediaPlayer *)player cacheStart:(id)arg
{
    NSLog(@"NAL 1GFC .... media caches index : %@", arg);
}

- (void)mediaPlayer:(VMediaPlayer *)player cacheUpdate:(id)arg
{
    NSArray *segs = (NSArray *)arg;
    //	NSLog(@"NAL .... media cacheUpdate, %d, %@", segs.count, segs);
    if (mDuration > 0) {
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:0];
        for (int i = 0; i < segs.count; i++) {
            float val = (float)[segs[i] longLongValue] / mDuration;
            [arr addObject:[NSNumber numberWithFloat:val]];
        }
        self.progressSld.segments = arr;
    }
}

- (void)mediaPlayer:(VMediaPlayer *)player cacheSpeed:(id)arg
{
    //	NSLog(@"NAL .... media cacheSpeed: %dKB/s", [(NSNumber *)arg intValue]);
}

- (void)mediaPlayer:(VMediaPlayer *)player cacheComplete:(id)arg
{
    NSLog(@"NAL .... media cacheComplete");
    self.progressSld.segments = @[@(0.0), @(1.0)];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}
#pragma mark - Convention Methods

#define TEST_Common					1
#define TEST_setOptionsWithKeys		0
#define TEST_setDataSegmentsSource	0

-(void)quicklyPlayMovie:(NSURL*)fileURL title:(NSString*)title seekToPos:(long)pos
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    //	[self setBtnEnableStatus:NO];
    
    NSString *docDir = [NSString stringWithFormat:@"%@/Documents", NSHomeDirectory()];
    NSLog(@"NAL &&& Doc: %@", docDir);
    
    
    //	fileURL = [NSURL URLWithString:@"http://v.17173.com/api/5981245-4.m3u8"];
    
    
    
#if TEST_Common // Test Common
    NSString *abs = [fileURL absoluteString];
    if ([abs rangeOfString:@"://"].length == 0) {
        NSString *docDir = [NSString stringWithFormat:@"%@/Documents", NSHomeDirectory()];
        NSString *videoUrl = [NSString stringWithFormat:@"%@/%@", docDir, abs];
        self.videoURL = [NSURL fileURLWithPath:videoUrl];
    } else {
        self.videoURL = fileURL;
    }
    //    [mMPayer setDataSource:self.videoURL header:nil];
    [mMPayer setDataSource:self.videoURL];
#elif TEST_setOptionsWithKeys // Test setOptionsWithKeys:withValues:
    self.videoURL = [NSURL URLWithString:@"rtmp://videodownls.9xiu.com/9xiu/552"]; // This is a live stream.
    NSMutableArray *keys = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *vals = [NSMutableArray arrayWithCapacity:0];
    keys[0] = @"-rtmp_live";
    vals[0] = @"-1";
    [mMPayer setDataSource:self.videoURL header:nil];
    [mMPayer setOptionsWithKeys:keys withValues:vals];
#elif TEST_setDataSegmentsSource // Test setDataSegmentsSource:fileList:
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:0];
    [list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.1.mp4?vkey=E3D97333E93EDF36E56CB85CE0B02018E1001BA5C023DFFD298C0204CD81610CFCE546C79DE6C3E2"];
    [list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.2.mp4?vkey=5E82F44940C19CCF26610E7E4088438E868AB2CAB5255E5FDE6763484B9B7E967EF9A97D7E54A324"];
    
    [mMPayer setDataSegmentsSource:nil fileList:list];
#endif
    
    [mMPayer prepareAsync];
    [self startActivityWithMsg:@"Loading..."];
}

-(void)quicklyReplayMovie:(NSURL*)fileURL title:(NSString*)title seekToPos:(long)pos
{
    [self quicklyStopMovie];
    [self quicklyPlayMovie:fileURL title:title seekToPos:pos];
}

-(void)quicklyStopMovie
{
    [mMPayer reset];
    [mSyncSeekTimer invalidate];
    mSyncSeekTimer = nil;
    
    self.progressSld.value = 0.0;
    self.progressSld.segments = nil;
    self.curPosLbl.text = @"00:00:00";
    self.durationLbl.text = @"00:00:00";
    self.downloadRate.text = nil;
    mDuration = 0;
    mCurPostion = 0;
    [self stopActivity];
    [self setBtnEnableStatus:YES];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}


#pragma mark - UI Actions

#define DELEGATE_IS_READY(x) (self.delegate && [self.delegate respondsToSelector:@selector(x)])

-(IBAction)goBackButtonAction:(id)sender
{
    AudioServicesPlaySystemSound(SOUND_ID);
    [self quicklyStopMovie];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)startPauseButtonAction:(id)sender
{
    BOOL isPlaying = [mMPayer isPlaying];
    if (isPlaying) {
        [mMPayer pause];
        [self.startPause setTitle:@"继续" forState:UIControlStateNormal];
    } else {
        [mMPayer start];
        [self.startPause setTitle:@"暂停" forState:UIControlStateNormal];
    }
}

-(void)currButtonAction:(id)sender
{
    NSURL *url = nil;
    NSString *title = nil;
    long lastPos = 0;
    if (DELEGATE_IS_READY(playCtrlGetPrevMediaTitle:lastPlayPos:)) {
        url = [self.delegate playCtrlGetCurrMediaTitle:&title lastPlayPos:&lastPos];
    }
    if (url) {
        [self quicklyPlayMovie:url title:title seekToPos:lastPos];
    } else {
        NSLog(@"WARN: No previous media url found!");
    }
}




-(IBAction)progressSliderDownAction:(id)sender
{
    self.progressDragging = YES;
    NSLog(@"NAL 4HBT &&&&&&&&&&&&&&&&.......&&&&&&&&&&&&&&&&&");
    NSLog(@"NAL 1DOW &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& Touch Down");
}

-(IBAction)progressSliderUpAction:(id)sender
{
    UISlider *sld = (UISlider *)sender;
    NSLog(@"NAL 1BVC &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& seek = %ld", (long)(sld.value * mDuration));
    [self startActivityWithMsg:@"Buffering"];
    [mMPayer seekTo:(long)(sld.value * mDuration)];
}

-(IBAction)dragProgressSliderAction:(id)sender
{
    UISlider *sld = (UISlider *)sender;
    self.curPosLbl.text = [Utilities timeToHumanString:(long)(sld.value * mDuration)];
}

-(void)progressSliderTapped:(UIGestureRecognizer *)g
{
    UISlider* s = (UISlider*)g.view;
    if (s.highlighted)
        return;
    CGPoint pt = [g locationInView:s];
    CGFloat percentage = pt.x / s.bounds.size.width;
    CGFloat delta = percentage * (s.maximumValue - s.minimumValue);
    CGFloat value = s.minimumValue + delta;
    [s setValue:value animated:YES];
    long seek = percentage * mDuration;
    self.curPosLbl.text = [Utilities timeToHumanString:seek];
    NSLog(@"NAL 2BVC &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& seek = %ld", seek);
    [self startActivityWithMsg:@"Buffering"];
    [mMPayer seekTo:seek];
}


#pragma mark - Sync UI Status

-(void)syncUIStatus
{
    if (!self.progressDragging) {
        mCurPostion  = [mMPayer getCurrentPosition];
        [self.progressSld setValue:(float)mCurPostion/mDuration];
        self.curPosLbl.text = [Utilities timeToHumanString:mCurPostion];
        self.durationLbl.text = [Utilities timeToHumanString:mDuration];
    }
}


#pragma mark Others

-(void)startActivityWithMsg:(NSString *)msg
{
    self.bubbleMsgLbl.hidden = NO;
    self.bubbleMsgLbl.text = msg;
    [self.activityView startAnimating];
    self.tipLabel.hidden = NO;
    justTimer =[NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(judgeTimerCount) userInfo:nil repeats:NO];
}

- (void)judgeTimerCount
{
    if (self.activityView.isAnimating || _happenedError) {
        UIAlertView * tipAlertView = [[UIAlertView alloc]initWithTitle:@"抱歉" message:@"视频数据获取失败" delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
        [tipAlertView show];
        self.tipLabel.hidden = YES;
        [self performSelector:@selector(goBackAlert:) withObject:tipAlertView afterDelay:2.0];
    }
}

- (void)goBackAlert:(id)obj
{
    UIAlertView * tmpAlert = obj;
    _happenedError = NO;
    [self quicklyStopMovie];
    [tmpAlert dismissWithClickedButtonIndex:0 animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)stopActivity
{
    self.bubbleMsgLbl.hidden = YES;
    self.bubbleMsgLbl.text = nil;
    self.tipLabel.hidden = YES;
    [self.activityView stopAnimating];
}

-(void)setBtnEnableStatus:(BOOL)enable
{
    self.startPause.enabled = enable;
}

- (void)setupObservers
{
    NSNotificationCenter *def = [NSNotificationCenter defaultCenter];
    [def addObserver:self
            selector:@selector(applicationDidEnterForeground:)
                name:UIApplicationDidBecomeActiveNotification
              object:[UIApplication sharedApplication]];
    [def addObserver:self
            selector:@selector(applicationDidEnterBackground:)
                name:UIApplicationWillResignActiveNotification
              object:[UIApplication sharedApplication]];
}

- (void)unSetupObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)showVideoLoadingError
{
    NSString *sError = NSLocalizedString(@"Video cannot be played", @"description");
    NSString *sReason = NSLocalizedString(@"Video cannot be loaded.", @"reason");
    NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               sError, NSLocalizedDescriptionKey,
                               sReason, NSLocalizedFailureReasonErrorKey,
                               nil];
    NSError *error = [NSError errorWithDomain:@"Vitamio" code:0 userInfo:errorDict];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

- (NSString *)getCacheRootDirectory
{
    NSString *cache = [NSString stringWithFormat:@"%@/Library/Caches/MediasCaches", NSHomeDirectory()];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cache]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cache
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    return cache;
}

@end