//
//  GithubAPI.m
//  gister
//
//  Created by Robert Diamond on 7/28/14.
//  Copyright (c) 2014 Robert Diamond. All rights reserved.
//

#import "GithubAPI.h"

@interface GithubAPI () <NSURLSessionTaskDelegate>

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSOperationQueue *bgQueue;

@end

@implementation GithubAPI

+ (GithubAPI *)sharedGithubAPI
{
    static GithubAPI *instance = nil;
    static dispatch_once_t once;

    if (instance == nil) dispatch_once(&once, ^{
        instance = [GithubAPI new];
    });

    return instance;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _bgQueue = [[NSOperationQueue alloc] init];
        _bgQueue.name = @"URLFetcher";
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForResource = 180.0f;
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_bgQueue];
    }

    return self;
}

- (void)loadGistsSince:(NSString *)sinceDate completion:(ArrayResponseBlock)completion
{
    NSMutableString *urlString = [@"https://api.github.com/gists/public" mutableCopy];
    if (sinceDate) {
        [urlString appendFormat:@"?since=%@",sinceDate];
    }
    ArrayResponseBlock mainThreadCompletion = [^(NSArray *array, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"error: %@", error);
            }
            completion(array, error);
        });
    } copy];
    [self _sendRequest:urlString withResponse:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil && ((NSHTTPURLResponse *)response).statusCode > 299) {
            NSString *description = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            error = [NSError errorWithDomain:@"Internal" code:((NSHTTPURLResponse *)response).statusCode userInfo:@{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"bad HTTP Status: %@", description]}];
        }
        if (error) {
            mainThreadCompletion(nil, error);
        } else {
            id dataObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                mainThreadCompletion(nil, error);
            } else {
                if (![dataObject isKindOfClass:[NSArray class]]) {
                    mainThreadCompletion(nil, [NSError errorWithDomain:@"Internal" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Did not return an array"}]);
                } else {
                    mainThreadCompletion((NSArray *)dataObject, nil);
                }
            }
        }
    }];
}

- (void)loadGistFile:(NSString *)fileURL completion:(StringResponseBlock)completion
{
    StringResponseBlock mainThreadCompletion = [^(NSString *string, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(string, error);
        });
    } copy];

    [self _sendRequest:fileURL withResponse:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *stringResponse = nil;
        if (data) {
            stringResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        if (error) {
            mainThreadCompletion(stringResponse, error);
        } else if (((NSHTTPURLResponse *)response).statusCode > 299) {
            mainThreadCompletion(stringResponse, [NSError errorWithDomain:@"Internal" code:((NSHTTPURLResponse *)response).statusCode userInfo:@{NSLocalizedFailureReasonErrorKey: @"Invalid HTTP response code"}]);
        } else {
            mainThreadCompletion(stringResponse, nil);
        }
    }];
}

- (void)_sendRequest:(NSString *)url withResponse:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
            [request setValue:@"close" forHTTPHeaderField:@"Connection"];
            [[strongSelf.session dataTaskWithRequest:request completionHandler:completionHandler] resume];
        }
    });

}

@end
