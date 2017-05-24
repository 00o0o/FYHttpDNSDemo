//
//  Book.h
//  FYHttpDNSDemo
//
//  Created by Clover on 5/23/17.
//  Copyright © 2016 Clover. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Rating : NSObject

@property (nonatomic, assign) NSInteger max;
@property (nonatomic, assign) NSInteger numRaters;
@property (nonatomic, assign) CGFloat average;
@property (nonatomic, assign) NSInteger min;
@end

@interface Tag : NSObject

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *title;
@end

@interface Book : NSObject

@property (nonatomic, strong) Rating *rating;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSArray<NSString *> *author;
@property (nonatomic, copy) NSArray<Tag *> *tags;
@property (nonatomic, copy) NSString *origin_title;
@property (nonatomic, copy) NSString *image;
@property (nonatomic, copy) NSString *binding;
@property (nonatomic, copy) NSArray *translator;
@property (nonatomic, copy) NSString *catalog;
@property (nonatomic, assign) NSInteger pages;
@property (nonatomic, copy) NSArray<NSString *> *images;
@property (nonatomic, copy) NSString *alt;
@property (nonatomic, assign) NSInteger xid;
@property (nonatomic, copy) NSString *publisher;
@property (nonatomic, copy) NSString *isbn10;
@property (nonatomic, copy) NSString *isbn13;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *alt_title;
@property (nonatomic, copy) NSString *author_intro;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSDictionary *series;
@property (nonatomic, copy) NSString *price;

@end
