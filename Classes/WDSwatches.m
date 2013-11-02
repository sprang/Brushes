//
//  WDSwatches.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import "WDActiveState.h"
#import "WDSwatches.h"
#import "WDColor.h"
#import "WDUtilities.h"

const float kSwatchCornerRadius = 5.0f;
const float kSwatchSize = 45.0f;

@implementation WDSwatches

@synthesize delegate = delegate_;
@synthesize highlightIndex = highlightIndex_;
@synthesize initialIndex = initialIndex_;
@synthesize highlightColor = highlightColor_;
@synthesize tappedColor = tappedColor_;
@synthesize shadowOverlay;

- (void) buildInsetShadowView
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
    
    CGRect         swatchRect = CGRectMake(0,0,kSwatchSize,kSwatchSize);
    NSInteger      swatchesPerRow = [self swatchesPerRow];
    NSInteger      numRows = [self numRows];
    
    // build the shadow image once
    UIGraphicsBeginImageContextWithOptions(swatchRect.size, NO, 0.0f);
    [self insetCircleInRect:CGRectInset(swatchRect, 3, 3)];
    
    // white border
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(swatchRect, 2.5f, 2.5f)
                                                    cornerRadius:kSwatchCornerRadius];
    [[UIColor whiteColor] set];
    path.lineWidth = 1.0f;
    [path stroke];
    
    UIImage *shadow = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // now stamp the shadow image for each swatch
    for (int y = 0; y < numRows; y++) {
        swatchRect.origin.y = y * kSwatchSize;
        for (int x = 0; x < swatchesPerRow; x++) {
            swatchRect.origin.x = x * kSwatchSize;
            [shadow drawInRect:swatchRect];
        }
    }
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    shadowOverlay = [[UIImageView alloc] initWithImage:result];
    [self addSubview:shadowOverlay];
}

- (void) setFrame:(CGRect)frame
{
    BOOL sizeChanged = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    [super setFrame:frame];
    
    if (sizeChanged || !self.shadowOverlay) {
        [shadowOverlay removeFromSuperview];
        shadowOverlay = nil;
        
        [self buildInsetShadowView];
    }
}

- (void) awakeFromNib
{
    highlightIndex_ = -1;
    initialIndex_ = -1;
    
    self.opaque = NO;
    self.backgroundColor = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }

    [self awakeFromNib];
    
    return self;
}

- (void) insetCircleInRect:(CGRect)rect
{
    CGContextRef    ctx = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(ctx);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:kSwatchCornerRadius];
    [path addClip];
    
    CGContextSetShadow(ctx, CGSizeMake(0,2), 8);
    CGContextAddRect(ctx, CGRectInset(rect, -8, -8));
    
    path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, -1, -1) cornerRadius:kSwatchCornerRadius];
    path.usesEvenOddFillRule = YES;
    [path fill];
    CGContextRestoreGState(ctx);
}

- (void) drawSwatchInRect:(CGRect)rect color:(WDColor *)color
{
    if (!color) {
        UIImage *image = [UIImage imageNamed:@"swatch_add.png"];
        CGPoint corner = rect.origin;
        corner.x += ceilf((CGRectGetWidth(rect) - image.size.width) / 2.0f);
        corner.y += ceilf((CGRectGetHeight(rect) - image.size.height) / 2.0f);
        [image drawAtPoint:corner blendMode:kCGBlendModeNormal alpha:0.2f];
    } else {
        [color set];
        
        CGRect colorRect = CGRectInset(rect, 3, 3);
        
        if (color.alpha < 1.0) {
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:colorRect cornerRadius:kSwatchCornerRadius];
            
            CGContextSaveGState(ctx);
            [path addClip];
            WDDrawTransparencyDiamondInRect(ctx, rect);
            CGContextRestoreGState(ctx);
        }
        
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:colorRect cornerRadius:kSwatchCornerRadius];
        [path fill];
    }
}

- (NSInteger) swatchesPerRow
{
    return CGRectGetWidth(self.bounds) / kSwatchSize;
}

- (NSInteger) numRows
{
    return CGRectGetHeight(self.bounds) / kSwatchSize;
}

- (void)drawRect:(CGRect)rect
{
    CGRect          swatch = CGRectMake(0,0,kSwatchSize,kSwatchSize);
    NSUInteger      index = 0;
    WDColor         *swatchColor;
    NSUInteger      swatchesPerRow = [self swatchesPerRow];
    NSUInteger      numRows = [self numRows];
    
    for (int y = 0; y < numRows; y++) {
        swatch.origin.y = y * kSwatchSize;
        
        for (int x = 0; x < swatchesPerRow; x++) {
            swatch.origin.x = x * kSwatchSize;
            
            if (CGRectIntersectsRect(swatch, rect)) {
                swatchColor = [[WDActiveState sharedInstance] swatchAtIndex:index];
                
                if (index == initialIndex_) {
                    swatchColor = nil;
                }
                
                if (index == highlightIndex_) {
                    swatchColor = highlightColor_;
                }
                
                [self drawSwatchInRect:swatch color:swatchColor];
            }

			index++;
        }
    }
}

- (CGRect) rectForSwatchIndex:(NSInteger)index
{
	NSUInteger x = index % [self swatchesPerRow];
	NSUInteger y = index / [self swatchesPerRow];
	
	return CGRectMake(x * kSwatchSize, y * kSwatchSize, kSwatchSize, kSwatchSize);
}

- (void) setHighlightIndex:(NSInteger)index
{
	if (index == highlightIndex_) {
		return;
	}
	
    [self setNeedsDisplayInRect:[self rectForSwatchIndex:highlightIndex_]];
	highlightIndex_ = index;
    [self setNeedsDisplayInRect:[self rectForSwatchIndex:highlightIndex_]];
	
}

- (void)dragMoved:(UITouch *)touch colorChip:(WDDragChip *)chip colorSource:(id)colorSource 
{
    CGPoint pt = [touch locationInView:self];

    if (!CGRectContainsPoint(self.bounds, pt)) {
        self.highlightIndex = -1;
        self.highlightColor = nil;
    } else {
        self.highlightIndex = [self indexAtPoint:pt];
        self.highlightColor = chip.color;
    }
    
    [self setNeedsDisplayInRect:[self rectForSwatchIndex:highlightIndex_]];
}

- (void) dragExited
{
    [self setNeedsDisplayInRect:[self rectForSwatchIndex:highlightIndex_]];
    self.highlightIndex = -1;
    self.highlightColor = nil;
}

- (void) dragEnded
{
    [self setNeedsDisplayInRect:[self rectForSwatchIndex:initialIndex_]];
    initialIndex_ = -1;
}

- (BOOL) dragEnded:(UITouch *)touch colorChip:(WDDragChip *)chip colorSource:(id)colorSource destination:(CGPoint *)flyLoc
{
    CGPoint pt = [touch locationInView:self];

    self.highlightIndex = -1;
    self.highlightColor = nil;
    
    if (!CGRectContainsPoint(self.bounds, pt)) {
        return NO;
    }
    
    if (initialIndex_ >= 0) {
        [[WDActiveState sharedInstance] setSwatch:nil atIndex:initialIndex_];
        [self setNeedsDisplayInRect:[self rectForSwatchIndex:initialIndex_]];
    }
    
    NSInteger index = [self indexAtPoint:pt];

    *flyLoc = [self convertPoint:WDCenterOfRect([self rectForSwatchIndex:index]) toView:chip.superview];
    
    [[WDActiveState sharedInstance] setSwatch:[chip color] atIndex:index];

    [self setNeedsDisplayInRect:[self rectForSwatchIndex:index]];
    
    return YES;
}

- (WDColor *) color
{
    return self.tappedColor;
}

- (NSInteger) indexAtPoint:(CGPoint)pt
{
    NSInteger x = ((int) pt.x) / kSwatchSize, y = ((int) pt.y) / kSwatchSize;
    return (y * [self swatchesPerRow] + x);
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    initialIndex_ = [self indexAtPoint:[touch locationInView:self]];
    self.tappedColor = [[WDActiveState sharedInstance] swatchAtIndex:initialIndex_];
	
    [super touchesBegan:touches withEvent:event];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setNeedsDisplayInRect:[self rectForSwatchIndex:initialIndex_]];
    [super touchesMoved:touches withEvent:event];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{   
    if (self.moved) {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];
    
    if (!CGRectContainsPoint(self.bounds, pt)) {
        return;
    }

    NSInteger  index = [self indexAtPoint:pt];
    WDColor    *color = [[WDActiveState sharedInstance] swatchAtIndex:index];
    
    if (touch.tapCount == 2) {
        [delegate_ doubleTapped:self];
    } else if (color) {
        [delegate_ setColor:color];
    } else {
        [[WDActiveState sharedInstance] setSwatch:[WDActiveState sharedInstance].paintColor atIndex:index];
        [self setNeedsDisplayInRect:[self rectForSwatchIndex:index]];
    }
    
    initialIndex_ = -1;
}


@end
