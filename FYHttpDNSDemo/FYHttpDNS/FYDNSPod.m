//
//  FYDNSPod.m
//  FYHttpDNSDemo
//
//  Created by Clover on 5/23/17.
//  Copyright © 2017 Clover. All rights reserved.
//

#import "FYDNSPod.h"

static NSString * const defaultServer = @"119.29.29.29";
static NSUInteger defaultTimeout = 5;

@interface FYDNSPod ()

@property (nonatomic, copy) NSString *server;
@property (nonatomic, assign) NSUInteger timeout;
@end

@implementation FYDNSPod

- (instancetype)init {
    return [self initWithServer:defaultServer timeout:defaultTimeout];
}

- (instancetype)initWithServer:(NSString *)server {
    return [self initWithServer:server timeout:defaultTimeout];
}

- (instancetype)initWithServer:(NSString *)server timeout:(NSUInteger)timeout {
    self = [super init];
    if(self) {
        _server = server;
        _timeout = timeout;
    }
    return self;
}

- (void)queryWithDomain:(NSString *)domain block:(void (^)(NSArray *))block {
    NSString *queryURLString = [NSString stringWithFormat:@"http://%@/d?ttl=1&dn=%@", _server, domain];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:queryURLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:_timeout];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(data && !error) {
            NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
            if(resp.statusCode != 200) {
                !block ?: block(nil);
                return;
            }
            
            NSString *respString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            NSArray *IP1 = [respString componentsSeparatedByString:@","];
            if(IP1.count != 2) {
                !block ?: block(nil);
                return;
            }
            
            NSString *ttlStr = [IP1 objectAtIndex:1];
            int ttl = [ttlStr intValue];
            if (ttl <= 0) {
                !block ?: block(nil);
                return;
            }
            
            NSString *IPs = [IP1 objectAtIndex:0];
            NSArray *IPArray = [IPs componentsSeparatedByString:@";"];
            NSMutableArray *ret = [NSMutableArray array];
            for (int i = 0; i < IPArray.count; i++) {
                NSString *IP = IPArray[i];
                if([self isIP:IP]) {
                    [ret addObject:IP];
                }
            }
            
            if(ret.count && block) {
                block(ret);
            }else {
                block(nil);
            }
            return;
        }
    }];
    [task resume];
}

#pragma mark - Private methods
- (BOOL)isIP:(NSString *)IP {
    NSString *regex = @"^[\\d]{1,3}\\.[\\d]{1,3}\\.[\\d]{1,3}\\.[\\d]{1,3}$";
    NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [test evaluateWithObject:IP];
}

@end
