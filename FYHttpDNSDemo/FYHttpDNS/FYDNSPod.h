//
//  FYDNSPod.h
//  FYHttpDNSDemo
//
//  Created by Clover on 5/23/17.
//  Copyright © 2017 Clover. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FYDNSPod : NSObject

- (instancetype)initWithServer:(NSString *)server;
- (instancetype)initWithServer:(NSString *)server timeout:(NSUInteger)timeout;
- (void)queryWithDomain:(NSString *)domain block:(void(^)(NSArray *))block;
@end
