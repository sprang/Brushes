//
//  WDDuplicateLayer.m
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

#import "WDDuplicateLayer.h"
#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDLayer.h"

@implementation WDDuplicateLayer

@synthesize destinationLayerUUID;
@synthesize sourceLayerUUID;

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep 
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.destinationLayerUUID = [decoder decodeStringForKey:@"destinationLayerUUID"];
    self.sourceLayerUUID = [decoder decodeStringForKey:@"sourceLayerUUID"];
}

- (void) encodeWithWDCoder:(id <WDCoder>)coder deep:(BOOL)deep 
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeString:self.destinationLayerUUID forKey:@"destinationLayerUUID"];
    [coder encodeString:self.sourceLayerUUID forKey:@"sourceLayerUUID"];
}

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    WDLayer *sourceLayer = [painting layerWithUUID:self.sourceLayerUUID];
    WDLayer *destinationLayer = [painting layerWithUUID:self.destinationLayerUUID];
    return (sourceLayer != nil && destinationLayer != nil);
}

- (void) endAnimation:(WDPainting *)painting
{
    WDLayer *sourceLayer = [painting layerWithUUID:self.sourceLayerUUID];
    WDLayer *destinationLayer = [painting layerWithUUID:self.destinationLayerUUID];
    if (sourceLayer != nil && destinationLayer != nil) {
        [destinationLayer duplicateLayer:sourceLayer copyThumbnail:YES];
        [[painting undoManager] setActionName:NSLocalizedString(@"Duplicate Layer", @"Duplicate Layer")];
    }
}

- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@ sourceLayer:%@ destLayer:%@", [super description], self.sourceLayerUUID, self.destinationLayerUUID];
}

+ (WDDuplicateLayer *) duplicateLayer:(WDLayer *)sourceLayer toLayer:(WDLayer *)destinationLayer
{
    WDDuplicateLayer *change = [[WDDuplicateLayer alloc] init];
    change.destinationLayerUUID = destinationLayer.uuid;
    change.sourceLayerUUID = sourceLayer.uuid;
    return change;
}

@end
