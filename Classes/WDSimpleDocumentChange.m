//
//  WDSimpleDocumentChange.m
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

#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDDocumentChangeVisitor.h"
#import "WDSimpleDocumentChange.h"

@implementation WDSimpleDocumentChange

@synthesize changeIndex;

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep 
{
    self.changeIndex = [decoder decodeIntegerForKey:@"change-index"];
}

- (void) encodeWithWDCoder:(id <WDCoder>)coder deep:(BOOL)deep 
{
    [coder encodeInteger:self.changeIndex forKey:@"change-index"];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@ #%d", [super description], self.changeIndex];
}

- (int) animationSteps:(WDPainting *)painting
{
    return 1;
}

- (void) beginAnimation:(WDPainting *)painting
{
}

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    return NO;
}

- (void) endAnimation:(WDPainting *)painting
{
}

- (void) accept:(id<WDDocumentChangeVisitor>)visitor
{
    [visitor visitGeneric:self];
}

- (void) scale:(float)scale
{
}

@end
