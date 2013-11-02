//
//  WDToolButton.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDTool.h"
#import "WDToolButton.h"
#import "WDActiveState.h"

#define kCornerRadius   6
#define kTopInset       2.0

@implementation WDToolButton

@synthesize tool = tool_;

- (UIImage *) selectedImage
{
    CGRect rect = CGRectMake(0, 0, 30, 30);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
        
    CGContextSaveGState(ctx);
        
    // clip
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 1, kTopInset)
                                                    cornerRadius:kCornerRadius];
    [path addClip];
    
    [[UIColor colorWithRed:(32.0f / 255.0f) green:(105.0f / 255.0f) blue:(221.0f / 255.0f) alpha:0.05] set];
    //[[UIColor colorWithWhite:0.0f alpha:0.05f] set];
    CGContextFillRect(ctx, rect);
        
    // draw donut to create inner shadow
    [[UIColor blackColor] set];
    CGContextAddRect(ctx, CGRectInset(rect, -20, -20));
    path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:kCornerRadius];
    CGContextSetShadowWithColor(ctx, CGSizeZero, 7, [UIColor colorWithWhite:0.0 alpha:0.15].CGColor);
    path.usesEvenOddFillRule = YES;
    [path fill];
        
    CGContextRestoreGState(ctx);
        
    path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 0.5f, kTopInset - 0.5f) cornerRadius:kCornerRadius];
    [[UIColor colorWithWhite:1.0f alpha:1.0f] set];
    [path stroke];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    CALayer *layer = self.layer;
    layer.shadowRadius = 1;
    layer.shadowOpacity = 0.9f;
    layer.shadowOffset = CGSizeZero;
    layer.shouldRasterize = YES;
    layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    UIImage *bgImage = [[self selectedImage] stretchableImageWithLeftCapWidth:8 topCapHeight:8];
    [self setBackgroundImage:bgImage forState:UIControlStateSelected];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeToolChanged:) name:WDActiveToolDidChange object:nil];
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) activeToolChanged:(NSNotification *)aNotification
{
    self.selected = ([WDActiveState sharedInstance].activeTool == self.tool) ? YES : NO;
}

- (void) setTool:(WDTool *)tool
{
    tool_ = tool;
    
    [self setImage:tool.icon forState:UIControlStateNormal];
}

- (void) setPhoneLandscapeMode:(BOOL)landscapeMode
{
    if (landscapeMode) {
        self.frame = CGRectMake(0, 0, 32, 28);
        [self setImage:tool_.landscapeIcon forState:UIControlStateNormal];
    } else {
        self.frame = CGRectMake(0, 0, 36, 36);
        [self setImage:tool_.icon forState:UIControlStateNormal];
    }
}

@end
