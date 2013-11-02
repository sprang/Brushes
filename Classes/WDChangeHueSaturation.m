//
//  WDChangeHueSaturation.m
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

#import "WDChangeHueSaturation.h"
#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDHueSaturation.h"
#import "WDLayer.h"

@implementation WDChangeHueSaturation

@synthesize hueSaturation;
@synthesize layerUUID;

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep 
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.hueSaturation = [decoder decodeObjectForKey:@"hsb"];
    self.layerUUID = [decoder decodeStringForKey:@"layer"];
}

- (void) encodeWithWDCoder:(id <WDCoder>)coder deep:(BOOL)deep 
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeObject:self.hueSaturation forKey:@"hsb" deep:deep];
    [coder encodeString:self.layerUUID forKey:@"layer"];
}

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    return layer != nil;
}

- (void) endAnimation:(WDPainting *)painting
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    if (layer) {
        layer.hueSaturation = self.hueSaturation;
        [layer commitColorAdjustments];
        
        [[painting undoManager] setActionName:NSLocalizedString(@"Hue and Saturation", @"Hue and Saturation")];
    }
}

- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@ layer:%@ hue/sat:%@", [super description], self.layerUUID, self.hueSaturation];
}

+ (WDChangeHueSaturation *) changeHueSaturation:(WDHueSaturation *)hueSaturation forLayer:(WDLayer *)layer
{
    WDChangeHueSaturation *change = [[WDChangeHueSaturation alloc] init];
    change.hueSaturation = hueSaturation;
    change.layerUUID = layer.uuid;
    return change;
}

@end
