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
@end

@implementation ViewController
- (IBAction)reject:(UIButton *)sender
{
    ++_gistNumber;
    [self _reloadIfNecessaryWithCompletion:^(NSArray *gists, NSError *error) {
        if (gists) {
            _gists = [gists arrayByAddingObjectsFromArray:_gists];
        }
        [UIView transitionWithView:self.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromLeft) animations:^{
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }];
    }];
}

- (IBAction)accept:(UIButton *)sender
{
    ++_gistNumber;
    [self _reloadIfNecessaryWithCompletion:^(NSArray *gists, NSError *error) {
        if (gists) {
            _gists = [gists arrayByAddingObjectsFromArray:_gists];
        }
        [UIView transitionWithView:self.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromRight) animations:^{
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
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
    [self _reloadIfNecessaryWithCompletion:^(NSArray *gists, NSError *error) {
        if (gists) {
            _gists = [gists arrayByAddingObjectsFromArray:_gists];
        }
        [UIView transitionWithView:self.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromBottom) animations:^{
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _reloadIfNecessary];
}

typedef void (^CompletionBlock)(NSArray *gists, NSError *error);

- (void)_reloadIfNecessary
{
    [self _reloadIfNecessaryWithCompletion:^(NSArray *gists, NSError *error) {
        if (gists) {
            _gists = [gists arrayByAddingObjectsFromArray:_gists];
        }
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
        [[GithubAPI sharedGithubAPI] loadGistsSince:sinceDate completion:completion];
    } else {
        completion(nil,nil);
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
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row == 0) ? 22.0f : CGRectGetHeight(tableView.bounds) - 32.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    NSUInteger row = indexPath.section;
    if (indexPath.row == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"gistFile"];
        ((GISTFileCellTableViewCell *)cell).fileURL = _gists[_gistNumber][@"files"][[_gists[_gistNumber][@"files"] allKeys][row]][@"raw_url"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"gistTitle"];
        cell.textLabel.text = [_gists[_gistNumber][@"files"] allKeys][row];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
