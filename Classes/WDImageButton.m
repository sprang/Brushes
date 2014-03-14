//
//  WDImageButton.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDImageButton.h"
#import "UIImage+Additions.h"
#import "UIView+Additions.h"

@implementation WDImageButton

@synthesize marked;
@synthesize markView;

+ (WDImageButton *) imageButtonWithImage:(UIImage *)image;
{
    WDImageButton *imageButton = [WDImageButton buttonWithType:UIButtonTypeCustom];
    
    [imageButton setImage:image forState:UIControlStateNormal];
    [imageButton sizeToFit];
    
    return imageButton;
}

- (void) setMarked:(BOOL)inMarked
{
    if (marked == inMarked) {
        return;
    }
    
    marked = inMarked;
    
    if (!marked) {
        [markView removeFromSuperview];
        markView = nil;
    } else {
        if (!markView) {
            UIImage *checkmark = [UIImage relevantImageNamed:@"checkmark.png"];
            markView = [[UIImageView alloc] initWithImage:checkmark];
            [self addSubview:markView];
        }
        
        CGPoint center = CGPointMake(CGRectGetMaxX(self.bounds) - 12, CGRectGetMaxY(self.bounds) - 12);
        markView.sharpCenter = center;
    }
}

@end
