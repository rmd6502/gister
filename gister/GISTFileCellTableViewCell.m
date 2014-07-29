//
//  GISTFileCellTableViewCell.m
//  gister
//
//  Created by Robert Diamond on 7/28/14.
//  Copyright (c) 2014 Robert Diamond. All rights reserved.
//

#import "GISTFileCellTableViewCell.h"

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
    self.textView.text = @"Loading...";
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize mySz = CGSizeMake(self.bounds.size.width, 9999.0f);
    CGSize textSize = [self.textView.text boundingRectWithSize:mySz options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.textView.font} context:[NSStringDrawingContext new]].size;
    return CGSizeMake(textSize.width + 10.0f, textSize.height + 10.0f);
}

@end
