//
//  WDAddLayer
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

#import "WDAddLayer.h"
#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDLayer.h"
#import "WDUtilities.h"

@implementation WDAddLayer

@synthesize index;
@synthesize layerUUID;


- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep 
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.index = [decoder decodeIntegerForKey:@"index"];
    self.layerUUID = [decoder decodeStringForKey:@"layer"];
}

- (void) encodeWithWDCoder:(id <WDCoder>)coder deep:(BOOL)deep 
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeInteger:(int)self.index forKey:@"index"];
    [coder encodeString:self.layerUUID forKey:@"layer"];
}

- (void) beginAnimation:(WDPainting *)painting
{
    NSUInteger n = MIN(self.index, painting.layers.count);
    WDLayer *layer = [[WDLayer alloc] initWithUUID:self.layerUUID];
    layer.painting = painting;
    [painting insertLayer:layer atIndex:n];
    [painting activateLayerAtIndex:n];
}

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    return [painting layerWithUUID:self.layerUUID] != nil;
}

- (void) endAnimation:(WDPainting *)painting
{
    [[painting undoManager] setActionName:NSLocalizedString(@"Add Layer", @"Add Layer")];
}

- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@ added:%@ layer:%lu", [super description], self.layerUUID, (unsigned long) self.index];
}

+ (WDAddLayer *) addLayerAtIndex:(NSUInteger)index 
{
    WDAddLayer *notification = [[WDAddLayer alloc] init];
    notification.index = index;
    notification.layerUUID = generateUUID();
    return notification;
}

@end
