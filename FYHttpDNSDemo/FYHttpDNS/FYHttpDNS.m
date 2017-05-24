//
//  FYHttpDNS.m
//  FYHttpDNSDemo
//
//  Created by Clover on 5/23/17.
//  Copyright © 2017 Clover. All rights reserved.
//

#import "FYHttpDNS.h"
#import "FYDNSPod.h"
#import "FYURLProtocol_Private.h"
#import <libkern/OSAtomic.h>

static OSSpinLock lock = OS_SPINLOCK_INIT;

@implementation FYHttpDNSConfiguration

+ (FYHttpDNSConfiguration *)sharedConfiguration {
    static FYHttpDNSConfiguration *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[FYHttpDNSConfiguration alloc] init];
    });
    return _instance;
}

@end

@implementation FYHttpDNS

+ (void)resolveDomain:(NSString *)domain {
    NSString *IPFilePath = [self getIPFilePath];
    FYDNSPod *dnsPod = [[FYDNSPod alloc] init];
    [dnsPod queryWithDomain:domain block:^(NSArray *IPArray) {
        if(IPArray) {
            OSSpinLockLock(&lock);
            NSMutableDictionary *IPDic = [NSMutableDictionary dictionaryWithContentsOfFile:IPFilePath];
            if(IPDic) {
                [IPDic setObject:IPArray forKey:domain];
            }else {
                IPDic = [NSMutableDictionary dictionaryWithObject:IPArray forKey:domain];
            }
            [IPDic writeToFile:IPFilePath atomically:YES];
            OSSpinLockUnlock(&lock);
        }else {
            OSSpinLockLock(&lock);
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if([fileManager fileExistsAtPath:IPFilePath]) {
                [fileManager removeItemAtPath:IPFilePath error:nil];
            }
            OSSpinLockUnlock(&lock);
        }
    }];
}

+ (void)replaceDomain:(NSString *)domain withConfiguration:(NSURLSessionConfiguration *)configuration {
    NSString *IPFilePath = [[self class] getIPFilePath];
    NSDictionary *IPDic = [NSDictionary dictionaryWithContentsOfFile:IPFilePath];
    if(IPDic) {
        NSArray *IPs = (NSArray *)IPDic[domain];
        if(!IPs || !IPs.count) {
            return;
        }
        NSString *IP = IPs.firstObject;
        
        configuration.protocolClasses = @[[FYURLProtocol class]];
        [FYURLProtocol configureHostWithBlock:^(id<FYURLProtocolConfiguration> configuration1) {
            configuration1.certPath = kHttpDNSConfiguration.certPath;
            configuration1.SSLPinningMode = kHttpDNSConfiguration.SSLPinningMode;
            [configuration1 resolveHost:domain toIP:IP configuration:configuration];
        }];
        
    }
}

#pragma mark - Private methods
+ (NSString *)getIPFilePath {
    static NSString *IPFilePath;
    if(!IPFilePath) {
        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        IPFilePath = [path stringByAppendingPathComponent:@"iplist.plist"];
    }
    return IPFilePath;
}
@end
