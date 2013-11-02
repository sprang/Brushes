//
//  WDDeleteLayer
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Original implementation by Scott Vachalek
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDCanvas.h"
#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDDeleteLayer.h"
#import "WDLayer.h"

@implementation WDDeleteLayer {
    float startOpacity_;
}

@synthesize layerUUID;

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.layerUUID = [decoder decodeStringForKey:@"layer"];
}

- (void) encodeWithWDCoder:(id <WDCoder>)coder deep:(BOOL)deep 
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeString:self.layerUUID forKey:@"layer"];
}

- (int) animationSteps:(WDPainting *)painting
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    return layer.visible ? layer.opacity / 0.03f : 0;
}

- (void) beginAnimation:(WDPainting *)painting
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    startOpacity_ = layer.opacity;
}

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    float progress = 1.0f * step / steps;
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    if (layer) {
        layer.opacity = startOpacity_ * (1.0f - progress);
        return YES;
    } else {
        return NO;
    }
}

- (void) endAnimation:(WDPainting *)painting
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    if (layer) {
        [painting activateLayerAtIndex:[painting.layers indexOfObject:layer]];
        [painting deleteActiveLayer];
        [[painting undoManager] setActionName:NSLocalizedString(@"Delete Layer", @"Delete Layer")];
    }
}

- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@ layer:%@", [super description], self.layerUUID];
}

+ (WDDeleteLayer *) deleteLayer:(WDLayer *)layer 
{
    WDDeleteLayer *notification = [[WDDeleteLayer alloc] init];
    notification.layerUUID = layer.uuid;
    return notification;
}

@end
