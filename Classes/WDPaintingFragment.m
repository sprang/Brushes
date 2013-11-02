//
//  WDPaintingFragment.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "WDLayer.h"
#import "WDPaintingFragment.h"
#import "NSData+Additions.h"

@implementation WDPaintingFragment

@synthesize bounds = bounds_;
@synthesize data = data_;
@synthesize cachedFilename = cachedFilename_;

+ (WDPaintingFragment *) paintingFragmentWithData:(NSData *)data bounds:(CGRect)bounds
{
    return [[WDPaintingFragment alloc] initWithData:data bounds:bounds];
}

- (NSString *)uniqueFilename
{
    static UInt32 unique = 0;
    
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.data", (unsigned int)unique++]];
}

- (id) initWithData:(NSData *)data bounds:(CGRect)bounds
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    bounds_ = bounds;
    data_ = data;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(queue, ^{
        self.cachedFilename = [self uniqueFilename];
        [[data_ compress] writeToFile:self.cachedFilename atomically:YES];

        dispatch_sync(dispatch_get_main_queue(), ^{
            data_ = nil;
        });
    });
    
    return self;
}

- (NSData *) data
{
    if (data_) {
        return data_;
    } else if (self.cachedFilename) {
        return [[NSData dataWithContentsOfFile:self.cachedFilename] decompress];
    }
    
    return nil;
}

- (void) dealloc
{
    if (self.cachedFilename) {
        [[NSFileManager defaultManager] removeItemAtPath:self.cachedFilename error:NULL];
    }
}

- (WDPaintingFragment *) inverseFragment:(WDLayer *)layer
{
    // pull the current data from the layer so this application can be reversed
    NSData *inverseData = [layer imageDataInRect:self.bounds];
    return [WDPaintingFragment paintingFragmentWithData:inverseData bounds:self.bounds];
}

- (void) applyInLayer:(WDLayer *)layer
{
    GLint xoffset = CGRectGetMinX(bounds_);
    GLint yoffset = CGRectGetMinY(bounds_);
    GLsizei width = CGRectGetWidth(bounds_);
    GLsizei height = CGRectGetHeight(bounds_);
    
    glBindTexture(GL_TEXTURE_2D, layer.textureName);
    NSData *data = self.data;
    glTexSubImage2D(GL_TEXTURE_2D, 0, xoffset, yoffset, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data.bytes);
    
    layer.isSaved = kWDSaveStatusUnsaved;
}

- (NSUInteger) bytesUsed
{
    return self.data.length;
}

@end
