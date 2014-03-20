//
//  WDStampPicker.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDStampPicker.h"
#import "WDScrollView.h"
#import "WDUtilities.h"

#define kScrollViewHeight       80
#define kIndicatorBaseHeight    100
#define kPointDepth             15
#define kButtonOutset           10.0f

@interface  WDStampPicker ()
@property (nonatomic) NSMutableArray *buttons;
@end

@interface WDStampPicker (Private)
- (void) buildIndicatorImage;
- (void) configureLayer;
- (void) buildImageButtons;
@end

@implementation WDStampPicker

@synthesize buttons = buttons_;
@synthesize scrollView = scrollView_;
@synthesize target = target_;
@synthesize action = action_;
@synthesize images = images_;
@synthesize buttonBounds = buttonBounds_;
@synthesize selectedIndex = selectedIndex_;
@synthesize indicatorImageView = indicatorImageView_;

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (!self) {
        return nil;
    }

    [self configureLayer];
    
    self.selectedIndex = -1;
    
    CGRect frame = self.bounds;
    frame.size.height = kScrollViewHeight;
    frame.origin.y = CGRectGetHeight(self.bounds) - frame.size.height;
	scrollView_ = [[WDScrollView alloc] initWithFrame:frame];
    scrollView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	scrollView_.backgroundColor = nil;
    scrollView_.opaque = NO;
    scrollView_.showsHorizontalScrollIndicator = NO;
    scrollView_.delegate = self;
	[self insertSubview:scrollView_ atIndex:0];
    
    // add an edge along the bottom
    frame = self.bounds;
    frame.origin.y = CGRectGetMaxY(frame) - 1 / [UIScreen mainScreen].scale;
    frame.size.height = 1 / [UIScreen mainScreen].scale;
    UIView *edge = [[UIView alloc] initWithFrame:frame];
    edge.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    edge.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:edge];
    
    return self;
}

- (void) setFrame:(CGRect)frame
{        
    BOOL sizeChanged = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    [super setFrame:frame];
    
    if (sizeChanged || !indicatorImageView_) {
        [self buildIndicatorImage];
        [self configureLayer];
        
        NSValue *first = buttonBounds_[0];
        NSValue *last = [buttonBounds_ lastObject];
        scrollView_.contentInset = UIEdgeInsetsMake(0, CGRectGetMidX(self.bounds) - CGRectGetMidX([first CGRectValue]),
                                                    0.0f, CGRectGetMidX(self.bounds) - CGRectGetWidth([last CGRectValue]) / 2.0f);
        
        [scrollView_ setContentOffset:[self contentOffsetForIndex:self.selectedIndex] animated:NO];
    }
}


- (CGPoint) contentOffsetForIndex:(NSUInteger)index
{
    NSValue *value = (self.buttonBounds)[index];
    float   newX = WDCenterOfRect([value CGRectValue]).x;
    
    float inset = CGRectGetMidX(self.bounds) - [buttonBounds_[0] CGRectValue].origin.x;
    newX -= inset;
    
    return  CGPointMake(newX, 0);
}

- (void) setImages:(NSArray *)images
{
    images_ = images;
    
    if (images_) {
        [self buildImageButtons];
    }
}

- (void) chooseItemAtIndex:(NSUInteger)index
{
    [self chooseItemAtIndex:index animated:NO];
}

- (void) chooseItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    BOOL changed = (self.selectedIndex == index) ? NO : YES;
    
    index = WDClamp(0, self.images.count - 1, index);
    [scrollView_ setContentOffset:[self contentOffsetForIndex:index] animated:animated];
    
    if (changed) {
        self.selectedIndex = index;
        [[UIApplication sharedApplication] sendAction:self.action to:self.target from:self forEvent:nil];
    }
}

- (void) scrollToItem:(id)sender
{
    [self chooseItemAtIndex:((UIView *)sender).tag animated:YES];
}

- (void) snapToItem
{
    float   x = scrollView_.contentOffset.x;
    float   inset = CGRectGetMidX(self.bounds) - [buttonBounds_[0] CGRectValue].origin.x;
    
    x += inset;
    
    for (int i = 0; i < self.buttonBounds.count; i++) {
        NSValue *value = (self.buttonBounds)[i];
        CGRect rect = value.CGRectValue;
        if (CGRectContainsPoint(rect, CGPointMake(x, CGRectGetMidY(rect)))) {
            [self chooseItemAtIndex:i animated:YES];
            return;
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self snapToItem];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self snapToItem];
}

#pragma mark -
#pragma mark View Building Stuff

- (void) buildIndicatorImage
{
    if (indicatorImageView_) {
        [indicatorImageView_ removeFromSuperview];
    }
    
    float scale = [UIScreen mainScreen].scale;
    
    CGRect frame = self.bounds;
    frame.size.height = kIndicatorBaseHeight;
    
    CGRect expandedFrame = frame;
    expandedFrame.size.height += kPointDepth + 10;
    
    UIGraphicsBeginImageContextWithOptions(expandedFrame.size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGRect pathRect = CGRectOffset(CGRectIntegral(CGRectInset(frame, -20, 0)), 0, 0.5f / scale);
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathMoveToPoint(pathRef, NULL, pathRect.origin.x, pathRect.origin.y - 1);
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMaxX(pathRect), pathRect.origin.y - 1);
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMaxX(pathRect), CGRectGetMaxY(pathRect));
    
    float pointDepth = kPointDepth - 0.5f / scale;
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMidX(pathRect) + pointDepth, CGRectGetMaxY(pathRect));
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMidX(pathRect), CGRectGetMaxY(pathRect) + pointDepth);
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMidX(pathRect) - pointDepth, CGRectGetMaxY(pathRect));
    
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMinX(pathRect), CGRectGetMaxY(pathRect));
    
    CGPathCloseSubpath(pathRef);
    
    [[UIColor colorWithWhite:1.0 alpha:1] set];
    CGContextAddPath(ctx, pathRef);
    CGContextFillPath(ctx);
    
    CGContextAddPath(ctx, pathRef);
    [[UIColor grayColor] set];
    CGContextSetLineWidth(ctx, 1 / scale);
    CGContextStrokePath(ctx);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    indicatorImageView_ = [[UIImageView alloc] initWithImage:image];
    [self insertSubview:indicatorImageView_ atIndex:1];
    
    CGPathRelease(pathRef);
}

- (void) configureLayer
{
    self.backgroundColor = [UIColor colorWithWhite:0.9764f alpha:1];
}

- (void) buildImageButtons
{
    // iterate through the strings and find the longest one
    float   totalWidth = 0.0f;
    
    for (UIImage *image in self.images) {
        totalWidth += image.size.width + (kButtonOutset * 2);
    }
    
    scrollView_.contentSize = CGSizeMake(totalWidth, CGRectGetHeight(scrollView_.bounds));
    
    self.buttonBounds = [NSMutableArray array];
    self.buttons = [NSMutableArray array];
    
    // add buttons
    UIButton        *button;
    CGRect          buttonFrame = CGRectMake(0, 0, 0, CGRectGetHeight(scrollView_.bounds));
    NSUInteger      index = 0;
    
    for (UIImage *image in self.images) {
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonFrame.size.width = image.size.width + (kButtonOutset * 2);
        [button setImage:image forState:UIControlStateNormal];
        button.frame = buttonFrame;
        button.tag = index++;
        
//        button.layer.shadowRadius = 0;
//        button.layer.shadowOpacity = 1;
//        button.layer.shadowOffset = CGSizeMake(0,1);
//        button.layer.shadowColor = [UIColor whiteColor].CGColor;
        
        [button addTarget:self action:@selector(scrollToItem:) forControlEvents:UIControlEventTouchUpInside];
        
        [scrollView_ addSubview:button];
        
        [self.buttonBounds addObject:[NSValue valueWithCGRect:buttonFrame]];
        [self.buttons addObject:button];
        
        buttonFrame.origin.x += buttonFrame.size.width;
    }
    
    NSValue *first = buttonBounds_[0];
    NSValue *last = [buttonBounds_ lastObject];
    scrollView_.contentInset = UIEdgeInsetsMake(0, CGRectGetMidX(self.bounds) - CGRectGetMidX([first CGRectValue]),
                                                0.0f, CGRectGetMidX(self.bounds) - CGRectGetWidth([last CGRectValue]) / 2.0f);
    
    [self chooseItemAtIndex:0];
}

- (void) setImage:(UIImage *)image forIndex:(NSUInteger)ix
{
    [buttons_[ix] setImage:image forState:UIControlStateNormal];
}

@end
