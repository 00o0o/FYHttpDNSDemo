//
//  ViewController.m
//  FYHttpDNSDemo
//
//  Created by Clover on 5/23/17.
//  Copyright © 2017 Clover. All rights reserved.
//

#import "ViewController.h"
#import <MJRefresh/MJRefresh.h>
#import <AFNetworking/AFNetworking.h>
#import <YYModel/YYModel.h>
#import "FYHttpDNS.h"
#import "Common.h"
#import "Book.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *datas;

@property (nonatomic, strong) NSURL *baseURL;

@property (nonatomic, assign) NSInteger start;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadData)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    
    self.datas = [NSMutableArray array];
    self.baseURL = [NSURL URLWithString:API_HOST];
}

- (void)loadData {
    self.start = 0;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [FYHttpDNS replaceDomain:self.baseURL.host withConfiguration:configuration];
    
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL sessionConfiguration:configuration];
    
    [sessionManager GET:@"v2/book/search" parameters:@{@"q": @"iOS", @"start": @(self.start)} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self.tableView.mj_header endRefreshing];
        
        NSMutableArray *arr = responseObject[@"books"];
        self.datas = [NSMutableArray arrayWithArray:[NSArray yy_modelArrayWithClass:[Book class] json:arr]];
        [self.tableView reloadData];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.tableView.mj_header endRefreshing];
        NSLog(@"error: %@", error);
    }];
}

- (void)loadMoreData {
    self.start = self.datas.count;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [FYHttpDNS replaceDomain:self.baseURL.host withConfiguration:configuration];
    
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL sessionConfiguration:configuration];
    
    [sessionManager GET:@"v2/book/search" parameters:@{@"q": @"iOS", @"start": @(self.start)} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self.tableView.mj_footer endRefreshing];
        
        NSMutableArray *arr = responseObject[@"books"];
        NSArray *datas = [NSMutableArray arrayWithArray:[NSArray yy_modelArrayWithClass:[Book class] json:arr]];
        [self.datas addObjectsFromArray:datas];
        [self.tableView reloadData];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.tableView.mj_footer endRefreshing];
        NSLog(@"error: %@", error);
    }];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Book *book = [self.datas objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = book.title;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
#pragma mark - UITableViewDelegate

@end
