//
//  WDAddImage.h
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

#import <UIKit/UIKit.h>
#import "WDSimpleDocumentChange.h"

@class WDLayer;

@interface WDAddImage : WDSimpleDocumentChange

@property (nonatomic) NSUInteger layerIndex;
@property (nonatomic) NSString *mediaType;
@property (nonatomic, assign) BOOL mergeDown;
@property (nonatomic) NSData *imageData;
@property (nonatomic) NSString *imageHash;
@property (nonatomic) NSString *layerUUID;
@property (nonatomic, assign) CGAffineTransform transform;

+ (WDAddImage *) addImage:(UIImage *)image atIndex:(NSUInteger)index mergeDown:(BOOL)mergeDown transform:(CGAffineTransform)transform;

@end
