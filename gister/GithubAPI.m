//
//  GithubAPI.m
//  gister
//
//  Created by Robert Diamond on 7/28/14.
//  Copyright (c) 2014 Robert Diamond. All rights reserved.
//

#import "GithubAPI.h"

@interface GithubAPI () <NSURLSessionDelegate>

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSOperationQueue *bgQueue;
@property (nonatomic) dispatch_queue_t bgDispatchQueue;

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
        _bgDispatchQueue = dispatch_queue_create("URLFetcher", 0);
        _bgQueue = [[NSOperationQueue alloc] init];
        _bgQueue.underlyingQueue = _bgDispatchQueue;
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForResource = 180.0f;
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_bgQueue];
    }

    return self;
}

- (void)loadGistsSince:(NSDate *)sinceDate completion:(ArrayResponseBlock)completion
{
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [NSDateFormatter new];
        formatter.dateFormat = @"YYYY-MM-DDTHH:MM:SSZ";
    }
    NSMutableString *urlString = [@"https://api.github.com/gists/public" mutableCopy];
    if (sinceDate) {
        [urlString appendFormat:@"?since=%@",[formatter stringFromDate:sinceDate]];
    }
    ArrayResponseBlock mainThreadCompletion = [^(NSArray *array, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
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
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [[_session dataTaskWithRequest:request completionHandler:completionHandler] resume];
}
@end
