//
//  WDBlendModePicker.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "NSArray+Additions.h"
#import "WDBlendModePicker.h"
#import "WDScrollView.h"
#import "WDUtilities.h"

const float kScrollViewHeight = 41;
const float kIndicatorBaseHeight = 48;
const float kPointDepth = 15;
const float kButtonOutset = 10.0f;

@interface WDBlendModePicker (Private)
- (void) buildIndicatorImage;
- (UIColor *) titleColor;
- (void) buildTitleButtons;
@end

@implementation WDBlendModePicker

@synthesize scrollView = scrollView_;
@synthesize target = target_;
@synthesize action = action_;
@synthesize titles = titles_;
@synthesize font = font_;
@synthesize buttonBounds = buttonBounds_;
@synthesize selectedIndex = selectedIndex_;
@synthesize indicatorImageView = indicatorImageView_;

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (!self) {
        return nil;
    }
    
    self.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1.0f];
    self.font = [UIFont systemFontOfSize:16];
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
    
    return self;
}


- (void) setFrame:(CGRect)frame
{        
    BOOL sizeChanged = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    [super setFrame:frame];
    
    if (sizeChanged || !indicatorImageView_) {
        [self buildIndicatorImage];
        
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

- (void) setTitles:(NSArray *)titles
{
    titles = [titles map:^id(id obj) {
        return [obj lowercaseString];
    }];
    
    titles_ = titles;
    
    if (titles_) {
        [self buildTitleButtons];
    }
}

- (void) chooseItemAtIndexSilent:(NSUInteger)index
{
    index = WDClamp(0, self.titles.count - 1, index);
    [scrollView_ setContentOffset:[self contentOffsetForIndex:index] animated:NO];
    self.selectedIndex = index;
}

- (void) chooseItemAtIndex:(NSUInteger)index
{
    [self chooseItemAtIndex:index animated:NO];
}

- (void) chooseItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    BOOL changed = (self.selectedIndex == index) ? NO : YES;
    
    index = WDClamp(0, self.titles.count - 1, index);
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
    CGPathMoveToPoint(pathRef, NULL, pathRect.origin.x, pathRect.origin.y);
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMaxX(pathRect), pathRect.origin.y);
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMaxX(pathRect), CGRectGetMaxY(pathRect));
    
    float pointDepth = kPointDepth - (0.5f / scale);
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMidX(pathRect) + pointDepth, CGRectGetMaxY(pathRect));
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMidX(pathRect), CGRectGetMaxY(pathRect) + pointDepth);
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMidX(pathRect) - pointDepth, CGRectGetMaxY(pathRect));
    
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMinX(pathRect), CGRectGetMaxY(pathRect));
    
    CGPathCloseSubpath(pathRef);
    
    [[UIColor colorWithWhite:0.975f alpha:1.0f] set];
    CGContextAddPath(ctx, pathRef);
    CGContextFillPath(ctx);
    
    CGContextAddPath(ctx, pathRef);
    [[UIColor grayColor] set];
    CGContextSetLineWidth(ctx, 1.0 / scale);
    CGContextStrokePath(ctx);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    indicatorImageView_ = [[UIImageView alloc] initWithImage:image];
    [self insertSubview:indicatorImageView_ atIndex:0];
    
    CGPathRelease(pathRef);
}

- (UIColor *) titleColor
{
    if (WDUseModernAppearance()) {
        return [UIColor colorWithRed:0 green:(118.0f / 255.0f) blue:1 alpha:1];
    } else {
        return [UIColor blackColor];
    }
}

- (void) buildTitleButtons
{
    // iterate through the strings and find the longest one
    float width, totalWidth = 0.0f;
    
    for (NSString *title in self.titles) {
        width = [title sizeWithFont:self.font].width;
        totalWidth += width + (kButtonOutset * 2);
    }
    
    scrollView_.contentSize = CGSizeMake(totalWidth, CGRectGetHeight(scrollView_.bounds));
    
    self.buttonBounds = [NSMutableArray array];
    
    // add buttons
    UIButton        *button;
    CGRect          buttonFrame = CGRectMake(0, 0, 0, CGRectGetHeight(scrollView_.bounds));
    NSUInteger      index = 0;
    
    for (NSString *title in self.titles) {
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonFrame.size.width = [title sizeWithFont:self.font].width + (kButtonOutset * 2);
        button.frame = buttonFrame;
        button.titleLabel.font = self.font;
        button.tag = index++;
        
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:[self titleColor] forState:UIControlStateNormal];
        
        [button addTarget:self action:@selector(scrollToItem:) forControlEvents:UIControlEventTouchUpInside];
        
        [scrollView_ addSubview:button];
        
        [self.buttonBounds addObject:[NSValue valueWithCGRect:buttonFrame]];
        
        buttonFrame.origin.x += buttonFrame.size.width;
    }
    
    NSValue *first = buttonBounds_[0];
    NSValue *last = [buttonBounds_ lastObject];
    scrollView_.contentInset = UIEdgeInsetsMake(0, CGRectGetMidX(self.bounds) - CGRectGetMidX([first CGRectValue]),
                                                0.0f, CGRectGetMidX(self.bounds) - CGRectGetWidth([last CGRectValue]) / 2.0f);
    
    [self chooseItemAtIndex:0];
}

@end
