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
}

- (IBAction)accept:(UIButton *)sender
{
}

- (void)previous
{

}

- (void)next
{

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
    if (_gists.count - _gistNumber < 1) {
        [[GithubAPI sharedGithubAPI] loadGistsSince:nil completion:^(NSArray *gists, NSError *error) {
            if (gists) {
                _gists = gists;
                [self.tableView reloadData];
            }
        }];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    NSUInteger row = indexPath.row / 2;
    if (indexPath.row & 1) {
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
