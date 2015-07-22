//
//  CHTVProgramVersionManager.m
//  TVhelper
//
//  Created by Jack Wang on 15/7/20.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHTVProgramVersionManager.h"
#import "CHTVProgramManager.h"
#define programVersionURL @"http://%@:8000/epg_database_ver.json"

@interface CHTVProgramVersionManager ()<NSURLConnectionDataDelegate, NSURLConnectionDelegate>
@property (strong, nonatomic) NSMutableData *reciveData;
@property (strong, nonatomic) NSString *selectedIp;
@end

@implementation CHTVProgramVersionManager

#pragma 获取节目版本信息
- (void) obtainProgramVersionInfo:(NSString *)selectedIP
{
    _selectedIp = selectedIP;
    NSString *newProgramVersionURL = [NSString stringWithFormat:programVersionURL, selectedIP];
    NSLog(@"program version request URL %@", newProgramVersionURL);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:newProgramVersionURL]];
    request.HTTPMethod = @"GET";
    [NSURLConnection connectionWithRequest:request delegate:self];

}

#pragma 获取版本信息的HTTP REQUEST
//1.2       开始接受数据
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    
    NSLog(@"%@",[res allHeaderFields]);
    
    self.reciveData = [NSMutableData data];
}

//1.3       接收到数据(每接收到一次数据会调用,不代表数据接收完了,所以不断接收)
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.reciveData appendData:data];
}

//1.4       完成读取
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //解析JSON版本信息
    NSError * error = nil;
    NSDictionary *verDict = [NSJSONSerialization JSONObjectWithData:_reciveData options:NSJSONReadingAllowFragments error:&error];
    NSLog(@"版本信息为:%@", verDict);
    
    if (verDict == nil || error) {
        NSLog(@"解析失败%@", error.localizedDescription);
    } else {
        //获得版本信息
        NSArray *versionKeys = [verDict objectForKey:@"EPG_DATABASE"];
        NSDictionary *versionInfo = [versionKeys firstObject];
        NSString *serverVersion = [versionInfo objectForKey:@"epg_db_version"];
        
        NSLog(@"version for server data is %@", serverVersion);
        
        //对比版本信息
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *mobileVersion = [defaults objectForKey:@"epg_db_version"];
        BOOL needUpdate = NO;
        
        if(mobileVersion != nil) {
            needUpdate= YES;
        }
        
        NSComparisonResult compareResult = [serverVersion compare:mobileVersion];
        if(compareResult == NSOrderedDescending || compareResult == NSOrderedSame) {
            needUpdate = YES;
        } else if (compareResult == NSOrderedAscending) {
            //盒子版本小于手机版本,不做处理
        }
        
        //如果需要更新，就直接更新
        if(needUpdate) {
            //盒子版本大于手机版本
            CHTVProgramManager *prgramManager = [[CHTVProgramManager alloc] init];
            [prgramManager obtainProgramInfo:_selectedIp withServerVersion:serverVersion];
            
            NSLog(@"server version is %@ and mobile version is %@, need update epg info", serverVersion, mobileVersion);
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


@end
