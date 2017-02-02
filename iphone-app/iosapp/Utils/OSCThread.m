//
//  OSCThread.m
//  iosapp
//
//  Created by ChanAetern on 3/1/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "OSCThread.h"
#import "OSCAPI.h"
#import "Config.h"
#import "Utils.h"

#import <AFNetworking.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <Reachability.h>

static BOOL isPollingStarted;
static NSTimer *timer;
static Reachability *reachability;
//如果你想在iOS程序中提供一仅在wifi网络下使用(Reeder)，或者在没有网络状态下提供离线模式(Evernote)。那么你会使用到Reachability来实现网络检测
@interface OSCThread ()

@end

@implementation OSCThread

+ (void)startPollingNotice
{
    if (isPollingStarted) {
        return;
    } else {
        //计时器的计时间隔为6
        timer = [NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
        //开启www.oschina.net网络检测
        reachability = [Reachability reachabilityWithHostName:@"www.oschina.net"];
        isPollingStarted = YES;
    }
}

+ (void)timerUpdate
{
    if (reachability.currentReachabilityStatus == 0) {return;}
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
    
    [manager GET:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_USER_NOTICE]
      parameters:@{@"uid":@([Config getOwnID])}
         success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseObject) {
             ONOXMLElement *notice = [responseObject.rootElement firstChildWithTag:@"notice"];
             int atCount = [[[notice firstChildWithTag:@"atmeCount"] numberValue] intValue];
             int msgCount = [[[notice firstChildWithTag:@"msgCount"] numberValue] intValue];
             int reviewCount = [[[notice firstChildWithTag:@"reviewCount"] numberValue] intValue];
             int newFansCount = [[[notice firstChildWithTag:@"newFansCount"] numberValue] intValue];
             
             [[NSNotificationCenter defaultCenter] postNotificationName:OSCAPI_USER_NOTICE
                                                                 object:@[@(atCount), @(reviewCount), @(msgCount), @(newFansCount)]];
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"%@", error);
         }];
}

@end
