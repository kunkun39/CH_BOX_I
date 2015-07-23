
//  TVSocketManager.m
//  TVhelper
//
//  Created by shanshu on 15/4/27.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHTVSocketManager.h"
#import "CHTVProgramVersionManager.h"
#define PORT 9001
#define channelUrl @"http://%@:8000/DtvProgInfoJson.json"

static CHTVSocketManager * socketManager = nil;
@interface CHTVSocketManager ()<TVSocketDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate>
@property (assign, nonatomic) NSInteger currentTime;
@property (strong, nonatomic) NSMutableData * reciveData;

@property (strong, nonatomic) NSTimer *timerForProgram;
@end
@implementation CHTVSocketManager

+ (CHTVSocketManager *)shareTVSocketManager
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        socketManager = [[CHTVSocketManager alloc]init];
    });
    return socketManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self observeTVIP];
        
        //初始化TIMER线程，并每隔10分钟不停的去更新节目信息
        _timerForProgram = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(socketProgramVersionInfo) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]addTimer:_timerForProgram forMode:NSDefaultRunLoopMode];
        NSLog(@"open scheduler task for program info get");
    }
    return self;
}

- (void)observeTVIP
{
    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_CONCURRENT);
    self.socket = [[CHTVSocketDel alloc] createdelegateQueue:queue withDelegate:self];
    NSError *error = nil;
    if (![self.socket datagramSocket:PORT error:&error])
    {
        return;
    }
    if (![    self.socket beginReceiving:&error])
    {
        return;
    }
    NSThread * ticketsThreadone = [[NSThread alloc] initWithTarget:self selector:@selector(judgeConnect:) object:nil];
    [ticketsThreadone setName:@"judgeConnectThread"];
    [ticketsThreadone start];
}
/**
 *  判断是否连接超时
 */
- (void)judgeConnect:(NSThread *)thread
{
    while (true) {
        if ([[NSDate date] timeIntervalSince1970] - _currentTime >=4) {
            [self clearSelectedIP];
        }
        [NSThread sleepForTimeInterval:3];
    }
}
- (void)clearPlist
{
    NSArray * nilAry = [NSArray array];
    NSString *filename=[NSTemporaryDirectory() stringByAppendingPathComponent:@"channel.plist"];
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm createFileAtPath:filename contents:nil attributes:nil];
    [nilAry writeToFile:filename atomically:YES];
}

- (void)clearSelectedIP
{
    if (self.selectedIP != nil) {
        [[self mutableArrayValueForKey:@"IPlistAry"] removeObject:self.selectedIP];
        self.selectedIP = nil;
    }
    [self clearPlist];
}
/**
 *  接收数据
 *
 */
- (void)TVSocket:(CHTVSocketDel *)sock hadReceivedData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    
    NSString *host = nil;
    uint16_t port = 0;
    
    [CHTVSocketDel analysisHost:&host port:&port withAddress:address];
    //    NSLog(@"%@   %@", host, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    if ([host containsString:@"::ffff:"]) {
        host = [host substringFromIndex:7];
    }
    @synchronized(self){
        if (![self.IPlistAry containsObject:host] && host != nil && ![host containsString:@"err"]) {
            [[self mutableArrayValueForKey:@"IPlistAry"] addObject:host];
        }
    }
    if (self.IPlistAry.count > 0 && self.selectedIP == nil) {
        self.selectedIP = self.IPlistAry[0];
    }
    if ([self.selectedIP isEqualToString: host]) {
        _currentTime = [[NSDate date] timeIntervalSince1970];
    }
    //    NSLog(@"%@  %@", host, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
}


- (void)TVSocket:(CHTVSocketDel *)sock hadNotSentDataWithTag:(long)tag dueToError:(NSError *)error
{
    // You could add checks here
    NSLog(@"didNotsent");
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    if (!socketManager) {
        socketManager = [super allocWithZone:zone];
    }
    return socketManager;
}
- (id)copy
{
    return self;
}

- (NSMutableArray *)IPlistAry
{
    if (!_IPlistAry) {
        _IPlistAry = [[NSMutableArray alloc]init];
    }
    return _IPlistAry;
}

- (NSMutableData *)reciveData
{
    if (!_reciveData) {
        _reciveData = [[NSMutableData alloc]init];
    }
    return _reciveData;
}

#pragma mark - channelInfo
- (void)socketChannelInfo
{
    NSMutableURLRequest *  request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: channelUrl, self.selectedIP]]];
    request.HTTPMethod = @"GET";
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"MIMEType: %@", response.MIMEType);
}
//1.3       接收到数据(每接收到一次数据会调用,不代表数据接收完了,所以不断接收)
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.reciveData appendData:data];
}
//1.4       完成读取
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError * error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:_reciveData options:NSJSONReadingMutableLeaves error:&error];
    if (error) {
        NSLog(@"解析失败%@",error.localizedDescription);
    }else{
        if ([[object objectForKey:@"JSON_PROGINFO"] isKindOfClass:[NSArray class]]) {
            NSArray * channel = [[NSArray alloc] initWithArray:[object objectForKey:@"JSON_PROGINFO"]];
            NSString *filename=[NSTemporaryDirectory() stringByAppendingPathComponent:@"channel.plist"];
            NSFileManager* fm = [NSFileManager defaultManager];
            [fm createFileAtPath:filename contents:nil attributes:nil];
            [channel writeToFile:filename atomically:YES];
            self.plistBack();
        }
    }
    [_reciveData resetBytesInRange:NSMakeRange(0, [_reciveData length])];
    [_reciveData setLength:0];
}

//1.5       连接失败
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%s", __FUNCTION__);
}

#pragma mart - obtain program version info
- (void)socketProgramVersionInfo
{
    CHTVProgramVersionManager *programVersionManager = [[CHTVProgramVersionManager alloc] init];
    [programVersionManager obtainProgramVersionInfo:self.selectedIP];
}


@end
