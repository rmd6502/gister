//
//  ViewController.m
//  gister
//
//  Created by Robert Diamond on 7/28/14.
//  Copyright (c) 2014 Robert Diamond. All rights reserved.
//

#import "GISTFileCellTableViewCell.h"
#import "GithubAPI.h"
#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) NSArray *gists;
@property (nonatomic) NSArray *gistFiles;
@property (nonatomic) NSDictionary *gistCache;
@end

@implementation ViewController
- (IBAction)reject:(UIButton *)sender
{
    ++_gistNumber;
    [self _reloadIfNecessaryWithCompletion:^(NSError *error) {
        if (!_gists.count) {
            return;
        }
        [UIView transitionWithView:self.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromLeft) animations:^{
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
            if (_gists.count) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }];
    }];
}

- (IBAction)accept:(UIButton *)sender
{
    ++_gistNumber;
    [self _reloadIfNecessaryWithCompletion:^(NSError *error) {
        if (!_gists.count) {
            return;
        }
        [UIView transitionWithView:self.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromRight) animations:^{
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
            if (_gists.count) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }];
    }];
}

- (void)previous
{
    if (_gistNumber > 0) {
        --_gistNumber;
        [UIView transitionWithView:self.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromTop) animations:^{
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)next
{
    ++_gistNumber;
    [self _reloadIfNecessaryWithCompletion:^(NSError *error) {
        if (!_gists.count) {
            return;
        }
        [UIView transitionWithView:self.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromBottom) animations:^{
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
            if (_gists.count) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }];
    }];
}
- (IBAction)swipeRejectOrAccept:(UISwipeGestureRecognizer *)sender
{
    switch (sender.direction) {
        case UISwipeGestureRecognizerDirectionLeft:
            [self reject:nil];
            break;
        case UISwipeGestureRecognizerDirectionRight:
            [self accept:nil];
            break;
        case UISwipeGestureRecognizerDirectionUp:
            [self next];
            break;
        case UISwipeGestureRecognizerDirectionDown:
            [self previous];
            break;
        default:
            break;
    }
}
            
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setNeedsUpdateConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _reloadIfNecessary];
}

typedef void (^CompletionBlock)(NSError *error);

- (void)_reloadIfNecessary
{
    [self _reloadIfNecessaryWithCompletion:^(NSError *error) {
        [self.tableView reloadData];
    }];
}

- (void)_reloadIfNecessaryWithCompletion:(CompletionBlock)completion
{
    NSString *sinceDate = nil;
    if (_gists.count - _gistNumber < 1) {
        if (_gists.count) {
            sinceDate = ((NSDictionary *)_gists[0])[@"updated_at"];
        }
        [[GithubAPI sharedGithubAPI] loadGistsSince:sinceDate completion:^(NSArray *gists, NSError *error) {
            if (gists) {
                _gists = [gists arrayByAddingObjectsFromArray:_gists];
            }
            if (_gists.count > _gistNumber) {
                _gistFiles = [((NSDictionary *)_gists[_gistNumber])[@"files"] allKeys];
            } else {
                _gistFiles = nil;
            }
            completion(error);
        }];
    } else {
        if (_gists.count > _gistNumber) {
            _gistFiles = [((NSDictionary *)_gists[_gistNumber])[@"files"] allKeys];
        } else {
            _gistFiles = nil;
        }
        completion(nil);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_gistNumber < _gists.count) {
        return ((NSDictionary *)_gists[_gistNumber][@"files"]).count;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CGRectGetHeight(tableView.bounds) - 10.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GISTFileCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"gistFile"];
    if (_gistFiles.count > indexPath.section) {
        cell.textView.text = _gists[_gistNumber][@"files"][_gistFiles[indexPath.section]][@"raw_url"];
    }

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [UILabel new];
    label.text = [_gists[_gistNumber][@"files"] allKeys][section];
    return label;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 22.0f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
