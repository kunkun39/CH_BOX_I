//
//  TVSocketManager.h
//  AsyncChatClient
//
//  Created by shanshu on 15/4/23.
//  Copyright (c) 2015年 crazyit.org. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <TargetConditionals.h>
#import <Availability.h>

extern NSString *const TVSocketException;
extern NSString *const TVSocketErrorDomain;

extern NSString *const TVSocketQueueName;
extern NSString *const TVSocketThreadName;

enum TVSocketError
{
    TVSocketNoError = 0,          // Never used
    TVSocketBadConfigError,       // Invalid configuration
    TVSocketBadParamError,        // Invalid parameter was passed
    TVSocketSendTimeoutError,     // A send operation timed out
    TVSocketClosedError,          // The socket was closed
    TVSocketOtherError,           // Description provided in userInfo
};
typedef enum TVSocketError TVSocketError;

typedef BOOL (^TVSocketReceiveFilterBlock)(NSData *data, NSData *address, id *context);

typedef BOOL (^TVSocketSendFilterBlock)(NSData *data, NSData *address, long tag);


@interface CHTVSocketDel : NSObject
- (id)init;
- (id)createSocketQueue:(dispatch_queue_t)socketq;
- (id)createdelegateQueue:(dispatch_queue_t)delegateq withDelegate:(id)aDelegate;

- (BOOL)datagramSocket:(uint16_t)datagram error:(NSError **)errPtr;
- (BOOL)datagramSocket:(uint16_t)datagram description:(NSString *)description error:(NSError **)errPtr;

- (BOOL)beginReceiving:(NSError **)errPtr;

+ (BOOL)analysisHost:(NSString **)hostPtr port:(uint16_t *)portPtr withAddress:(NSData *)address;

- (void)writeBuffer:(NSData *)data
          onHost:(NSString *)host
            port:(uint16_t)port
     inTimeout:(NSTimeInterval)timeout
             tag:(long)tag;
- (void)close;
@end

@protocol TVSocketDelegate

@optional
- (void)TVSocket:(CHTVSocketDel *)sock hadNotConnected:(NSError *)error;

- (void)TVSocket:(CHTVSocketDel *)sock hadConnectedToAddress:(NSData *)address;

- (void)TVSocket:(CHTVSocketDel *)sock hadSentDataWithTag:(long)tag;

- (void)TVSocket:(CHTVSocketDel *)sock hadReceivedData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext;

- (void)TVSocket:(CHTVSocketDel *)sock hadNotSentDataWithTag:(long)tag dueToError:(NSError *)error;
@end



