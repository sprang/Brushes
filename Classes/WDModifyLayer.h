//
//  WDModifyLayer.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Original implementation by Scott Vachalek
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import "WDSimpleDocumentChange.h"

typedef enum {
    WDMergeLayer,
    WDClearLayer,
    WDDesaturateLayer,
    WDInvertLayerColor,
    WDFlipLayerHorizontal,
    WDFlipLayerVertical,
} WDLayerOperation;

@class WDLayer;

@interface WDModifyLayer : WDSimpleDocumentChange

@property (nonatomic) NSString *layerUUID;
@property (nonatomic, assign) WDLayerOperation operation;

+ (WDModifyLayer *) modifyLayer:(WDLayer *)layer withOperation:(WDLayerOperation)operation;
+ (WDModifyLayer *) modifyLayerUUID:(NSString *)layerUUID withOperation:(WDLayerOperation)operation;

@end
