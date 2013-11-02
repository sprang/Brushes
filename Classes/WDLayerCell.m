//
//  WDLayerCell.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "UIView+Additions.h"
#import "WDBlendModes.h"
#import "WDImageView.h"
#import "WDJSONCoder.h"
#import "WDLayerCell.h"
#import "WDLayer.h"
#import "WDCellSelectionView.h"
#import "WDUpdateLayer.h"

#define kReorderMargin      44
#define kControlSpacing     16
#define kBlendSpacing       6
#define kBlendFudge         3

@implementation WDLayerCell

@synthesize controls;
@synthesize thumbnail;
@synthesize visibilityButton;
@synthesize lockButton;
@synthesize alphaLockButton;
@synthesize layerIndexLabel;
@synthesize paintingLayer;
@synthesize blendModeButton;
@synthesize delegate;

- (void) setPaintingLayer:(WDLayer *)layer
{
    paintingLayer = layer;

    thumbnail.scalingFactor = 0.5f;
    
    if (blendModeButton) {
        UIImage *background = [UIImage imageNamed:@"blend_button.png"];
        background = [background resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)];
        [blendModeButton setBackgroundImage:background forState:UIControlStateNormal];
        [blendModeButton setTitleColor:[UIColor colorWithWhite:0.25f alpha:1] forState:UIControlStateNormal];
        blendModeButton.backgroundColor = nil;
    }
    
    controls.backgroundColor = nil;
    controls.opaque = NO;
    
    [self updateThumbnail];
    [self updateVisibilityButton];
    [self updateLockedStatusButton]; 
    [self updateAlphaLockedStatusButton];
    [self updateOpacity];
    [self updateIndex];
    [self updateBlendMode];
    
    WDCellSelectionView *selectionView = [[WDCellSelectionView alloc] init];
    self.selectedBackgroundView = selectionView;
}

- (void) updateVisibilityButton
{
    [visibilityButton setImage:[UIImage imageNamed:(!paintingLayer.visible ? @"hidden.png" : @"visible.png")] forState:UIControlStateNormal];
}

- (void) updateLockedStatusButton
{
    [lockButton setImage:[UIImage imageNamed:(paintingLayer.locked ? @"lock.png" : @"unlock.png")] forState:UIControlStateNormal];
}

- (void) updateAlphaLockedStatusButton
{
    [alphaLockButton setImage:[UIImage imageNamed:(paintingLayer.alphaLocked ? @"alpha_lock.png" : @"alpha_unlock.png")] forState:UIControlStateNormal];
}

- (void) updateIndex
{
    NSUInteger index = [[paintingLayer.painting layers] indexOfObject:paintingLayer] + 1;
    layerIndexLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)index];
}

- (void) updateOpacity
{
    thumbnail.opacity = paintingLayer.opacity;
}

- (void) setOpacity:(float)opacity
{
    thumbnail.opacity = opacity;
}

- (void) updateThumbnail
{
    thumbnail.image = paintingLayer.thumbnail;
}

- (void) updateBlendMode
{
    NSString *title = [WDDisplayNameForBlendMode(paintingLayer.blendMode) lowercaseString];
    [blendModeButton setTitle:title forState:UIControlStateNormal];
}

- (IBAction) toggleVisibility:(id)sender
{
    NSString *actionName = paintingLayer.visible ? NSLocalizedString(@"Hide Layer", @"Hide Layer") : NSLocalizedString(@"Show Layer", @"Show Layer");
    [[paintingLayer.painting undoManager] setActionName:actionName];
    
    WDJSONCoder *coder = [[WDJSONCoder alloc] initWithProgress:nil];
    WDLayer *updated = [coder copy:paintingLayer deep:NO];
    [updated toggleVisibility];
    changeDocument(paintingLayer.painting, [WDUpdateLayer updateLayer:updated]);
}

- (IBAction) toggleLocked:(id)sender
{
    NSString *actionName = paintingLayer.locked ? NSLocalizedString(@"Unlock Layer", @"Unlock Layer") : NSLocalizedString(@"Lock Layer", @"Lock Layer");
    [[paintingLayer.painting undoManager] setActionName:actionName];
    
    WDJSONCoder *coder = [[WDJSONCoder alloc] initWithProgress:nil];
    WDLayer *updated = [coder copy:paintingLayer deep:NO];
    [updated toggleLocked];
    changeDocument(paintingLayer.painting, [WDUpdateLayer updateLayer:updated]);
}

- (IBAction) toggleAlphaLocked:(id)sender
{
    NSString *actionName = paintingLayer.alphaLocked ?
        NSLocalizedString(@"Unlock Layer Alpha", @"Unlock Layer Alpha") :
        NSLocalizedString(@"Lock Layer Alpha", @"Lock Layer Alpha");
    [[paintingLayer.painting undoManager] setActionName:actionName];
    
    WDJSONCoder *coder = [[WDJSONCoder alloc] initWithProgress:nil];
    WDLayer *updated = [coder copy:paintingLayer deep:NO];
    [updated toggleAlphaLocked];
    changeDocument(paintingLayer.painting, [WDUpdateLayer updateLayer:updated]);
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    float thumbWidth = CGRectGetWidth(thumbnail.frame);
    float controlWidth = CGRectGetWidth(controls.frame);
    
    float totalWidth = thumbWidth + controlWidth + kControlSpacing;
    float margin = (CGRectGetWidth(self.bounds) - kReorderMargin - totalWidth) / 2.0f;
    float centerY = CGRectGetMidY(self.bounds);
    
    thumbnail.sharpCenter = CGPointMake(margin + controlWidth + kControlSpacing + thumbWidth / 2.0, centerY);
    
    float controlCenterX = margin + controlWidth / 2.0;
    controls.sharpCenter =  CGPointMake(controlCenterX, centerY);
    
    if (blendModeButton) {
        float blendHeight = CGRectGetHeight(blendModeButton.frame);
        float controlHeight = CGRectGetHeight(controls.frame);
        float totalHeight = blendHeight + controlHeight + kBlendSpacing;
        float yMargin = (CGRectGetHeight(self.bounds) - totalHeight) / 2.0f;
        
        controls.sharpCenter =  CGPointMake(controlCenterX, yMargin + controlHeight / 2.0 - kBlendFudge);
        blendModeButton.sharpCenter = CGPointMake(controlCenterX, yMargin + controlHeight + kBlendSpacing +blendHeight / 2.0 - kBlendFudge);
    }
}

- (void) editBlendMode:(id)sender
{
    [self.delegate editBlendModeForLayer:paintingLayer];
}


@end
