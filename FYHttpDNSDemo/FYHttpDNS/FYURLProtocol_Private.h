//
//  FYURLProtocol_Private.h
//  FYHttpDNSDemo
//
//  Created by Clover on 5/23/17.
//  Copyright © 2017 Clover. All rights reserved.
//

#import "FYURLProtocol.h"

@protocol FYURLProtocolConfiguration;

@interface FYURLProtocol: NSURLProtocol

+ (void)configureHostWithBlock:(void(^)(id<FYURLProtocolConfiguration>))configuration;
@end

@protocol FYURLProtocolConfiguration <NSObject>

@property (nonatomic, copy) NSString *certPath;
@property (nonatomic, assign) FYSSLPinningMode SSLPinningMode;

- (void)resolveHost:(NSString *)host toIP:(NSString *)IP configuration:(NSURLSessionConfiguration *)configuration;

@end
