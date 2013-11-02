//
//  NSData+Additions.h
//  Brushes
//
//  Created by Steve Sprang on 4/27/10.
//  Copyright 2010 Steve Sprang. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (WDAdditions)

// gzip compression utilities
- (NSData *)decompress;
- (NSData *)compress;

- (NSString *)hexadecimalString;

@end
