//
//  WDChangeOpacity.m
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

#import "WDChangeOpacity.h"
#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDLayer.h"

@implementation WDChangeOpacity {
    float startOpacity_;
}

@synthesize layerUUID;
@synthesize opacity;

- (void) encodeWithWDCoder:(id<WDCoder>)coder deep:(BOOL)deep
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeString:self.layerUUID forKey:@"layer"];
    [coder encodeFloat:self.opacity forKey:@"opacity"];
}

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.layerUUID = [decoder decodeStringForKey:@"layer"];
    self.opacity = [decoder decodeFloatForKey:@"opacity"];
}

- (int) animationSteps:(WDPainting *)painting
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    return layer.visible ? fabsf(self.opacity - layer.opacity) / 0.03f : 0;
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
        layer.opacity = startOpacity_ + (self.opacity - startOpacity_) * progress;
        return YES;
    } else {
        return NO;
    }
}

- (void) endAnimation:(WDPainting *)painting
{
    NSString *format = NSLocalizedString(@"Layer Opacity: %d%%", @"Layer Opacity: %d%%");
    [[painting undoManager] setActionName:[NSString stringWithFormat:format, (int) roundf(self.opacity * 100)]];
}


- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@ layer:%@ opacity:%g", [super description], self.layerUUID, self.opacity];
}

+ (WDChangeOpacity *) changeOpacity:(float)opacity forLayer:(WDLayer *)layer
{
    WDChangeOpacity *change = [[WDChangeOpacity alloc] init];
    change.layerUUID = layer.uuid;
    change.opacity = opacity;
    return change;
}

@end
