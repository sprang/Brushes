//
//  WDBrushSizeOverlay.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDBrushSizeOverlay.h"

@implementation WDBrushSizeOverlay

@synthesize title;
@synthesize value;
@synthesize preview;

- (CGRect) squareBounds
{
    CGRect square = self.bounds;
    square.size.height = square.size.width;
    
    return square;
}

- (void) configureTitle
{
    CGRect square = [self squareBounds];
    CGRect frame = square;
    
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = nil;
    label.opaque = NO;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:19.0f];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = UITextAlignmentCenter;
    label.text = @"512 px";
    label.shadowColor = [UIColor blackColor];
    label.shadowOffset = CGSizeMake(0, 1);

    [label sizeToFit];
    frame = label.frame;
    frame.size.width = CGRectGetWidth(square);
    frame.origin.y = 10;
    label.frame = frame;
    
    [self addSubview:label];
    self.title = label;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.opaque = NO;
    self.backgroundColor = nil;
    
    [self configureTitle];
    
    return self;
}

- (void) setValue:(float)inValue
{
    value = inValue;
    
    title.text = [NSString stringWithFormat:NSLocalizedString(@"%d px", @"%d px"), (int)value];
    
    float percentage = 0.05f + (value / 512.0f) * 0.95;
    preview.transform = CGAffineTransformMakeScale(percentage, percentage);
}

- (void) setPreviewImage:(UIImage *)image
{
    CGRect square = [self squareBounds];
  
    if (!preview) {
        preview = [[UIImageView alloc] initWithImage:image];
        preview.frame = CGRectInset(square, 30, 30);
        [preview.layer setMinificationFilter:kCAFilterTrilinear];
        
        [self addSubview:preview];
    } else {
        preview.image = image;
    }
}

- (void)drawRect:(CGRect)rect
{    
    CGRect square = [self squareBounds];
    float heightDelta = CGRectGetHeight(self.bounds) - CGRectGetHeight(square);
    
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:square cornerRadius:11];
    
    if (heightDelta > 0.0f) {
        float dimension = heightDelta / M_SQRT2 * 2;
        UIBezierPath *point = [UIBezierPath bezierPathWithRect:CGRectMake(-dimension / 2, -dimension / 2, dimension, dimension)];
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformTranslate(transform, CGRectGetMidX(self.bounds), CGRectGetHeight(square));
        transform = CGAffineTransformRotate(transform, M_PI_4);
        [point applyTransform:transform];
                              
        [roundedRect appendPath:point];
    }
    
    [[UIColor colorWithWhite:0.0f alpha:0.5f] set];
    [roundedRect fill];
}

@end
