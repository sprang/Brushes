//
//  WDAddPath.h
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
#import "WDDocumentChange.h"

@class WDLayer;
@class WDPath;

@interface WDAddPath : NSObject <WDDocumentChange>

@property (nonatomic) WDPath *path;
@property (nonatomic, assign) BOOL erase;
@property (nonatomic) NSString *layerUUID;
@property (nonatomic, weak) WDPainting *sourcePainting;

+ (WDAddPath *) addPath:(WDPath *)added erase:(BOOL)erase layer:(WDLayer *)layer sourcePainting:(WDPainting *)painting;

@end
