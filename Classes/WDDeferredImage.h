//
//  WDDeferredImage.h
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

#import <Foundation/Foundation.h>

#import "WDDataProvider.h"

@interface WDDeferredImage : NSObject <WDDataProvider>

@property (nonatomic) UIImage *image;
@property (nonatomic) NSString *mediaType;
@property (nonatomic) CGSize size;

+ (WDDeferredImage *) image:(UIImage *)image mediaType:(NSString *)type size:(CGSize)size;
- (UIImage *)scaledImage;

@end
