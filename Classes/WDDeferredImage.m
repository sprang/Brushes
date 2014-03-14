//
//  WDDeferredImage.m
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

#import "UIImage+Resize.h"
#import "WDDeferredImage.h"
#import "WDUtilities.h"

@implementation WDDeferredImage

@synthesize image;
@synthesize mediaType;
@synthesize size;

+ (WDDeferredImage *)image:(UIImage *)image mediaType:(NSString *)type size:(CGSize)size
{
    WDDeferredImage *di = [[WDDeferredImage alloc] init];
    di.image = image;
    di.mediaType = type;
    di.size = size;
    return di;
}

- (UIImage *)scaledImage
{
    if (CGSizeEqualToSize(self.image.size, self.size)) {
        return self.image;
    } else {
        return [self.image resizedImage:self.size interpolationQuality:kCGInterpolationHigh];
    }
}

- (NSData *)data
{
    UIImage *scaledImage = self.scaledImage;
    if ([self.mediaType isEqualToString:@"image/png"]) {
        return UIImagePNGRepresentation(scaledImage);
    } else if ([self.mediaType isEqualToString:@"image/jpeg"]) {
        return UIImageJPEGRepresentation(scaledImage, 0.9f);
    } else {
        WDLog(@"ERROR: Unknown image media format: %@", self.mediaType);
        return nil;
    }
}

- (WDSaveStatus)isSaved
{
    return NO;
}

- (NSString *)uuid
{
    return nil;
}

@end
