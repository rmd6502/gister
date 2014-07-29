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
@property (nonatomic) NSMutableDictionary *gistCache;
@end

@implementation ViewController
- (IBAction)reject:(UIButton *)sender
{
    ++self.gistNumber;
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
    ++self.gistNumber;
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
        --self.gistNumber;
        [UIView transitionWithView:self.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromTop) animations:^{
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)next
{
    ++self.gistNumber;
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
            [self _updateGist];
            completion(error);
        }];
    } else {
        completion(nil);
    }
}

- (void)setGistNumber:(NSUInteger)gistNumber
{
    if (_gistNumber != gistNumber) {
        _gistNumber = gistNumber;
        [self _updateGist];
    }
}

- (void)_updateGist
{
    if (_gists.count > _gistNumber) {
        _gistFiles = [[((NSDictionary *)_gists[_gistNumber])[@"files"] allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSString *)obj1 compare:(NSString *)obj2];
        }];
        GithubAPI *githubAPI = [GithubAPI sharedGithubAPI];
        NSDictionary *currentGistFiles = _gists[_gistNumber][@"files"];
        _gistCache = [NSMutableDictionary new];
        __weak typeof(self) weakSelf = self;
        NSUInteger section = 0;
        for (NSString *file in _gistFiles) {
            [githubAPI loadGistFile:((NSDictionary *)currentGistFiles[file])[@"raw_url"] completion:^(NSString *data, NSError *error) {
                typeof(self) strongSelf = weakSelf;
                if (strongSelf) {
                    strongSelf.gistCache[file] = data;
                    [strongSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }];
            ++section;
        }
    } else {
        _gistFiles = nil;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *text = _gistCache[_gistFiles[indexPath.section]];
    if (_gistFiles.count > indexPath.section && text.length) {
        return [text boundingRectWithSize:CGSizeMake(tableView.bounds.size.width, 9999.0f) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Helvetica Neue" size:12.0f]} context:[NSStringDrawingContext new]].size.height;
    }

    return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GISTFileCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"gistFile"];
    if (_gistFiles.count > indexPath.section) {
        if (_gistCache[_gistFiles[indexPath.section]]) {
            cell.textView.text = _gistCache[_gistFiles[indexPath.section]];
        }
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
