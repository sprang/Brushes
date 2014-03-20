//
//  WDCodable
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

@protocol WDCoder;
@protocol WDDecoder;

@protocol WDCoding <NSObject>

@required

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep;
- (void) encodeWithWDCoder:(id<WDCoder>)coder deep:(BOOL)deep;

@end

