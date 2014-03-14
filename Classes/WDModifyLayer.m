//
//  WDModifyLayer.m
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

#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDLayer.h"
#import "WDModifyLayer.h"
#import "WDUtilities.h"

@implementation WDModifyLayer 

@synthesize layerUUID;
@synthesize operation;

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep 
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.layerUUID = [decoder decodeStringForKey:@"layer"];
    self.operation = [decoder decodeIntegerForKey:@"operation"];
}

- (void) encodeWithWDCoder:(id <WDCoder>)coder deep:(BOOL)deep 
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeString:self.layerUUID forKey:@"layer"];
    [coder encodeInteger:self.operation forKey:@"operation"];
}

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    return layer != nil;
}

- (void) endAnimation:(WDPainting *)painting
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    NSUndoManager *undoManager = [painting undoManager];
    
    if (layer) {
        switch (self.operation) {
            case WDMergeLayer:
                [painting activateLayerAtIndex:[painting.layers indexOfObject:layer]];
                [painting mergeDown];
                [undoManager setActionName:NSLocalizedString(@"Merge Down", @"Merge Down")];
                return;
            case WDClearLayer:
                [layer clear];
                [undoManager setActionName:NSLocalizedString(@"Clear Layer", @"Clear Layer")];
                return;
            case WDDesaturateLayer:
                [layer desaturate];
                [undoManager setActionName:NSLocalizedString(@"Desaturate", @"Desaturate")];
                return;
            case WDInvertLayerColor:
                [layer invert];
                [undoManager setActionName:NSLocalizedString(@"Invert Color", @"Invert Color")];
                return;
            case WDFlipLayerHorizontal:
                [layer flipHorizontally];
                [undoManager setActionName:NSLocalizedString(@"Flip Horizontally", @"Flip Horizontally")];
                return;
            case WDFlipLayerVertical:
                [layer flipVertically];
                [undoManager setActionName:NSLocalizedString(@"Flip Vertically", @"Flip Vertically")];
                return;
            default:
                WDLog(@"ERROR: unknown layer modification: %d", self.operation);
        }
    }
}

- (NSString *) description 
{
    NSString *operationName;
    switch (self.operation) {
        case WDMergeLayer: operationName = @"merge"; break;
        case WDClearLayer: operationName = @"clear"; break;
        case WDDesaturateLayer: operationName = @"desaturate"; break;
        case WDInvertLayerColor: operationName = @"invert"; break;
        case WDFlipLayerHorizontal: operationName = @"flip horizontal"; break;
        case WDFlipLayerVertical: operationName = @"flip vertical"; break;
        default: operationName = @"unknown"; break;
    }
    return [NSString stringWithFormat:@"%@ layer:%@ operation:%@", [super description], self.layerUUID, operationName];
}

+ (WDModifyLayer *) modifyLayer:(WDLayer *)layer withOperation:(WDLayerOperation)operation
{
    return [WDModifyLayer modifyLayerUUID:layer.uuid withOperation:operation];
}

+ (WDModifyLayer *) modifyLayerUUID:(NSString *)layerUUID withOperation:(WDLayerOperation)operation
{
    WDModifyLayer *change = [[WDModifyLayer alloc] init];
    change.layerUUID = layerUUID;
    change.operation = operation;
    return change;
}

@end
