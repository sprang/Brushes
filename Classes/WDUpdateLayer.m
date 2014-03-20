//
//  WDUpdateLayer
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
#import "WDJSONCoder.h"
#import "WDLayer.h"
#import "WDUpdateLayer.h"


@implementation WDUpdateLayer

@synthesize layer;

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.layer = [decoder decodeObjectForKey:@"layer"];
}

- (void) encodeWithWDCoder:(id<WDCoder>)coder deep:(BOOL)deep 
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeObject:self.layer forKey:@"layer" deep:NO];
}

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    WDLayer *layer2 = [painting layerWithUUID:self.layer.uuid];
    return (layer2 != nil && self.layer != nil);
}

- (void) endAnimation:(WDPainting *)painting
{
    WDLayer *layer2 = [painting layerWithUUID:self.layer.uuid];
    if (layer2 && self.layer) {
        WDJSONCoder *coder = [[WDJSONCoder alloc] initWithProgress:nil];
        [coder update:layer2 with:self.layer];
    }
}

- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@ layer:%@", [super description], self.layer];
}

+ (WDUpdateLayer *) updateLayer:(WDLayer *)layer
{
    WDUpdateLayer *change = [[WDUpdateLayer alloc] init];
    change.layer = layer;
    return change;
}

@end
