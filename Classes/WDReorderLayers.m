//
//  WDReorderLayers.m
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
#import "WDReorderLayers.h"

@implementation WDReorderLayers

@synthesize layerUUID;
@synthesize destIndex;

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep 
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.layerUUID = [decoder decodeStringForKey:@"layer"];
    self.destIndex = [decoder decodeIntegerForKey:@"destIndex"];
}

- (void) encodeWithWDCoder:(id <WDCoder>)coder deep:(BOOL)deep 
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeString:layerUUID forKey:@"layer"];
    [coder encodeInteger:destIndex forKey:@"destIndex"];
}

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    return (layer && (self.destIndex < [painting.layers count]));
}

- (void) endAnimation:(WDPainting *)painting
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    if (layer && (self.destIndex < [painting.layers count])) {
        [painting moveLayer:layer toIndex:self.destIndex];
        [[painting undoManager] setActionName:NSLocalizedString(@"Rearrange Layers", @"Rearrange Layers")];
    }
}

- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@ layer:%@ destIndex:%d", [super description], self.layerUUID, self.destIndex];
}

+ (WDReorderLayers *) moveLayer:(WDLayer *)layer toIndex:(int)index
{
    WDReorderLayers *change = [[WDReorderLayers alloc] init];
    change.layerUUID = layer.uuid;
    change.destIndex = index;
    return change;
}

@end
