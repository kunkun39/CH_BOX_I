//
//  TVSocketManager.m
//  AsyncChatClient
//
//  Created by shanshu on 15/4/23.
//  Copyright (c) 2015年 crazyit.org. All rights reserved.
//

#import "CHTVSocketDel.h"
#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
// For more information see: https://github.com/robbiehanson/CocoaAsyncSocket/wiki/ARC
#endif

#if TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#import <UIKit/UIKit.h>
#endif

#import <arpa/inet.h>
#import <fcntl.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <net/if.h>
#import <sys/socket.h>
#import <sys/types.h>


#if 0

// Logging Enabled - See log level below

// Logging uses the CocoaLumberjack framework (which is also GCD based).
// http://code.google.com/p/cocoalumberjack/
//
// It allows us to do a lot of logging without significantly slowing down the code.
#import "DDLog.h"

#define LogAsync   NO
#define LogContext 65535

#define LogObjc(flg, frmt, ...) LOG_OBJC_MAYBE(LogAsync, logLevel, flg, LogContext, frmt, ##__VA_ARGS__)
#define LogC(flg, frmt, ...)    LOG_C_MAYBE(LogAsync, logLevel, flg, LogContext, frmt, ##__VA_ARGS__)

#define LogError(frmt, ...)     LogObjc(LOG_FLAG_ERROR,   (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogWarn(frmt, ...)      LogObjc(LOG_FLAG_WARN,    (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogInfo(frmt, ...)      LogObjc(LOG_FLAG_INFO,    (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogVerbose(frmt, ...)   LogObjc(LOG_FLAG_VERBOSE, (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)

#define LogCError(frmt, ...)    LogC(LOG_FLAG_ERROR,   (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogCWarn(frmt, ...)     LogC(LOG_FLAG_WARN,    (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogCInfo(frmt, ...)     LogC(LOG_FLAG_INFO,    (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogCVerbose(frmt, ...)  LogC(LOG_FLAG_VERBOSE, (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)

#define LogTrace()              LogObjc(LOG_FLAG_VERBOSE, @"%@: %@", THIS_FILE, THIS_METHOD)
#define LogCTrace()             LogC(LOG_FLAG_VERBOSE, @"%@: %s", THIS_FILE, __FUNCTION__)

// Log levels : off, error, warn, info, verbose
static const int logLevel = LOG_LEVEL_VERBOSE;

#else

// Logging Disabled

#define LogError(frmt, ...)     {}
#define LogWarn(frmt, ...)      {}
#define LogInfo(frmt, ...)      {}
#define LogVerbose(frmt, ...)   {}

#define LogCError(frmt, ...)    {}
#define LogCWarn(frmt, ...)     {}
#define LogCInfo(frmt, ...)     {}
#define LogCVerbose(frmt, ...)  {}

#define LogTrace()              {}
#define LogCTrace(frmt, ...)    {}

#endif


#define return_from_block  return


#define SOCKET_NULL -1

#define AutoreleasedBlock(block) ^{ @autoreleasepool { block(); }}

@class TVSendPacket;

NSString *const TVSocketException = @"TVSocketException";
NSString *const TVSocketErrorDomain = @"TVSocketErrorDomain";

NSString *const TVSocketQueueName = @"TVSocket";
NSString *const TVSocketThreadName = @"TVSocket-CFStream";

/**
 flags组
 */
enum TVSocketFlags
{
    kDidCreateSockets        = 1 <<  0,  // socket是否创建
    kDidBind                 = 1 <<  1,  // 是否绑定
    kConnecting              = 1 <<  2,  // 准备连接
    kDidConnect              = 1 <<  3,  // 已连接
    kReceiveOnce             = 1 <<  4,
    kReceiveContinuous       = 1 <<  5,  // 能够接受
    kIPv4Deactivated         = 1 <<  6,
    kIPv6Deactivated         = 1 <<  7,  // socket6被关闭
    kSend4SourceSuspended    = 1 <<  8,
    kSend6SourceSuspended    = 1 <<  9,
    kReceive4SourceSuspended = 1 << 10,
    kReceive6SourceSuspended = 1 << 11,
    kSock4CanAcceptBytes     = 1 << 12,  // socket4 能接受数据
    kSock6CanAcceptBytes     = 1 << 13,  // 见上
    kForbidSendReceive       = 1 << 14,
    kCloseAfterSends         = 1 << 15,
    kFlipFlop                = 1 << 16,
#if TARGET_OS_IPHONE
    kAddedStreamListener     = 1 << 17,  // CFStreams 是否被添加到监听队列
#endif
};

enum TVSocketConfig
{
    kIPv4Disabled  = 1 << 0,
    kIPv6Disabled  = 1 << 1,
    kPreferIPv4    = 1 << 2,
    kPreferIPv6    = 1 << 3,
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface CHTVSocketDel ()
{
#if __has_feature(objc_arc_weak)
    __weak id delegate;
#else
    __unsafe_unretained id delegate;
#endif
    dispatch_queue_t delegateQueue;
    
    TVSocketReceiveFilterBlock receiveFilterBlock;
    dispatch_queue_t receiveFilterQueue;
    BOOL receiveFilterAsync;
    
    TVSocketSendFilterBlock sendFilterBlock;
    dispatch_queue_t sendFilterQueue;
    BOOL sendFilterAsync;
    
    uint32_t flags;
    uint16_t config;
    
    uint16_t max4ReceiveSize;
    uint32_t max6ReceiveSize;
    
    int socket4FD;
    int socket6FD;
    
    dispatch_queue_t socketQueue;
    
    dispatch_source_t send4Source;
    dispatch_source_t send6Source;
    dispatch_source_t receive4Source;
    dispatch_source_t receive6Source;
    dispatch_source_t sendTimer;
    
    TVSendPacket *currentSend;
    NSMutableArray *sendQueue;
    
    unsigned long socket4FDBytesAvailable;
    unsigned long socket6FDBytesAvailable;
    
    uint32_t pendingFilterOperations;
    
    NSData   *cachedLocalAddress4;
    NSString *cachedLocalHost4;
    uint16_t  cachedLocalPort4;
    
    NSData   *cachedLocalAddress6;
    NSString *cachedLocalHost6;
    uint16_t  cachedLocalPort6;
    
    NSData   *cachedConnectedAddress;
    NSString *cachedConnectedHost;
    uint16_t  cachedConnectedPort;
    int       cachedConnectedFamily;
    
    void *IsOnSocketQueueOrTargetQueueKey;
    
#if TARGET_OS_IPHONE
    CFStreamClientContext streamContext;
    CFReadStreamRef readStream4;
    CFReadStreamRef readStream6;
    CFWriteStreamRef writeStream4;
    CFWriteStreamRef writeStream6;
#endif
    
    id userData;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface TVSendPacket : NSObject {
@public
    NSData *buffer;
    NSTimeInterval timeout;
    long tag;
    
    BOOL resolveInProgress;
    BOOL filterInProgress;
    
    NSArray *resolvedAddresses;
    NSError *resolveError;
    
    NSData *address;
    int addressFamily;
}

- (id)initWithData:(NSData *)d timeout:(NSTimeInterval)t tag:(long)i;

@end

@implementation TVSendPacket

- (id)initWithData:(NSData *)d timeout:(NSTimeInterval)t tag:(long)i
{
    if ((self = [super init]))
    {
        buffer = d;
        timeout = t;
        tag = i;
        
        resolveInProgress = NO;
    }
    return self;
}


@end


@interface TVSpecialPacket : NSObject {
@public
    //	uint8_t type;
    
    BOOL resolveInProgress;
    
    NSArray *addresses;
    NSError *error;
}

- (id)init;

@end

@implementation TVSpecialPacket

- (id)init
{
    self = [super init];
    return self;
}


@end


@implementation CHTVSocketDel

- (id)init
{
    LogTrace();
    
    return [self initToCreateSocketQueue:NULL andDelegateQueue:NULL withDelegate:nil];
}

- (id)createSocketQueue:(dispatch_queue_t)socketq
{
    LogTrace();
    return [self initToCreateSocketQueue:socketq andDelegateQueue:NULL withDelegate:nil];
}

- (id)createdelegateQueue:(dispatch_queue_t)delegateq withDelegate:(id)aDelegate
{
    LogTrace();
    return [self initToCreateSocketQueue:NULL andDelegateQueue:delegateq withDelegate:aDelegate];
}

- (id)initWithmy
{
    if (self = [super init]) {
        
    }
    return self;
}

- (id)initToCreateSocketQueue:(dispatch_queue_t)socketq andDelegateQueue:(dispatch_queue_t)delegateq withDelegate:(id)aDelegate
{
    LogTrace();
    
    if ((self = [super init]))
    {
        delegate = aDelegate;
        
        if (delegateq)
        {
            delegateQueue = delegateq;
#if !OS_OBJECT_USE_OBJC
            dispatch_retain(delegateQueue);
#endif
        }
        
        max4ReceiveSize = 9216;
        max6ReceiveSize = 9216;
        
        socket4FD = SOCKET_NULL;
        socket6FD = SOCKET_NULL;
        
        if (socketq)
        {
            NSAssert(socketq != dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                     @"The given socketQueue parameter must not be a concurrent queue.");
            NSAssert(socketq != dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
                     @"The given socketQueue parameter must not be a concurrent queue.");
            NSAssert(socketq != dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                     @"The given socketQueue parameter must not be a concurrent queue.");
            
            socketQueue = socketq;
#if !OS_OBJECT_USE_OBJC
            dispatch_retain(socketQueue);
#endif
        }
        else
        {
            socketQueue = dispatch_queue_create([TVSocketQueueName UTF8String], NULL);
        }
        
        IsOnSocketQueueOrTargetQueueKey = &IsOnSocketQueueOrTargetQueueKey;
        
        void *nonNullUnusedPointer = (__bridge void *)self;
        dispatch_queue_set_specific(socketQueue, IsOnSocketQueueOrTargetQueueKey, nonNullUnusedPointer, NULL);
        
        currentSend = nil;
        sendQueue = [[NSMutableArray alloc] initWithCapacity:5];
        
#if TARGET_OS_IPHONE
        //        [[NSNotificationCenter defaultCenter] addObserver:self
        //                                                 selector:@selector(applicationWillEnterForeground:)
        //                                                     name:UIApplicationWillEnterForegroundNotification
        //                                                   object:nil];
#endif
    }
    return self;
}

- (void)dealloc
{
    LogInfo(@"%@ - %@ (start)", THIS_METHOD, self);
    
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
    
    if (dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey))
    {
                [self closeWithError:nil];
    }
    else
    {
        dispatch_sync(socketQueue, ^{
                        [self closeWithError:nil];
        });
    }
    
    delegate = nil;
#if !OS_OBJECT_USE_OBJC
    if (delegateQueue) dispatch_release(delegateQueue);
#endif
    delegateQueue = NULL;
    
#if !OS_OBJECT_USE_OBJC
    if (socketQueue) dispatch_release(socketQueue);
#endif
    socketQueue = NULL;
    
    LogInfo(@"%@ - %@ (finish)", THIS_METHOD, self);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Binding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method runs through the various checks required prior to a bind attempt.
 * It is shared between the various bind methods.
 **/

- (BOOL)preOp:(NSError **)errPtr
{
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    
    if (delegate == nil) // Must have delegate set
    {
      
        return NO;
    }
    
    if (delegateQueue == NULL) // Must have delegate queue set
    {
 
        return NO;
    }
    
    return YES;
}


- (BOOL)preBind:(NSError **)errPtr
{
    if (![self preOp:errPtr])
    {
        return NO;
    }
    
    if (flags & kDidBind)
    {

        return NO;
    }
    
    if ((flags & kConnecting) || (flags & kDidConnect))
    {
        return NO;
    }
    
    BOOL isIPv4Disabled = (config & kIPv4Disabled) ? YES : NO;
    BOOL isIPv6Disabled = (config & kIPv6Disabled) ? YES : NO;
    
    if (isIPv4Disabled && isIPv6Disabled) // Must have IPv4 or IPv6 enabled
    {

        return NO;
    }
    
    return YES;
}


- (void)analyseDescription:(NSString *)Description
                  datagram:(uint16_t)datagram
               intoIPAddr4:(NSData **)addr4Ptr
                   IPaddr6:(NSData **)addr6Ptr
{
    NSData *addr4 = nil;
    NSData *addr6 = nil;
    
    if (Description == nil)
    {
        // ANY address
        
        struct sockaddr_in sockaddr4;
        memset(&sockaddr4, 0, sizeof(sockaddr4));
        
        sockaddr4.sin_len         = sizeof(sockaddr4);
        sockaddr4.sin_family      = AF_INET;
        sockaddr4.sin_port        = htons(datagram);
        sockaddr4.sin_addr.s_addr = htonl(INADDR_ANY);
        
        struct sockaddr_in6 sockaddr6;
        memset(&sockaddr6, 0, sizeof(sockaddr6));
        
        sockaddr6.sin6_len       = sizeof(sockaddr6);
        sockaddr6.sin6_family    = AF_INET6;
        sockaddr6.sin6_port      = htons(datagram);
        sockaddr6.sin6_addr      = in6addr_any;
        
        addr4 = [NSData dataWithBytes:&sockaddr4 length:sizeof(sockaddr4)];
        addr6 = [NSData dataWithBytes:&sockaddr6 length:sizeof(sockaddr6)];
    }
    else if ([Description isEqualToString:@"localhost"] ||
             [Description isEqualToString:@"loopback"])
    {
        // LOOPBACK address
        
        struct sockaddr_in sockaddr4;
        memset(&sockaddr4, 0, sizeof(sockaddr4));
        
        sockaddr4.sin_len         = sizeof(struct sockaddr_in);
        sockaddr4.sin_family      = AF_INET;
        sockaddr4.sin_port        = htons(datagram);
        sockaddr4.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        
        struct sockaddr_in6 sockaddr6;
        memset(&sockaddr6, 0, sizeof(sockaddr6));
        
        sockaddr6.sin6_len       = sizeof(struct sockaddr_in6);
        sockaddr6.sin6_family    = AF_INET6;
        sockaddr6.sin6_port      = htons(datagram);
        sockaddr6.sin6_addr      = in6addr_loopback;
        
        addr4 = [NSData dataWithBytes:&sockaddr4 length:sizeof(sockaddr4)];
        addr6 = [NSData dataWithBytes:&sockaddr6 length:sizeof(sockaddr6)];
    }
    else
    {
        const char *iface = [Description UTF8String];
        
        struct ifaddrs *addrs;
        const struct ifaddrs *cursor;
        
        if ((getifaddrs(&addrs) == 0))
        {
            cursor = addrs;
            while (cursor != NULL)
            {
                if ((addr4 == nil) && (cursor->ifa_addr->sa_family == AF_INET))
                {
                    // IPv4
                    
                    struct sockaddr_in *addr = (struct sockaddr_in *)cursor->ifa_addr;
                    
                    if (strcmp(cursor->ifa_name, iface) == 0)
                    {
                        
                        struct sockaddr_in nativeAddr4 = *addr;
                        nativeAddr4.sin_port = htons(datagram);
                        
                        addr4 = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
                    }
                    else
                    {
                        char ip[INET_ADDRSTRLEN];
                        
                        const char *conversion;
                        conversion = inet_ntop(AF_INET, &addr->sin_addr, ip, sizeof(ip));
                        
                        if ((conversion != NULL) && (strcmp(ip, iface) == 0))
                        {
                            
                            struct sockaddr_in nativeAddr4 = *addr;
                            nativeAddr4.sin_port = htons(datagram);
                            
                            addr4 = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
                        }
                    }
                }
                else if ((addr6 == nil) && (cursor->ifa_addr->sa_family == AF_INET6))
                {
                    // IPv6
                    
                    struct sockaddr_in6 *addr = (struct sockaddr_in6 *)cursor->ifa_addr;
                    
                    if (strcmp(cursor->ifa_name, iface) == 0)
                    {
                        
                        struct sockaddr_in6 nativeAddr6 = *addr;
                        nativeAddr6.sin6_port = htons(datagram);
                        
                        addr6 = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
                    }
                    else
                    {
                        char ip[INET6_ADDRSTRLEN];
                        
                        const char *conversion;
                        conversion = inet_ntop(AF_INET6, &addr->sin6_addr, ip, sizeof(ip));
                        
                        if ((conversion != NULL) && (strcmp(ip, iface) == 0))
                        {
                            
                            struct sockaddr_in6 nativeAddr6 = *addr;
                            nativeAddr6.sin6_port = htons(datagram);
                            
                            addr6 = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
                        }
                    }
                }
                
                cursor = cursor->ifa_next;
            }
            
            freeifaddrs(addrs);
        }
    }
    
    if (addr4Ptr) *addr4Ptr = addr4;
    if (addr6Ptr) *addr6Ptr = addr6;
}

-(BOOL)datagramSocket:(uint16_t)datagram error:(NSError *__autoreleasing *)errPtr
{
    return [self datagramSocket:datagram description:nil error:errPtr];
}

- (BOOL)datagramSocket:(uint16_t)datagram description:(NSString *)description error:(NSError **)errPtr
{
    __block BOOL result = NO;
    __block NSError *err = nil;
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        if (![self preBind:&err])
        {
            return_from_block;
        }
        
        
        NSData *interface4 = nil;
        NSData *interface6 = nil;
        
        [self analyseDescription:description datagram:datagram intoIPAddr4:&interface4 IPaddr6:&interface6];
        
        if ((interface4 == nil) && (interface6 == nil))
        {

            return_from_block;
        }
        
        BOOL isIPv4Disabled = (config & kIPv4Disabled) ? YES : NO;
        BOOL isIPv6Disabled = (config & kIPv6Disabled) ? YES : NO;
        
        if (isIPv4Disabled && (interface6 == nil))
        {

            return_from_block;
        }
        
        if (isIPv6Disabled && (interface4 == nil))
        {

            return_from_block;
        }
        BOOL useIPv4 = !isIPv4Disabled && (interface4 != nil);
        BOOL useIPv6 = !isIPv6Disabled && (interface6 != nil);
    
        if ((flags & kDidCreateSockets) == 0)
        {
            if (![self createSocket4:useIPv4 socket6:useIPv6 error:&err])
            {
                return_from_block;
            }
        }
        LogVerbose(@"Binding socket to port(%hu) interface(%@)", port, interface);
        
        if (useIPv4)
        {
            int status = bind(socket4FD, (struct sockaddr *)[interface4 bytes], (socklen_t)[interface4 length]);
            if (status == -1)
            {
                
                return_from_block;
            }
        }
        
        if (useIPv6)
        {
            int status = bind(socket6FD, (struct sockaddr *)[interface6 bytes], (socklen_t)[interface6 length]);
            if (status == -1)
            {
                
                return_from_block;
            }
        }
        
        flags |= kDidBind;
        
        if (!useIPv4) flags |= kIPv4Deactivated;
        if (!useIPv6) flags |= kIPv6Deactivated;
        
        result = YES;
        
    }};
    
    if (dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey))
        block();
    else
        dispatch_sync(socketQueue, block);
    
    if (err)
        LogError(@"Error binding to port/interface: %@", err);
    
    if (errPtr)
        *errPtr = err;
    
    return result;
}


- (BOOL)isIPv4Enabled
{
    
    __block BOOL result = NO;
    
    dispatch_block_t block = ^{
        
        result = ((config & kIPv4Disabled) == 0);
    };
    
    if (dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey))
        block();
    else
        dispatch_sync(socketQueue, block);
    
    return result;
}

- (void)setIPv4Enabled:(BOOL)flag
{
    
    dispatch_block_t block = ^{
        
        LogVerbose(@"%@ %@", THIS_METHOD, (flag ? @"YES" : @"NO"));
        
        if (flag)
            config &= ~kIPv4Disabled;
        else
            config |= kIPv4Disabled;
    };
    
    if (dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey))
        block();
    else
        dispatch_async(socketQueue, block);
}

- (BOOL)isIPv6Enabled
{
    
    __block BOOL result = NO;
    
    dispatch_block_t block = ^{
        
        result = ((config & kIPv6Disabled) == 0);
    };
    
    if (dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey))
        block();
    else
        dispatch_sync(socketQueue, block);
    
    return result;
}

- (void)setIPv6Enabled:(BOOL)flag
{
    
    dispatch_block_t block = ^{
        
        LogVerbose(@"%@ %@", THIS_METHOD, (flag ? @"YES" : @"NO"));
        
        if (flag)
            config &= ~kIPv6Disabled;
        else
            config |= kIPv6Disabled;
    };
    
    if (dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey))
        block();
    else
        dispatch_async(socketQueue, block);
}

- (BOOL)createSocket4:(BOOL)useIPv4 socket6:(BOOL)useIPv6 error:(NSError **)errPtr
{
    LogTrace();
    
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    NSAssert(((flags & kDidCreateSockets) == 0), @"Sockets have already been created");
    
    int(^createSocket)(int) = ^int (int domain) {
        
        int socketFD = socket(domain, SOCK_DGRAM, 0);
        
        if (socketFD == SOCKET_NULL)
        {
                
                return SOCKET_NULL;
        }
        
        int status;
        
        // Set socket options
        
        status = fcntl(socketFD, F_SETFL, O_NONBLOCK);
        if (status == -1)
        {
            if (errPtr)
                
                close(socketFD);
            return SOCKET_NULL;
        }
        
        int reuseaddr = 1;
        status = setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, &reuseaddr, sizeof(reuseaddr));
        if (status == -1)
        {
            if (errPtr)
                
                close(socketFD);
            return SOCKET_NULL;
        }
        
        int nosigpipe = 1;
        status = setsockopt(socketFD, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, sizeof(nosigpipe));
        if (status == -1)
        {
            if (errPtr)
                
                close(socketFD);
            return SOCKET_NULL;
        }
        
        return socketFD;
    };
    
    
    if (useIPv4)
    {
        LogVerbose(@"Creating IPv4 socket");
        
        socket4FD = createSocket(AF_INET);
        if (socket4FD == SOCKET_NULL)
        {
            return NO;
        }
    }
    
    if (useIPv6)
    {
        LogVerbose(@"Creating IPv6 socket");
        
        socket6FD = createSocket(AF_INET6);
        if (socket6FD == SOCKET_NULL)
        {
            
            if (socket4FD != SOCKET_NULL)
            {
                close(socket4FD);
                socket4FD = SOCKET_NULL;
            }
            
            return NO;
        }
    }
    
    //
    if (useIPv4)
        [self setupSendAndReceiveSourcesForSocket4];
    if (useIPv6)
        [self setupSendAndReceiveSourcesForSocket6];
    
    flags |= kDidCreateSockets;
    return YES;
}
- (BOOL)createSockets:(NSError **)errPtr
{
    LogTrace();
    
    BOOL useIPv4 = [self isIPv4Enabled];
    BOOL useIPv6 = [self isIPv6Enabled];
    
    return [self createSocket4:useIPv4 socket6:useIPv6 error:errPtr];
}

- (void)setupSendAndReceiveSourcesForSocket4
{
    LogTrace();
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    
    send4Source = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, socket4FD, 0, socketQueue);
    receive4Source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, socket4FD, 0, socketQueue);
    
    // Setup event handlers
    
    dispatch_source_set_event_handler(send4Source, ^{ @autoreleasepool {
        
        LogVerbose(@"send4EventBlock");
        LogVerbose(@"dispatch_source_get_data(send4Source) = %lu", dispatch_source_get_data(send4Source));
        
        flags |= kSock4CanAcceptBytes;
        
        if (currentSend == nil)
        {
            LogVerbose(@"Nothing to send");
            [self suspendSend4Source];
        }
        else if (currentSend->resolveInProgress)
        {
            LogVerbose(@"currentSend - waiting for address resolve");
            [self suspendSend4Source];
        }
        else if (currentSend->filterInProgress)
        {
            LogVerbose(@"currentSend - waiting on sendFilter");
            [self suspendSend4Source];
        }
        else
        {
            [self doSend];
        }
        
    }});
    
    dispatch_source_set_event_handler(receive4Source, ^{ @autoreleasepool {
        
        LogVerbose(@"receive4EventBlock");
        
        socket4FDBytesAvailable = dispatch_source_get_data(receive4Source);
        LogVerbose(@"socket4FDBytesAvailable: %lu", socket4FDBytesAvailable);
        
        if (socket4FDBytesAvailable > 0)
            [self doReceive];
        else
            [self doReceiveEOF];
        
    }});
    
    __block int socketFDRefCount = 2;
    
    int theSocketFD = socket4FD;
    
#if !OS_OBJECT_USE_OBJC
    dispatch_source_t theSendSource = send4Source;
    dispatch_source_t theReceiveSource = receive4Source;
#endif
    
    dispatch_source_set_cancel_handler(send4Source, ^{
        
        LogVerbose(@"send4CancelBlock");
        
#if !OS_OBJECT_USE_OBJC
        LogVerbose(@"dispatch_release(send4Source)");
        dispatch_release(theSendSource);
#endif
        
        if (--socketFDRefCount == 0)
        {
            LogVerbose(@"close(socket4FD)");
            close(theSocketFD);
        }
    });
    
    dispatch_source_set_cancel_handler(receive4Source, ^{
        
        LogVerbose(@"receive4CancelBlock");
        
#if !OS_OBJECT_USE_OBJC
        LogVerbose(@"dispatch_release(receive4Source)");
        dispatch_release(theReceiveSource);
#endif
        
        if (--socketFDRefCount == 0)
        {
            LogVerbose(@"close(socket4FD)");
            close(theSocketFD);
        }
    });
    
    socket4FDBytesAvailable = 0;
    flags |= kSock4CanAcceptBytes;
    
    flags |= kSend4SourceSuspended;
    flags |= kReceive4SourceSuspended;
}


- (void)setupSendAndReceiveSourcesForSocket6
{
    LogTrace();
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    
    send6Source = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, socket6FD, 0, socketQueue);
    receive6Source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, socket6FD, 0, socketQueue);
    
    // Setup event handlers
    
    dispatch_source_set_event_handler(send6Source, ^{ @autoreleasepool {
        
        LogVerbose(@"send6EventBlock");
        LogVerbose(@"dispatch_source_get_data(send6Source) = %lu", dispatch_source_get_data(send6Source));
        
        flags |= kSock6CanAcceptBytes;
        
        if (currentSend == nil)
        {
            LogVerbose(@"Nothing to send");
            [self suspendSend6Source];
        }
        else if (currentSend->resolveInProgress)
        {
            LogVerbose(@"currentSend - waiting for address resolve");
            [self suspendSend6Source];
        }
        else if (currentSend->filterInProgress)
        {
            LogVerbose(@"currentSend - waiting on sendFilter");
            [self suspendSend6Source];
        }
        else
        {
            [self doSend];
        }
        
    }});
    
    dispatch_source_set_event_handler(receive6Source, ^{ @autoreleasepool {
        
        LogVerbose(@"receive6EventBlock");
        
        socket6FDBytesAvailable = dispatch_source_get_data(receive6Source);
        LogVerbose(@"socket6FDBytesAvailable: %lu", socket6FDBytesAvailable);
        
        if (socket6FDBytesAvailable > 0)
            [self doReceive];
        else
            [self doReceiveEOF];
        
    }});
    
    __block int socketFDRefCount = 2;
    
    int theSocketFD = socket6FD;
    
#if !OS_OBJECT_USE_OBJC
    dispatch_source_t theSendSource = send6Source;
    dispatch_source_t theReceiveSource = receive6Source;
#endif
    
    dispatch_source_set_cancel_handler(send6Source, ^{
        
        LogVerbose(@"send6CancelBlock");
        
#if !OS_OBJECT_USE_OBJC
        LogVerbose(@"dispatch_release(send6Source)");
        dispatch_release(theSendSource);
#endif
        
        if (--socketFDRefCount == 0)
        {
            LogVerbose(@"close(socket6FD)");
            close(theSocketFD);
        }
    });
    
    dispatch_source_set_cancel_handler(receive6Source, ^{
        
        LogVerbose(@"receive6CancelBlock");
        
#if !OS_OBJECT_USE_OBJC
        LogVerbose(@"dispatch_release(receive6Source)");
        dispatch_release(theReceiveSource);
#endif
        
        if (--socketFDRefCount == 0)
        {
            LogVerbose(@"close(socket6FD)");
            close(theSocketFD);
        }
    });
    
    socket6FDBytesAvailable = 0;
    flags |= kSock6CanAcceptBytes;
    
    flags |= kSend6SourceSuspended;
    flags |= kReceive6SourceSuspended;
}

- (void)suspendSend4Source
{
    if (send4Source && !(flags & kSend4SourceSuspended))
    {
        LogVerbose(@"dispatch_suspend(send4Source)");
        
        dispatch_suspend(send4Source);
        flags |= kSend4SourceSuspended;
    }
}

- (void)suspendSend6Source
{
    if (send6Source && !(flags & kSend6SourceSuspended))
    {
        LogVerbose(@"dispatch_suspend(send6Source)");
        
        dispatch_suspend(send6Source);
        flags |= kSend6SourceSuspended;
    }
}

- (void)resumeSend4Source
{
    if (send4Source && (flags & kSend4SourceSuspended))
    {
        LogVerbose(@"dispatch_resume(send4Source)");
        
        dispatch_resume(send4Source);
        flags &= ~kSend4SourceSuspended;
    }
}

- (void)resumeSend6Source
{
    if (send6Source && (flags & kSend6SourceSuspended))
    {
        LogVerbose(@"dispatch_resume(send6Source)");
        
        dispatch_resume(send6Source);
        flags &= ~kSend6SourceSuspended;
    }
}
- (void)suspendReceive4Source
{
    if (receive4Source && !(flags & kReceive4SourceSuspended))
    {
        LogVerbose(@"dispatch_suspend(receive4Source)");
        
        dispatch_suspend(receive4Source);
        flags |= kReceive4SourceSuspended;
    }
}

- (void)suspendReceive6Source
{
    if (receive6Source && !(flags & kReceive6SourceSuspended))
    {
        LogVerbose(@"dispatch_suspend(receive6Source)");
        
        dispatch_suspend(receive6Source);
        flags |= kReceive6SourceSuspended;
    }
}

- (void)resumeReceive4Source
{
    if (receive4Source && (flags & kReceive4SourceSuspended))
    {
        LogVerbose(@"dispatch_resume(receive4Source)");
        
        dispatch_resume(receive4Source);
        flags &= ~kReceive4SourceSuspended;
    }
}

- (void)resumeReceive6Source
{
    if (receive6Source && (flags & kReceive6SourceSuspended))
    {
        LogVerbose(@"dispatch_resume(receive6Source)");
        
        dispatch_resume(receive6Source);
        flags &= ~kReceive6SourceSuspended;
    }
}

- (void)doReceive
{
    LogTrace();
    
    if ((flags & (kReceiveOnce | kReceiveContinuous)) == 0)
    {
        LogVerbose(@"Receiving is paused...");
        
        if (socket4FDBytesAvailable > 0) {
            [self suspendReceive4Source];
        }
        if (socket6FDBytesAvailable > 0) {
            [self suspendReceive6Source];
        }
        
        return;
    }
    
    if ((flags & kReceiveOnce) && (pendingFilterOperations > 0))
    {
        LogVerbose(@"Receiving is temporarily paused (pending filter operations)...");
        
        if (socket4FDBytesAvailable > 0) {
            [self suspendReceive4Source];
        }
        if (socket6FDBytesAvailable > 0) {
            [self suspendReceive6Source];
        }
        
        return;
    }
    
    if ((socket4FDBytesAvailable == 0) && (socket6FDBytesAvailable == 0))
    {
        LogVerbose(@"No data available to receive...");
        
        if (socket4FDBytesAvailable == 0) {
            [self resumeReceive4Source];
        }
        if (socket6FDBytesAvailable == 0) {
            [self resumeReceive6Source];
        }
        
        return;
    }
    
    
    BOOL doReceive4;
    
    if (flags & kDidConnect)
    {
        // Connected socket
        
        doReceive4 = (socket4FD != SOCKET_NULL);
    }
    else
    {
        
        if (socket4FDBytesAvailable > 0)
        {
            if (socket6FDBytesAvailable > 0)
            {
                doReceive4 = (flags & kFlipFlop) ? YES : NO;
                
                flags ^= kFlipFlop;
                
            }
            else {
                doReceive4 = YES;
            }
        }
        else {
            doReceive4 = NO;
        }
    }
    
    ssize_t result = 0;
    
    NSData *data = nil;
    NSData *addr4 = nil;
    NSData *addr6 = nil;
    
    if (doReceive4)
    {
        NSAssert(socket4FDBytesAvailable > 0, @"Invalid logic");
        LogVerbose(@"Receiving on IPv4");
        
        struct sockaddr_in sockaddr4;
        socklen_t sockaddr4len = sizeof(sockaddr4);
        
        size_t bufSize = MIN(max4ReceiveSize, socket4FDBytesAvailable);
        void *buf = malloc(bufSize);
        
        result = recvfrom(socket4FD, buf, bufSize, 0, (struct sockaddr *)&sockaddr4, &sockaddr4len);
        LogVerbose(@"recvfrom(socket4FD) = %i", (int)result);
        
        if (result > 0)
        {
            if ((size_t)result >= socket4FDBytesAvailable)
                socket4FDBytesAvailable = 0;
            else
                socket4FDBytesAvailable -= result;
            
            if ((size_t)result != bufSize) {
                buf = realloc(buf, result);
            }
            
            data = [NSData dataWithBytesNoCopy:buf length:result freeWhenDone:YES];
            addr4 = [NSData dataWithBytes:&sockaddr4 length:sockaddr4len];
        }
        else
        {
            LogVerbose(@"recvfrom(socket4FD) = %@", [self errnoError]);
            socket4FDBytesAvailable = 0;
            free(buf);
        }
    }
    else
    {
        NSAssert(socket6FDBytesAvailable > 0, @"Invalid logic");
        LogVerbose(@"Receiving on IPv6");
        
        struct sockaddr_in6 sockaddr6;
        socklen_t sockaddr6len = sizeof(sockaddr6);
        
        size_t bufSize = MIN(max6ReceiveSize, socket6FDBytesAvailable);
        void *buf = malloc(bufSize);
        
        result = recvfrom(socket6FD, buf, bufSize, 0, (struct sockaddr *)&sockaddr6, &sockaddr6len);
        LogVerbose(@"recvfrom(socket6FD) -> %i", (int)result);
        
        if (result > 0)
        {
            if ((size_t)result >= socket6FDBytesAvailable)
                socket6FDBytesAvailable = 0;
            else
                socket6FDBytesAvailable -= result;
            
            if ((size_t)result != bufSize) {
                buf = realloc(buf, result);
            }
            
            data = [NSData dataWithBytesNoCopy:buf length:result freeWhenDone:YES];
            addr6 = [NSData dataWithBytes:&sockaddr6 length:sockaddr6len];
        }
        else
        {
            LogVerbose(@"recvfrom(socket6FD) = %@", [self errnoError]);
            socket6FDBytesAvailable = 0;
            free(buf);
        }
    }
    
    
    BOOL waitingForSocket = NO;
    BOOL notifiedDelegate = NO;
    BOOL ignored = NO;
    
    NSError *socketError = nil;
    
    if (result == 0)
    {
        waitingForSocket = YES;
    }
    else if (result < 0)
    {
        if (errno == EAGAIN)
            waitingForSocket = YES;
        else{
        }
    }
    else
    {
        if (flags & kDidConnect)
        {
            if (addr4 && ![self isConnectedToAddress4:addr4])
                ignored = YES;
            if (addr6 && ![self isConnectedToAddress6:addr6])
                ignored = YES;
        }
        
        NSData *addr = (addr4 != nil) ? addr4 : addr6;
        
        if (!ignored)
        {
            if (receiveFilterBlock && receiveFilterQueue)
            {
                
                __block id filterContext = nil;
                __block BOOL allowed = NO;
                
                if (receiveFilterAsync)
                {
                    pendingFilterOperations++;
                    dispatch_async(receiveFilterQueue, ^{ @autoreleasepool {
                        
                        allowed = receiveFilterBlock(data, addr, &filterContext);
                        
                        dispatch_async(socketQueue, ^{ @autoreleasepool {
                            
                            pendingFilterOperations--;
                            
                            if (allowed)
                            {
                                [self notifyDidReceiveData:data fromAddress:addr withFilterContext:filterContext];
                            }
                            else
                            {
                                LogVerbose(@"received packet silently dropped by receiveFilter");
                            }
                            
                            if (flags & kReceiveOnce)
                            {
                                if (allowed)
                                {
                                    flags &= ~kReceiveOnce;
                                }
                                else if (pendingFilterOperations == 0)
                                {
                                    [self doReceive];
                                }
                            }
                        }});
                    }});
                }
                else // if (!receiveFilterAsync)
                {
                    dispatch_sync(receiveFilterQueue, ^{ @autoreleasepool {
                        
                        allowed = receiveFilterBlock(data, addr, &filterContext);
                    }});
                    
                    if (allowed)
                    {
                        [self notifyDidReceiveData:data fromAddress:addr withFilterContext:filterContext];
                        notifiedDelegate = YES;
                    }
                    else
                    {
                        LogVerbose(@"received packet silently dropped by receiveFilter");
                        ignored = YES;
                    }
                }
            }
            else // if (!receiveFilterBlock || !receiveFilterQueue)
            {
                [self notifyDidReceiveData:data fromAddress:addr withFilterContext:nil];
                notifiedDelegate = YES;
            }
        }
    }
    
    if (waitingForSocket)
    {
        // Wait for a notification of available data.
        
        if (socket4FDBytesAvailable == 0) {
            [self resumeReceive4Source];
        }
        if (socket6FDBytesAvailable == 0) {
            [self resumeReceive6Source];
        }
    }
    else if (socketError)
    {
        [self closeWithError:socketError];
    }
    else
    {
        if (flags & kReceiveContinuous)
        {
            // Continuous receive mode
            [self doReceive];
        }
        else
        {

            if (notifiedDelegate)
            {
                flags &= ~kReceiveOnce;
            }
            else if (ignored)
            {
                [self doReceive];
            }
            else
            {

            }
        }
    }
}

- (void)doReceiveEOF
{
    LogTrace();
    
    [self closeWithError:nil];
}

- (BOOL)isConnectedToAddress4:(NSData *)someAddr4
{
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    NSAssert(flags & kDidConnect, @"Not connected");
    NSAssert(cachedConnectedAddress, @"Expected cached connected address");
    
    if (cachedConnectedFamily != AF_INET)
    {
        return NO;
    }
    
    const struct sockaddr_in *sSockaddr4 = (struct sockaddr_in *)[someAddr4 bytes];
    const struct sockaddr_in *cSockaddr4 = (struct sockaddr_in *)[cachedConnectedAddress bytes];
    
    if (memcmp(&sSockaddr4->sin_addr, &cSockaddr4->sin_addr, sizeof(struct in_addr)) != 0)
    {
        return NO;
    }
    if (memcmp(&sSockaddr4->sin_port, &cSockaddr4->sin_port, sizeof(in_port_t)) != 0)
    {
        return NO;
    }
    
    return YES;
}


- (BOOL)isConnectedToAddress6:(NSData *)someAddr6
{
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    NSAssert(flags & kDidConnect, @"Not connected");
    NSAssert(cachedConnectedAddress, @"Expected cached connected address");
    
    if (cachedConnectedFamily != AF_INET6)
    {
        return NO;
    }
    
    const struct sockaddr_in6 *sSockaddr6 = (struct sockaddr_in6 *)[someAddr6 bytes];
    const struct sockaddr_in6 *cSockaddr6 = (struct sockaddr_in6 *)[cachedConnectedAddress bytes];
    
    if (memcmp(&sSockaddr6->sin6_addr, &cSockaddr6->sin6_addr, sizeof(struct in6_addr)) != 0)
    {
        return NO;
    }
    if (memcmp(&sSockaddr6->sin6_port, &cSockaddr6->sin6_port, sizeof(in_port_t)) != 0)
    {
        return NO;
    }
    
    return YES;
}

- (void)notifyDidReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)context
{
    LogTrace();
    
    SEL selector = @selector(TVSocket:hadReceivedData:fromAddress:withFilterContext:);
    
    if (delegateQueue && [delegate respondsToSelector:selector])
    {
        id theDelegate = delegate;
        
        dispatch_async(delegateQueue, ^{ @autoreleasepool {
            
            [theDelegate TVSocket:self hadReceivedData:data fromAddress:address withFilterContext:context];
        }});
    }
}


- (void)udpSocket:(CHTVSocketDel *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    
    if (0)
    {
    }
    else
    {
        NSString *host = nil;
        uint16_t port = 0;
        [CHTVSocketDel analysisHost:&host port:&port withAddress:address];
        
        NSLog(@"%@", host);
    }
    
}

+ (BOOL)analysisHost:(NSString **)hostPtr port:(uint16_t *)portPtr withAddress:(NSData *)address
{
    return [self getHost:hostPtr port:portPtr family:NULL fromAddress:address];
}

+ (BOOL)getHost:(NSString **)hostPtr port:(uint16_t *)portPtr family:(int *)afPtr fromAddress:(NSData *)address
{
    if ([address length] >= sizeof(struct sockaddr))
    {
        const struct sockaddr *addrX = (const struct sockaddr *)[address bytes];
        
        if (addrX->sa_family == AF_INET)
        {
            if ([address length] >= sizeof(struct sockaddr_in))
            {
                const struct sockaddr_in *addr4 = (const struct sockaddr_in *)addrX;
                
                if (hostPtr) *hostPtr = [self hostFromSockaddr4:addr4];
                if (portPtr) *portPtr = [self portFromSockaddr4:addr4];
                if (afPtr)   *afPtr   = AF_INET;
                
                return YES;
            }
        }
        else if (addrX->sa_family == AF_INET6)
        {
            if ([address length] >= sizeof(struct sockaddr_in6))
            {
                const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6 *)addrX;
                
                if (hostPtr) *hostPtr = [self hostFromSockaddr6:addr6];
                if (portPtr) *portPtr = [self portFromSockaddr6:addr6];
                if (afPtr)   *afPtr   = AF_INET6;
                
                return YES;
            }
        }
    }
    
    if (hostPtr) *hostPtr = nil;
    if (portPtr) *portPtr = 0;
    if (afPtr)   *afPtr   = AF_UNSPEC;
    
    return NO;
}


- (BOOL)beginReceiving:(NSError **)errPtr
{
    LogTrace();
    
    __block BOOL result = NO;
    __block NSError *err = nil;
    
    dispatch_block_t block = ^{
        
        if ((flags & kReceiveContinuous) == 0)
        {
            if ((flags & kDidCreateSockets) == 0)
            {
        
                return_from_block;
            }
            
            flags |= kReceiveContinuous; // Enable
            flags &= ~kReceiveOnce;      // Disable
            
            dispatch_async(socketQueue, ^{ @autoreleasepool {
                
                [self doReceive];
            }});
        }
        
        result = YES;
    };
    
    if (dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey))
        block();
    else
        dispatch_sync(socketQueue, block);
    
    if (err)
        LogError(@"Error in beginReceiving: %@", err);
    
    if (errPtr)
        *errPtr = err;
    
    return result;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Closing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)closeWithError:(NSError *)error
{
    LogVerbose(@"closeWithError: %@", error);
    
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    
    if (currentSend) [self endCurrentSend];
    
    [sendQueue removeAllObjects];
    
//    BOOL shouldCallDelegate = (flags & kDidCreateSockets) ? YES : NO;
    

    [self closeSockets];
    
    // Clear all flags (config remains as is)
    flags = 0;
}

- (void)close
{
    LogTrace();
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        [self closeWithError:nil];
    }};
    
    if (dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey))
        block();
    else
        dispatch_sync(socketQueue, block);
}

- (void)closeSockets
{
    [self closeSocket4];
    [self closeSocket6];
    
    flags &= ~kDidCreateSockets;
}


#pragma mark send


- (void)doPreSend
{
    LogTrace();
    
  
    
    BOOL waitingForResolve = NO;
    NSError *error = nil;
    
    if (flags & kDidConnect)
    {
        // Connected socket
        
        if (currentSend->resolveInProgress || currentSend->resolvedAddresses || currentSend->resolveError)
        {
            
        }
        else
        {
            currentSend->address = cachedConnectedAddress;
            currentSend->addressFamily = cachedConnectedFamily;
        }
    }
    else
    {
        if (currentSend->resolveInProgress)
        {

            waitingForResolve = YES;
        }
        else if (currentSend->resolveError)
        {
            error = currentSend->resolveError;
        }
        else if (currentSend->address == nil)
        {
            if (currentSend->resolvedAddresses == nil)
            {
                NSLog(@"resolvedAddresses == nil");
            }
            else
            {
                // Pick the proper address to use (out of possibly several resolved addresses)
                
                NSData *address = nil;
                int addressFamily = AF_UNSPEC;
                
                addressFamily = [self getAddress:&address error:&error fromAddresses:currentSend->resolvedAddresses];
                
                currentSend->address = address;
                currentSend->addressFamily = addressFamily;
            }
        }
    }
    
    if (waitingForResolve)
    {
        
        LogVerbose(@"currentSend - waiting for address resolve");
        
        if (flags & kSock4CanAcceptBytes) {
            [self suspendSend4Source];
        }
        if (flags & kSock6CanAcceptBytes) {
            [self suspendSend6Source];
        }
        
        return;
    }
    
    if (error)
    {
        
        [self notifyDidNotSendDataWithTag:currentSend->tag dueToError:error];
        [self endCurrentSend];
        [self maybeDequeueSend];
        
        return;
    }
    
    
    if (sendFilterBlock && sendFilterQueue)
    {
        
        if (sendFilterAsync)
        {
            
            currentSend->filterInProgress = YES;
            TVSendPacket *sendPacket = currentSend;
            
            dispatch_async(sendFilterQueue, ^{ @autoreleasepool {
                
                BOOL allowed = sendFilterBlock(sendPacket->buffer, sendPacket->address, sendPacket->tag);
                
                dispatch_async(socketQueue, ^{ @autoreleasepool {
                    
                    sendPacket->filterInProgress = NO;
                    if (sendPacket == currentSend)
                    {
                        if (allowed)
                        {
                            [self doSend];
                        }
                        else
                        {
                            LogVerbose(@"currentSend - silently dropped by sendFilter");
                            
                            [self notifyDidSendDataWithTag:currentSend->tag];
                            [self endCurrentSend];
                            [self maybeDequeueSend];
                        }
                    }
                }});
            }});
        }
        else
        {
            // Scenario 2 of 3 - Need to synchronously query sendFilter
            
            __block BOOL allowed = YES;
            
            dispatch_sync(sendFilterQueue, ^{ @autoreleasepool {
                
                allowed = sendFilterBlock(currentSend->buffer, currentSend->address, currentSend->tag);
            }});
            
            if (allowed)
            {
                [self doSend];
            }
            else
            {
                LogVerbose(@"currentSend - silently dropped by sendFilter");
                
                [self notifyDidSendDataWithTag:currentSend->tag];
                [self endCurrentSend];
                [self maybeDequeueSend];
            }
        }
    }
    else // if (!sendFilterBlock || !sendFilterQueue)
    {
        // Scenario 3 of 3 - No sendFilter. Just go straight into sending.
        
        [self doSend];
    }
}


- (int)getAddress:(NSData **)addressPtr error:(NSError **)errorPtr fromAddresses:(NSArray *)addresses
{
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    NSAssert([addresses count] > 0, @"Expected at least one address");
    
    int resultAF = AF_UNSPEC;
    NSData *resultAddress = nil;
    NSError *resultError = nil;
    

    
    BOOL resolvedIPv4Address = NO;
    BOOL resolvedIPv6Address = NO;
    
    for (NSData *address in addresses)
    {
        switch ([[self class] familyFromAddress:address])
        {
            case AF_INET  : resolvedIPv4Address = YES; break;
            case AF_INET6 : resolvedIPv6Address = YES; break;
                
            default       : NSAssert(NO, @"Addresses array contains invalid address");
        }
    }
    
    BOOL isIPv4Disabled = (config & kIPv4Disabled) ? YES : NO;
    BOOL isIPv6Disabled = (config & kIPv6Disabled) ? YES : NO;
    
    if (isIPv4Disabled && !resolvedIPv6Address)
    {
        if (addressPtr) *addressPtr = resultAddress;
        if (errorPtr) *errorPtr = resultError;
        
        return resultAF;
    }
    
    if (isIPv6Disabled && !resolvedIPv4Address)
    {
        if (addressPtr) *addressPtr = resultAddress;
        if (errorPtr) *errorPtr = resultError;
        
        return resultAF;
    }
    
    BOOL isIPv4Deactivated = (flags & kIPv4Deactivated) ? YES : NO;
    BOOL isIPv6Deactivated = (flags & kIPv6Deactivated) ? YES : NO;
    
    if (isIPv4Deactivated && !resolvedIPv6Address)
    {
        if (addressPtr) *addressPtr = resultAddress;
        if (errorPtr) *errorPtr = resultError;
        
        return resultAF;
    }
    
    if (isIPv6Deactivated && !resolvedIPv4Address)
    {
        if (addressPtr) *addressPtr = resultAddress;
        if (errorPtr) *errorPtr = resultError;
        
        return resultAF;
    }
    
    
    BOOL ipv4WasFirstInList = YES;
    NSData *address4 = nil;
    NSData *address6 = nil;
    
    for (NSData *address in addresses)
    {
        int af = [[self class] familyFromAddress:address];
        
        if (af == AF_INET)
        {
            if (address4 == nil)
            {
                address4 = address;
                
                if (address6)
                    break;
                else
                    ipv4WasFirstInList = YES;
            }
        }
        else // af == AF_INET6
        {
            if (address6 == nil)
            {
                address6 = address;
                
                if (address4)
                    break;
                else
                    ipv4WasFirstInList = NO;
            }
        }
    }
    
    // Determine socket type
    
    BOOL preferIPv4 = (config & kPreferIPv4) ? YES : NO;
    BOOL preferIPv6 = (config & kPreferIPv6) ? YES : NO;
    
    BOOL useIPv4 = ((preferIPv4 && address4) || (address6 == nil));
    BOOL useIPv6 = ((preferIPv6 && address6) || (address4 == nil));
    
    NSAssert(!(preferIPv4 && preferIPv6), @"Invalid config state");
    NSAssert(!(useIPv4 && useIPv6), @"Invalid logic");
    
    if (useIPv4 || (!useIPv6 && ipv4WasFirstInList))
    {
        resultAF = AF_INET;
        resultAddress = address4;
    }
    else
    {
        resultAF = AF_INET6;
        resultAddress = address6;
    }
    
    if (addressPtr) *addressPtr = resultAddress;
    if (errorPtr) *errorPtr = resultError;
    
    return resultAF;
}

- (void)notifyDidSendDataWithTag:(long)tag
{
    LogTrace();
    
    if (delegateQueue && [delegate respondsToSelector:@selector(TVSocket:hadSentDataWithTag:)])
    {
        id theDelegate = delegate;
        
        dispatch_async(delegateQueue, ^{ @autoreleasepool {
            
            [theDelegate TVSocket:self hadSentDataWithTag:tag];
        }});
    }
}

- (void)notifyDidNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    LogTrace();
    
    if (delegateQueue && [delegate respondsToSelector:@selector(TVSocket:hadNotSentDataWithTag:dueToError:)])
    {
        id theDelegate = delegate;
        
        dispatch_async(delegateQueue, ^{ @autoreleasepool {
            
            [theDelegate TVSocket:self hadNotSentDataWithTag:tag dueToError:error];
        }});
    }
}


- (void)endCurrentSend
{
    if (sendTimer)
    {
        dispatch_source_cancel(sendTimer);
#if !OS_OBJECT_USE_OBJC
        dispatch_release(sendTimer);
#endif
        sendTimer = NULL;
    }
    
    currentSend = nil;
}


- (void)maybeDequeueSend
{
    LogTrace();
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    

    if (currentSend == nil)
    {

        if ((flags & kDidCreateSockets) == 0)
        {
            NSError *err = nil;
            if (![self createSockets:&err])
            {
                [self closeWithError:err];
                return;
            }
        }
        
        while ([sendQueue count] > 0)
        {
            currentSend = [sendQueue objectAtIndex:0];
            [sendQueue removeObjectAtIndex:0];
            
            if ([currentSend isKindOfClass:[TVSpecialPacket class]])
            {
                [self maybeConnect];
                
                return;
            }
            else if (currentSend->resolveError)
            {
                // Notify delegate
                [self notifyDidNotSendDataWithTag:currentSend->tag dueToError:currentSend->resolveError];
                
                // Clear currentSend
                currentSend = nil;
                
                continue;
            }
            else
            {
                [self doPreSend];
                
                break;
            }
        }
        
        if ((currentSend == nil) && (flags & kCloseAfterSends))
        {
            [self closeWithError:nil];
        }
    }
}


- (void)maybeConnect
{
    LogTrace();
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    
    
    BOOL sendQueueReady = [currentSend isKindOfClass:[TVSpecialPacket class]];
    
    if (sendQueueReady)
    {
        TVSpecialPacket *connectPacket = (TVSpecialPacket *)currentSend;
        
        if (connectPacket->resolveInProgress)
        {
            LogVerbose(@"Waiting for DNS resolve...");
        }
        else
        {
            if (connectPacket->error)
            {
                //                [self notifyDidNotConnect:connectPacket->error];
            }
            else
            {
                NSData *address = nil;
                NSError *error = nil;
                
                int addressFamily = [self getAddress:&address error:&error fromAddresses:connectPacket->addresses];
                
                // Perform connect
                
                BOOL result = NO;
                
                switch (addressFamily)
                {
                    case AF_INET  : result = [self connectWithAddress4:address error:&error]; break;
                    case AF_INET6 : result = [self connectWithAddress6:address error:&error]; break;
                }
                
                if (result)
                {
                    flags |= kDidBind;
                    flags |= kDidConnect;
                    
                    cachedConnectedAddress = address;
                    cachedConnectedHost = [[self class] hostFromAddress:address];
                    cachedConnectedPort = [[self class] portFromAddress:address];
                    cachedConnectedFamily = addressFamily;
                    
                    [self notifyDidConnectToAddress:address];
                }
                else
                {
                    [self notifyDidNotConnect:error];
                }
            }
            
            flags &= ~kConnecting;
            
            [self endCurrentSend];
            [self maybeDequeueSend];
        }
    }
}
- (void)notifyDidConnectToAddress:(NSData *)anAddress
{
    LogTrace();
    
    if (delegateQueue && [delegate respondsToSelector:@selector(TVSocket:hadConnectedToAddress:)])
    {
        id theDelegate = delegate;
        NSData *address = [anAddress copy]; // In case param is NSMutableData
        
        dispatch_async(delegateQueue, ^{ @autoreleasepool {
            
            [theDelegate TVSocket:self hadConnectedToAddress:address];
        }});
    }
}

- (BOOL)connectWithAddress4:(NSData *)address4 error:(NSError **)errPtr
{
    LogTrace();
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    
    int status = connect(socket4FD, (struct sockaddr *)[address4 bytes], (socklen_t)[address4 length]);
    if (status != 0)
    {
            
            return NO;
    }
    
    [self closeSocket6];
    flags |= kIPv6Deactivated;
    
    return YES;
}
- (void)notifyDidNotConnect:(NSError *)error
{
    LogTrace();
    
    if (delegateQueue && [delegate respondsToSelector:@selector(TVSocket:hadNotConnected:)])
    {
        id theDelegate = delegate;
        
        dispatch_async(delegateQueue, ^{ @autoreleasepool {
            
            [theDelegate TVSocket:self hadNotConnected:error];
        }});
    }
}

- (BOOL)connectWithAddress6:(NSData *)address6 error:(NSError **)errPtr
{
    LogTrace();
    NSAssert(dispatch_get_specific(IsOnSocketQueueOrTargetQueueKey), @"Must be dispatched on socketQueue");
    
    int status = connect(socket6FD, (struct sockaddr *)[address6 bytes], (socklen_t)[address6 length]);
    if (status != 0)
    {
            return NO;
    }
    
    [self closeSocket4];
    flags |= kIPv4Deactivated;
    
    return YES;
}



- (void)doSend
{
    LogTrace();
    
    NSAssert(currentSend != nil, @"Invalid logic");
    
    // Perform the actual send
    
    ssize_t result = 0;
    
    if (flags & kDidConnect)
    {
        // Connected socket
        
        const void *buffer = [currentSend->buffer bytes];
        size_t length = (size_t)[currentSend->buffer length];
        
        if (currentSend->addressFamily == AF_INET)
        {
            result = send(socket4FD, buffer, length, 0);
            LogVerbose(@"send(socket4FD) = %d", result);
        }
        else
        {
            result = send(socket6FD, buffer, length, 0);
            LogVerbose(@"send(socket6FD) = %d", result);
        }
    }
    else
    {
        // Non-Connected socket
        
        const void *buffer = [currentSend->buffer bytes];
        size_t length = (size_t)[currentSend->buffer length];
        
        const void *dst  = [currentSend->address bytes];
        socklen_t dstSize = (socklen_t)[currentSend->address length];
        
        if (currentSend->addressFamily == AF_INET)
        {
            result = sendto(socket4FD, buffer, length, 0, dst, dstSize);
            LogVerbose(@"sendto(socket4FD) = %d", result);
        }
        else
        {
            result = sendto(socket6FD, buffer, length, 0, dst, dstSize);
            LogVerbose(@"sendto(socket6FD) = %d", result);
        }
    }
    
    if ((flags & kDidBind) == 0)
    {
        flags |= kDidBind;
    }
    
    
    BOOL waitingForSocket = NO;
    NSError *socketError = nil;
    
    if (result == 0)
    {
        waitingForSocket = YES;
    }
    else if (result < 0)
    {
        if (errno == EAGAIN)
            waitingForSocket = YES;
    }
    
    if (waitingForSocket)
    {

        LogVerbose(@"currentSend - waiting for socket");
        
        if (!(flags & kSock4CanAcceptBytes)) {
            [self resumeSend4Source];
        }
        if (!(flags & kSock6CanAcceptBytes)) {
            [self resumeSend6Source];
        }
        
        if ((sendTimer == NULL) && (currentSend->timeout >= 0.0))
        {

            
            [self setupSendTimerWithTimeout:currentSend->timeout];
        }
    }
    else if (socketError)
    {
        [self closeWithError:socketError];
    }
    else // done
    {
        [self notifyDidSendDataWithTag:currentSend->tag];
        [self endCurrentSend];
        [self maybeDequeueSend];
    }
}

- (void)setupSendTimerWithTimeout:(NSTimeInterval)timeout
{
    NSAssert(sendTimer == NULL, @"Invalid logic");
    NSAssert(timeout >= 0.0, @"Invalid logic");
    
    LogTrace();
    
    sendTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, socketQueue);
    
    dispatch_source_set_event_handler(sendTimer, ^{ @autoreleasepool {
        
        [self doSendTimeout];
    }});
    
    dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    
    dispatch_source_set_timer(sendTimer, tt, DISPATCH_TIME_FOREVER, 0);
    dispatch_resume(sendTimer);
}

- (void)doSendTimeout
{
    LogTrace();
    
    [self endCurrentSend];
    [self maybeDequeueSend];
}

- (void)writeBuffer:(NSData *)data
          onHost:(NSString *)host
            port:(uint16_t)port
     inTimeout:(NSTimeInterval)timeout
             tag:(long)tag
{
    LogTrace();
    
    if ([data length] == 0)
    {
        LogWarn(@"Ignoring attempt to send nil/empty data.");
        return;
    }
    
    TVSendPacket *packet = [[TVSendPacket alloc] initWithData:data timeout:timeout tag:tag];
    packet->resolveInProgress = YES;
    
    [self asyncResolveHost:host port:port withCompletionBlock:^(NSArray *addresses, NSError *error) {
        
        
        packet->resolveInProgress = NO;
        
        packet->resolvedAddresses = addresses;
        packet->resolveError = error;
        
        if (packet == currentSend)
        {
            LogVerbose(@"currentSend - address resolved");
            [self doPreSend];
        }
    }];
    
    dispatch_async(socketQueue, ^{ @autoreleasepool {
        
        [sendQueue addObject:packet];
        [self maybeDequeueSend];
        
    }});
    
}

- (void)asyncResolveHost:(NSString *)aHost
                    port:(uint16_t)port
     withCompletionBlock:(void (^)(NSArray *addresses, NSError *error))completionBlock
{
    LogTrace();
    
    
    if (aHost == nil)
    {

        
        dispatch_async(socketQueue, ^{ @autoreleasepool {
            
        }});
        
        return;
    }
    
    
    NSString *host = [aHost copy];
    
    
    dispatch_queue_t globalConcurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalConcurrentQueue, ^{ @autoreleasepool {
        
        NSMutableArray *addresses = [NSMutableArray arrayWithCapacity:2];
        NSError *error = nil;
        
        if ([host isEqualToString:@"localhost"] || [host isEqualToString:@"loopback"])
        {
            // Use LOOPBACK address
            struct sockaddr_in sockaddr4;
            memset(&sockaddr4, 0, sizeof(sockaddr4));
            
            sockaddr4.sin_len         = sizeof(struct sockaddr_in);
            sockaddr4.sin_family      = AF_INET;
            sockaddr4.sin_port        = htons(port);
            sockaddr4.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
            
            struct sockaddr_in6 sockaddr6;
            memset(&sockaddr6, 0, sizeof(sockaddr6));
            
            sockaddr6.sin6_len       = sizeof(struct sockaddr_in6);
            sockaddr6.sin6_family    = AF_INET6;
            sockaddr6.sin6_port      = htons(port);
            sockaddr6.sin6_addr      = in6addr_loopback;
            
            // Wrap the native address structures and add to list
            [addresses addObject:[NSData dataWithBytes:&sockaddr4 length:sizeof(sockaddr4)]];
            [addresses addObject:[NSData dataWithBytes:&sockaddr6 length:sizeof(sockaddr6)]];
        }
        else
        {
            NSString *portStr = [NSString stringWithFormat:@"%hu", port];
            
            struct addrinfo hints, *res, *res0;
            
            memset(&hints, 0, sizeof(hints));
            hints.ai_family   = PF_UNSPEC;
            hints.ai_socktype = SOCK_DGRAM;
            hints.ai_protocol = IPPROTO_UDP;
            
            int gai_error = getaddrinfo([host UTF8String], [portStr UTF8String], &hints, &res0);
            
            if (gai_error)
            {
            }
            else
            {
                for(res = res0; res; res = res->ai_next)
                {
                    if (res->ai_family == AF_INET)
                    {
                        
                        [addresses addObject:[NSData dataWithBytes:res->ai_addr length:res->ai_addrlen]];
                    }
                    else if (res->ai_family == AF_INET6)
                    {
                        
                        [addresses addObject:[NSData dataWithBytes:res->ai_addr length:res->ai_addrlen]];
                    }
                }
                freeaddrinfo(res0);
                
                if ([addresses count] == 0)
                {
                }
            }
        }
        
        dispatch_async(socketQueue, ^{ @autoreleasepool {
            
            completionBlock(addresses, error);
        }});
        
    }});
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Class Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)closeSocket4
{
    if (socket4FD != SOCKET_NULL)
    {
        LogVerbose(@"dispatch_source_cancel(send4Source)");
        dispatch_source_cancel(send4Source);
        
        LogVerbose(@"dispatch_source_cancel(receive4Source)");
        dispatch_source_cancel(receive4Source);
        
        
        [self resumeSend4Source];
        [self resumeReceive4Source];
        
        send4Source = NULL;
        receive4Source = NULL;
        
        socket4FD = SOCKET_NULL;
        
        socket4FDBytesAvailable = 0;
        flags &= ~kSock4CanAcceptBytes;
        
        
        cachedLocalAddress4 = nil;
        cachedLocalHost4 = nil;
        cachedLocalPort4 = 0;
    }
}

- (void)closeSocket6
{
    if (socket6FD != SOCKET_NULL)
    {
        LogVerbose(@"dispatch_source_cancel(send6Source)");
        dispatch_source_cancel(send6Source);
        
        LogVerbose(@"dispatch_source_cancel(receive6Source)");
        dispatch_source_cancel(receive6Source);
        
        
        [self resumeSend6Source];
        [self resumeReceive6Source];
        
        send6Source = NULL;
        receive6Source = NULL;

        
        socket6FD = SOCKET_NULL;
        
        socket6FDBytesAvailable = 0;
        flags &= ~kSock6CanAcceptBytes;
        
        
        cachedLocalAddress6 = nil;
        cachedLocalHost6 = nil;
        cachedLocalPort6 = 0;
    }
}


+ (NSString *)hostFromSockaddr4:(const struct sockaddr_in *)pSockaddr4
{
    char addrBuf[INET_ADDRSTRLEN];
    
    if (inet_ntop(AF_INET, &pSockaddr4->sin_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL)
    {
        addrBuf[0] = '\0';
    }
    
    return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

+ (NSString *)hostFromSockaddr6:(const struct sockaddr_in6 *)pSockaddr6
{
    char addrBuf[INET6_ADDRSTRLEN];
    
    if (inet_ntop(AF_INET6, &pSockaddr6->sin6_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL)
    {
        addrBuf[0] = '\0';
    }
    
    return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

+ (uint16_t)portFromSockaddr4:(const struct sockaddr_in *)pSockaddr4
{
    return ntohs(pSockaddr4->sin_port);
}

+ (uint16_t)portFromSockaddr6:(const struct sockaddr_in6 *)pSockaddr6
{
    return ntohs(pSockaddr6->sin6_port);
}

+ (int)familyFromAddress:(NSData *)address
{
    int af = AF_UNSPEC;
    [self getHost:NULL port:NULL family:&af fromAddress:address];
    
    return af;
}

+ (NSString *)hostFromAddress:(NSData *)address
{
    NSString *host = nil;
    [self getHost:&host port:NULL family:NULL fromAddress:address];
    
    return host;
}

+ (uint16_t)portFromAddress:(NSData *)address
{
    uint16_t port = 0;
    [self getHost:NULL port:&port family:NULL fromAddress:address];
    
    return port;
}


@end


