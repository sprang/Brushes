//
//  WDAddImage.m
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

#import "NSData+Additions.h"
#import "WDAddImage.h"
#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDLayer.h"
#import "WDTypedData.h"
#import "WDUtilities.h"
#import "UIImage+Additions.h"

@implementation WDAddImage

@synthesize imageData;
@synthesize imageHash;
@synthesize layerIndex;
@synthesize layerUUID;
@synthesize mediaType;
@synthesize mergeDown;
@synthesize transform;

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep 
{
    [super updateWithWDDecoder:decoder deep:deep];
    self.imageHash = [decoder decodeStringForKey:@"imageHash"];
    self.layerIndex = [decoder decodeIntegerForKey:@"index" defaultTo:NSUIntegerMax];
    self.layerUUID = [decoder decodeStringForKey:@"layer"];
    self.mergeDown = [decoder decodeBooleanForKey:@"mergeDown"];
    self.transform = [decoder decodeTransformForKey:@"transform"];
}

- (void) encodeWithWDCoder:(id <WDCoder>)coder deep:(BOOL)deep 
{
    [super encodeWithWDCoder:coder deep:deep];
    [coder encodeString:self.imageHash forKey:@"imageHash"];
    [coder encodeInteger:(int)self.layerIndex forKey:@"index"];
    [coder encodeString:self.layerUUID forKey:@"layer"];
    [coder encodeBoolean:self.mergeDown forKey:@"mergeDown"];
    [coder encodeTransform:self.transform forKey:@"transform"];
}

- (int) animationSteps:(WDPainting *)painting
{
    return (self.layerIndex != NSUIntegerMax || painting.layers.count > 1) ? 30 : 1;
}

- (void) beginAnimation:(WDPainting *)painting
{
    if (self.layerIndex != NSUIntegerMax) {
        // older versions did not add a layer automatically
        NSUInteger n = MIN(self.layerIndex, painting.layers.count);
        WDLayer *layer = [[WDLayer alloc] initWithUUID:self.layerUUID];
        layer.painting = painting;
        [painting insertLayer:layer atIndex:n];
        [painting activateLayerAtIndex:n];
    }

    if (!self.imageData) {
        // during replay, this data will have been loaded by the painting but not this object, yet
        WDTypedData *typedData = (painting.imageData)[self.imageHash];
        self.imageData = typedData.data;
    } else {
        // during recording/collaboration the imageData needs to go to the painting for storage
        WDTypedData *typedData = [WDTypedData data:self.imageData mediaType:self.mediaType compress:NO uuid:self.imageHash isSaved:kWDSaveStatusUnsaved];
        (painting.imageData)[self.imageHash] = typedData;
    }

    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    layer.opacity = 0;
    UIImage *image = [UIImage imageWithData:self.imageData];
    [layer renderImage:image transform:self.transform];
}

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    WDLayer *layer = [painting layerWithUUID:self.layerUUID];
    if (layer) {
        layer.opacity = WDSineCurve(1.0f * step / steps);
        return YES;
    } else {
        return NO;
    }
}

- (void) endAnimation:(WDPainting *)painting
{
    if (self.mergeDown) {
        [painting mergeDown];
    }
    [[painting undoManager] setActionName:NSLocalizedString(@"Place Image", @"Place Image")];
}

- (void) scale:(float)scale
{
    // seems like this is scaling the translation portion twice, but it works...?   
    CGAffineTransform t = self.transform;
    self.transform = CGAffineTransformMake(t.a, t.b, t.c, t.d, t.tx * scale, t.ty * scale);
    self.transform = CGAffineTransformScale(self.transform, scale, scale);
}

- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@ addedto:%@ hash:%@ transform:%@", [super description], self.layerUUID, self.imageHash,
            NSStringFromCGAffineTransform(self.transform)];
}

+ (WDAddImage *) addImage:(UIImage *)image atIndex:(NSUInteger)index mergeDown:(BOOL)mergeDown transform:(CGAffineTransform)transform;
{
    WDAddImage *notification = [[WDAddImage alloc] init];
    
    BOOL hasAlpha = [image hasAlpha];

    notification.imageData = hasAlpha ? UIImagePNGRepresentation(image) : UIImageJPEGRepresentation(image, 0.9f);
    notification.imageHash = [WDSHA1DigestForData(notification.imageData) hexadecimalString];
    notification.layerIndex = index;
    notification.layerUUID = generateUUID();
    notification.mergeDown = mergeDown;
    notification.mediaType = hasAlpha ? @"image/png" : @"image/jpeg";
    notification.transform = transform;
    return notification;
}

@end
