//
//  WDLayerCell.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDImageView;
@class WDLayer;

@protocol WDLayerCellDelegate;

@interface WDLayerCell : UITableViewCell
@property (nonatomic) IBOutlet UIView *controls;
@property (nonatomic) IBOutlet WDImageView *thumbnail;
@property (nonatomic) IBOutlet UIButton *visibilityButton;
@property (nonatomic) IBOutlet UIButton *lockButton;
@property (nonatomic) IBOutlet UIButton *alphaLockButton;
@property (nonatomic) IBOutlet UILabel *layerIndexLabel;
@property (nonatomic, weak) IBOutlet WDLayer *paintingLayer;
@property (nonatomic, weak) IBOutlet UIButton *blendModeButton;
@property (nonatomic, weak) id<WDLayerCellDelegate> delegate;

- (void) updateVisibilityButton;
- (void) updateLockedStatusButton;
- (void) updateAlphaLockedStatusButton;
- (void) updateThumbnail;
- (void) updateOpacity;
- (void) updateBlendMode;
- (void) updateIndex;

- (void) setOpacity:(float)opacity;

- (IBAction) toggleVisibility:(id)sender;
- (IBAction) toggleLocked:(id)sender;
- (IBAction) toggleAlphaLocked:(id)sender;
- (IBAction) editBlendMode:(id)sender;
@end

@protocol WDLayerCellDelegate <NSObject>
- (void) editBlendModeForLayer:(WDLayer *)layer;
@end
