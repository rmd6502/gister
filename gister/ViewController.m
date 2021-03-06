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
    __weak typeof(self) weakSelf = self;
    [self _reloadIfNecessaryWithCompletion:^(NSError *error) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf.gists.count || !strongSelf) {
            return;
        }
        [UIView transitionWithView:strongSelf.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromLeft) animations:^{
            [strongSelf.tableView reloadData];
        } completion:^(BOOL finished) {
            if (strongSelf.gists.count > strongSelf.gistNumber) {
                [strongSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }];
    }];
}

- (IBAction)accept:(UIButton *)sender
{
    ++self.gistNumber;
    __weak typeof(self) weakSelf = self;
    [self _reloadIfNecessaryWithCompletion:^(NSError *error) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf.gists.count || !strongSelf) {
            return;
        }
        [UIView transitionWithView:strongSelf.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromRight) animations:^{
            [strongSelf.tableView reloadData];
        } completion:^(BOOL finished) {
            if (strongSelf.gists.count > strongSelf.gistNumber) {
                [strongSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
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
    __weak typeof(self) weakSelf = self;
    [self _reloadIfNecessaryWithCompletion:^(NSError *error) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf.gists.count || !strongSelf) {
            return;
        }
        [UIView transitionWithView:strongSelf.view duration:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromBottom) animations:^{
            [strongSelf.tableView reloadData];
        } completion:^(BOOL finished) {
            if (strongSelf.gists.count) {
                [strongSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }];
    }];
}
- (IBAction)swipeRejectOrAccept:(UISwipeGestureRecognizer *)sender
{
    switch (sender.direction) {
        case UISwipeGestureRecognizerDirectionRight:
            [self reject:nil];
            break;
        case UISwipeGestureRecognizerDirectionLeft:
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
            
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _reloadIfNecessary];
}

typedef void (^CompletionBlock)(NSError *error);

- (void)_reloadIfNecessary
{
    __weak typeof(self) weakSelf = self;
    [self _reloadIfNecessaryWithCompletion:^(NSError *error) {
        [weakSelf.tableView reloadData];
    }];
}

- (void)_reloadIfNecessaryWithCompletion:(CompletionBlock)completion
{
    NSString *sinceDate = nil;
    if (_gists.count - _gistNumber < 1) {
        if (_gists.count) {
            sinceDate = ((NSDictionary *)_gists[0])[@"updated_at"];
        }
        __weak typeof(self) weakSelf = self;
        [[GithubAPI sharedGithubAPI] loadGistsSince:sinceDate completion:^(NSArray *gists, NSError *error) {
            typeof(self) strongSelf = weakSelf;
            if (strongSelf) {
                if (error) {
                    [[[UIAlertView alloc] initWithTitle:@"Problem" message:error.localizedDescription delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil] show];
                }
                NSUInteger startIndex = 0;
                while (strongSelf.gists.count && startIndex < gists.count) {
                    if ([strongSelf.gists indexOfObject:gists[startIndex]] == NSNotFound) {
                        break;
                    } else {
                        ++startIndex;
                    }
                }
                if (gists.count > startIndex) {
                    strongSelf.gists = [[gists subarrayWithRange:NSMakeRange(startIndex, gists.count-startIndex)] arrayByAddingObjectsFromArray:strongSelf.gists];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"No More!" message:@"You've reached the end!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil] show];
                }
                [strongSelf _updateGist];
                completion(error);
            }
        }];
    } else {
        completion(nil);
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self _reloadIfNecessary];
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
        return _gistFiles.count;
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
    return 33.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *text = _gistCache[_gistFiles[indexPath.section]];
    if (_gistFiles.count > indexPath.section && text.length) {
        return [text boundingRectWithSize:CGSizeMake(tableView.bounds.size.width, 9999.0f) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [self _textFont]} context:[NSStringDrawingContext new]].size.height;
    }

    return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GISTFileCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"gistFile"];
    cell.textView.font = [self _textFont];
    if (_gistFiles.count > indexPath.section) {
        if (_gistCache[_gistFiles[indexPath.section]]) {
            cell.textView.text = _gistCache[_gistFiles[indexPath.section]];
        }
    }

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *ret = [UIView new];
    ret.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UILabel *label = [UILabel new];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 2;
    label.font = [self _sectionHeaderFont];
    label.text = _gistFiles[section];
    [label sizeToFit];
    ret.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:.95];
    [ret addSubview:label];
    label.frame = CGRectMake(5, 1, label.bounds.size.width-10, label.bounds.size.height);
    [ret sizeToFit];
    return ret;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [_gistFiles[section] boundingRectWithSize:CGSizeMake(tableView.bounds.size.width - 10.0f, 9999.0f) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [self _sectionHeaderFont]} context:[NSStringDrawingContext new]].size.height + 6.0f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIFont *)_sectionHeaderFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Thin" size:14.0f];
}

- (UIFont *)_textFont
{
    return [UIFont fontWithName:@"Menlo-Regular" size:8.0f];
}

@end
