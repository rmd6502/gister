//
//  GISTFileCellTableViewCell.m
//  gister
//
//  Created by Robert Diamond on 7/28/14.
//  Copyright (c) 2014 Robert Diamond. All rights reserved.
//

#import "GISTFileCellTableViewCell.h"
#import "GithubAPI.h"

@interface GISTFileCellTableViewCell ()
@property (nonatomic) IBOutlet UITextView *textView;
@end

@implementation GISTFileCellTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    self.fileURL = nil;
}

- (void)setFileURL:(NSString *)fileURL
{
    if (_fileURL != fileURL) {
        _fileURL = [fileURL copy];
        if (_fileURL) {
            [[GithubAPI sharedGithubAPI] loadGistFile:_fileURL completion:^(NSString *string, NSError *error) {
                if (!error) {
                    _textView.text = string;
                }
            }];
        } else {
            _textView.text = nil;
        }
    }
}

@end
