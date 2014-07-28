//
//  GithubAPI.h
//  gister
//
//  Created by Robert Diamond on 7/28/14.
//  Copyright (c) 2014 Robert Diamond. All rights reserved.
//

typedef void(^ArrayResponseBlock)(NSArray *,NSError *);
typedef void(^StringResponseBlock)(NSString *,NSError *);

@interface GithubAPI : NSObject

+ (GithubAPI *)sharedGithubAPI;
- (void)loadGistsSince:(NSDate *)sinceDate completion:(ArrayResponseBlock)completion;
- (void)loadGistFile:(NSString *)fileURL completion:(StringResponseBlock)completion;

@end
