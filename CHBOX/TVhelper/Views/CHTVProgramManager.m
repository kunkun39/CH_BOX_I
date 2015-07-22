//
//  CHTVProgramManager.m
//  TVhelper
//
//  Created by Jack Wang on 15/7/16.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHTVProgramManager.h"
#import "CHBaseDetailViewController.h"
#import "CHProgram.h"
#import "sqlite3.h"

#define programURL @"http://%@:8000/epg_database.db"

static NSString *epg_databasePath = nil;
static NSString *ppg_database = nil;

@interface CHTVProgramManager ()<NSURLConnectionDataDelegate, NSURLConnectionDelegate>
@property (strong, nonatomic) NSMutableData *reciveData;
@property (strong, nonatomic) NSString *serverVersion;
@end

@implementation CHTVProgramManager

#pragma mark - search program info
//1.1       创建URL开始发送HTTP请求
- (void)obtainProgramInfo:(NSString *)selectedIP withServerVersion:(NSString *)serverVersion
{
    _serverVersion = serverVersion;
    
    NSString *newProgramURL = [NSString stringWithFormat:programURL, selectedIP];
    NSLog(@"program request URL %@", newProgramURL);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:newProgramURL]];
    request.HTTPMethod = @"GET";
    [NSURLConnection connectionWithRequest:request delegate:self];
}

//1.2       开始接受数据
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    
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
    //直接DOWNLOAD数据库并保存
    [_reciveData writeToFile:[self obtainEPGDatabasePath] atomically:NO];
    NSLog(@"successful save epg database to local sandbox");
    
    //保存当前的版本信息
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:_serverVersion forKey:@"epg_db_version"];
    
    
    //清空临时保存的文件
    [_reciveData resetBytesInRange:NSMakeRange(0, [_reciveData length])];
    [_reciveData setLength:0];
}

//1.5       连接失败
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%s", __FUNCTION__);
}

#pragma ****************************节目信息数据库操作****************************

+ (NSDictionary *) obtainAllChannelCurrentProgramInfo
{
    NSMutableDictionary *currentPrograms = [[NSMutableDictionary alloc] init];
    sqlite3 *db = nil;
    
    if (sqlite3_open([epg_databasePath UTF8String], &db) != SQLITE_OK) {
        sqlite3_close(db);
        NSLog(@"数据库打开失败");
    } else {
        //查询所有的当前节目
        NSLog(@"开始执行获得所有频道的当前节目信息");
        NSString *sqlQuery = @"SELECT i_ChannelIndex, str_ChannelName, str_eventName, str_startTime, str_endTime FROM epg_information WHERE str_startTime < ? AND str_endTime >= ?";
        sqlite3_stmt *statement;
        
        //获取当前时间
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setLocale:[NSLocale currentLocale]];
        [outputFormatter setDateFormat:@"HH:mm"];
        NSString *currentTime = [outputFormatter stringFromDate:[NSDate date]];
        NSLog(@"system current time:%@", currentTime);
        
        //开始获取数据
        if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
            
            sqlite3_bind_text(statement, 1, [currentTime UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [currentTime UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSString *channelName = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 1)];
                NSString *eventName = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 2)];
                NSString *startTime = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 3)];
                NSString *endTime = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 4)];
                
                CHProgram *program = [CHProgram programWithChannel:channelName andEventName:eventName andEventStart:startTime andEventEnd:endTime];
                [currentPrograms setObject:program forKey:channelName];
                NSLog(@"current for %@ - %@ - %@ - %@", channelName, eventName, startTime, endTime);
            }
            
            sqlite3_finalize(statement);
        }
        
        sqlite3_close(db);
    }
    
    return currentPrograms;
}

+ (NSArray *) obtainAllProgramInfoForOneChannel:(NSString *)channelName
{
    NSMutableArray *allPrograms = [[NSMutableArray alloc] init];
    sqlite3 *db = nil;
    
    if (sqlite3_open([epg_databasePath UTF8String], &db) != SQLITE_OK) {
        sqlite3_close(db);
        NSLog(@"数据库打开失败");
    } else {
        //查询所有的当前节目
        NSLog(@"开始执行获得所有频道的当前节目信息");
        NSString *sqlQuery = @"SELECT i_ChannelIndex, str_ChannelName, str_eventName, str_startTime, str_endTime, i_weekIndex FROM epg_information WHERE str_ChannelName = ? ORDER BY str_startTime ASC";
        sqlite3_stmt *statement;
        
        //获取当前时间
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setLocale:[NSLocale currentLocale]];
        [outputFormatter setDateFormat:@"HH:mm"];
        NSString *currentTime = [outputFormatter stringFromDate:[NSDate date]];
        NSLog(@"system current time:%@", currentTime);
        
        //开始获取数据
        if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
            
            sqlite3_bind_text(statement, 1, [channelName UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSString *channelName = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 1)];
                NSString *eventName = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 2)];
                NSString *startTime = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 3)];
                NSString *endTime = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 4)];
                NSString *weekIndex = [[NSString alloc]initWithUTF8String:(char*)sqlite3_column_text(statement, 5)];
                
                CHProgram *program = [CHProgram programWithChannel:channelName andEventName:eventName andEventStart:startTime andEventEnd:endTime andWeekIndex:weekIndex];
                
                [allPrograms addObject:program];
                NSLog(@"details program for %@ - %@ - %@ - %@", channelName, eventName, startTime, endTime);
            }
            
            sqlite3_finalize(statement);
        }
        
        sqlite3_close(db);
    }
    
    return allPrograms;
}

+ (void) obtainCurrentProgramInfoByChannelName:(NSString *)channelName
{
    
}

#pragma ****************************EPG数据库相关的操作**************************
- (NSString *) obtainEPGDatabasePath {
    if(epg_databasePath != nil) {
        return epg_databasePath;
    }
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    
    //获得数据库名字
    epg_databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"epg_database.db"]];
    return epg_databasePath;
}

@end
