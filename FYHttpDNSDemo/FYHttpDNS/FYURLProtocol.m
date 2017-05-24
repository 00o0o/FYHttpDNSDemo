//
//  FYURLProtocol.m
//  FYHttpDNSDemo
//
//  Created by Clover on 5/23/17.
//  Copyright © 2017 Clover. All rights reserved.
//

#import "FYURLProtocol.h"
#import "FYURLProtocol_Private.h"

#pragma mark - FYURLProtocolConfiguration
@interface FYURLProtocolConfiguration : NSObject<FYURLProtocolConfiguration>

@property (nonatomic, strong, readonly) NSURLSessionConfiguration *sessionConfiguration;

+ (FYURLProtocolConfiguration *)sharedConfiguration;

- (NSString *)IPForHost:(NSString *)host;
@end

@interface FYURLProtocolConfiguration ()

@property (nonatomic, strong, readwrite) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong) NSMutableDictionary *IPDic;
@end

@implementation FYURLProtocolConfiguration
@synthesize certPath = _certPath;
@synthesize SSLPinningMode = _SSLPinningMode;

+ (FYURLProtocolConfiguration *)sharedConfiguration {
    static FYURLProtocolConfiguration *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[FYURLProtocolConfiguration alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if(self) {
        self.IPDic = [NSMutableDictionary dictionary];
        self.SSLPinningMode = FYSSLPinningModeNone;
    }
    return self;
}

- (void)resolveHost:(NSString *)host toIP:(NSString *)IP configuration:(NSURLSessionConfiguration *)configuration {
    NSParameterAssert(host);
    NSParameterAssert(IP);
    NSParameterAssert(configuration);
    
    [self.IPDic setObject:IP forKey:host];
    self.sessionConfiguration = configuration;
}

- (NSString *)IPForHost:(NSString *)host {
    return [_IPDic valueForKey:host];
}

@end


static NSString * const CustomURLProtocolPropertyKey = @"CustomURLProtocolPropertyKey";

#pragma mark - FYURLProtocol
@interface FYURLProtocol ()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@end

@implementation FYURLProtocol

+ (void)configureHostWithBlock:(void (^)(id<FYURLProtocolConfiguration>))configuration {
    configuration([FYURLProtocolConfiguration sharedConfiguration]);
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    //只处理http和https请求
    NSString *scheme = [[request URL] scheme];
    if([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame || [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame) {
        //看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:CustomURLProtocolPropertyKey inRequest:request]) {
            return NO;
        }
        
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    mutableReqeust = [self redirectHostInRequset:mutableReqeust];
    //打标签，防止无限循环
    [NSURLProtocol setProperty:@YES forKey:CustomURLProtocolPropertyKey inRequest:mutableReqeust];
    
    return mutableReqeust;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    NSURLSessionConfiguration *configuration = [FYURLProtocolConfiguration sharedConfiguration].sessionConfiguration;
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue new]];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:self.request];
    [task resume];
}

- (void)stopLoading {
    [self.session invalidateAndCancel];
    self.session = nil;
}

#pragma mark - Private methods
+ (NSMutableURLRequest*)redirectHostInRequset:(NSMutableURLRequest*)request {
    if ([request.URL host].length == 0) {
        return request;
    }
    
    NSString *originUrlString = [request.URL absoluteString];
    NSString *originHostString = [request.URL host];
    NSRange hostRange = [originUrlString rangeOfString:originHostString];
    if (hostRange.location == NSNotFound) {
        return request;
    }
    
    
    [request setValue:request.URL.host forHTTPHeaderField:@"Host"];
    NSString *ip = [[FYURLProtocolConfiguration sharedConfiguration] IPForHost:request.URL.host];
    
    // 替换host
    NSString *urlString = [originUrlString stringByReplacingCharactersInRange:hostRange withString:ip];
    NSURL *url = [NSURL URLWithString:urlString];
    request.URL = url;
    
    return request;
}

- (BOOL)validateCertficate:(SecTrustRef)serverTrust forDomain:(NSString *)domain {
    FYURLProtocolConfiguration *configuration = [FYURLProtocolConfiguration sharedConfiguration];
    if(configuration.SSLPinningMode == FYSSLPinningModeNone) {
        return YES;
    }else if(configuration.SSLPinningMode == FYSSLPinningModeCertficate) {
        // Get remote certificate
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        
        NSMutableArray *policies = [NSMutableArray array];
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
        SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
        
        // Evaluate server certificate
        SecTrustResultType result;
        SecTrustEvaluate(serverTrust, &result);
        BOOL certificateIsValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
        
        // Get local and remote cert data
        NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
        static NSData *localCertificate;
        if(!localCertificate) {
            localCertificate = [NSData dataWithContentsOfFile:configuration.certPath];
        }
        
        // The pinnning check
        if ([remoteCertificateData isEqualToData:localCertificate] && certificateIsValid) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {

    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if([self validateCertficate:challenge.protectionSpace.serverTrust forDomain:[self.request.allHTTPHeaderFields objectForKey:@"Host"]]) {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            if(credential) {
                disposition = NSURLSessionAuthChallengeUseCredential;
            }
        }else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    
    if(completionHandler) {
        completionHandler(disposition, credential);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error) {
        [self.client URLProtocol:self didFailWithError:error];
    }else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

@end

