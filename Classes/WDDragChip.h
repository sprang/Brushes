//
//  WDDragChip.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDColor;

@interface WDDragChip : UIView 
@property (nonatomic, strong) WDColor *color;
@end

@protocol WDColorDragging <NSObject>
@optional
- (void)dragMoved:(UITouch *)touch colorChip:(WDDragChip *)chip colorSource:(id)source;
- (void)dragExited;
- (BOOL)dragEnded:(UITouch *)touch colorChip:(WDDragChip *)chip colorSource:(id)source destination:(CGPoint *)flyLoc;
@end
