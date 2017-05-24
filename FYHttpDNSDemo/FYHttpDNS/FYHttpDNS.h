//
//  FYHttpDNS.h
//  FYHttpDNSDemo
//
//  Created by Clover on 5/23/17.
//  Copyright © 2017 Clover. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYURLProtocol.h"

#define kHttpDNSConfiguration [FYHttpDNSConfiguration sharedConfiguration]

@interface FYHttpDNSConfiguration : NSObject

@property (nonatomic, copy) NSString *certPath;
@property (nonatomic, assign) FYSSLPinningMode SSLPinningMode;

+ (FYHttpDNSConfiguration *)sharedConfiguration;
@end

@interface FYHttpDNS : NSObject

+ (void)resolveDomain:(NSString *)domain;
+ (void)replaceDomain:(NSString *)domain withConfiguration:(NSURLSessionConfiguration *)configuration;
@end
