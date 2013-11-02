//
//  WDPaintingFragment.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDLayer;

@interface WDPaintingFragment : NSObject 

@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic) NSString *cachedFilename;

+ (WDPaintingFragment *) paintingFragmentWithData:(NSData *)data bounds:(CGRect)bounds;

- (id) initWithData:(NSData *)data bounds:(CGRect)bounds;
- (WDPaintingFragment *) inverseFragment:(WDLayer *)layer;
- (void) applyInLayer:(WDLayer *)layer;
- (NSUInteger) bytesUsed;

@end

