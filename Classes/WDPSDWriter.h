//
//  WDPSDWriter
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

//  Saves paintings using Adobe's PSD format as documented at:
//  http://www.adobe.com/devnet-apps/photoshop/fileformatashtml/PhotoshopFileFormats.htm
//

#import <Foundation/Foundation.h>

@class WDPainting;

@interface WDPSDWriter : NSObject

- (id) initWithPainting:(WDPainting *)painting;

- (void) writePSD:(NSOutputStream *)out;
+ (void) validatePSD:(NSData *)data;

@end
