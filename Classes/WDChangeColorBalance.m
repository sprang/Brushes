//
//  WDChangeColorBalance.m
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

#import "WDChangeColorBalance.h"
#import "WDCoder.h"
#import "WDColorBalance.h"
#import "WDDecoder.h"
#import "WDLayer.h"

@implementation WDChangeColorBalance

@synthesize colorBalance;
@synthesize layerUUID;

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep 
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.colorBalance = [decoder decodeObjectForKey:@"colorBalance"];
    self.layerUUID = [decoder decodeStringForKey:@"layer"];
}

- (void) encodeWithWDCoder:(id <WDCoder>)coder deep:(BOOL)deep 
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeObject:self.colorBalance forKey:@"colorBalance" deep:deep];
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
        layer.colorBalance = self.colorBalance;
        [layer commitColorAdjustments];
        
        [[painting undoManager] setActionName:NSLocalizedString(@"Color Balance", @"Color Balance")];
    }
}

- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@ layer:%@ colorBalance:%@", [super description], self.layerUUID, self.colorBalance];
}

+ (WDChangeColorBalance *) changeColorBalance:(WDColorBalance *)colorBalance forLayer:(WDLayer *)layer
{
    WDChangeColorBalance *change = [[WDChangeColorBalance alloc] init];
    change.colorBalance = colorBalance;
    change.layerUUID = layer.uuid;
    return change;
}

@end
