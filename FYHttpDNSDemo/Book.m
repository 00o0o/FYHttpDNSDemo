//
//  Book.m
//  FYHttpDNSDemo
//
//  Created by Clover on 5/23/17.
//  Copyright © 2016 Clover. All rights reserved.
//

#import "Book.h"

@implementation Rating

@end

@implementation Tag

@end

@implementation Book

+ (NSDictionary *)modelContainerPropertyGenericClass {
    
    return @{@"author": [NSString class],
             @"tags": [Tag class],
             @"images": [NSString class]};
}

+ (NSDictionary *)modelCustomPropertyMapper {
    
    return @{@"idx": @"id"};
}

@end
