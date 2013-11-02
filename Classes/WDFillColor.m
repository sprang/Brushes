//
//  WDFillColor.m
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
#import "WDColor.h"
#import "WDDecoder.h"
#import "WDFillColor.h"
#import "WDLayer.h"

@implementation WDFillColor

@synthesize color;
@synthesize layerUUID;

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep 
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.layerUUID = [decoder decodeStringForKey:@"layer"];
    self.color = [decoder decodeObjectForKey:@"color"];
}

- (void) encodeWithWDCoder:(id <WDCoder>)coder deep:(BOOL)deep 
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeString:self.layerUUID forKey:@"layer"];
    [coder encodeObject:self.color forKey:@"color" deep:deep];
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
        [layer fill:self.color];
        [[painting undoManager] setActionName:NSLocalizedString(@"Fill Layer", @"Fill Layer")];
    }
}

- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@ layer:%@ color:%@", [super description], self.layerUUID, self.color];
}

+ (WDFillColor *) fillColor:(WDColor *)color inLayer:(WDLayer *)layer
{
    WDFillColor *fill = [[WDFillColor alloc] init];
    fill.color = color;
    fill.layerUUID = layer.uuid;
    return fill;
}

@end
