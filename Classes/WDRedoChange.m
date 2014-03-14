//
//  WDRedoChange.m
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

#import "WDDocumentChangeVisitor.h"
#import "WDPainting.h"
#import "WDRedoChange.h"

@implementation WDRedoChange

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    return [painting.undoManager canRedo];
}

- (void) endAnimation:(WDPainting *)painting
{
    if ([painting.undoManager canRedo]) {
        [painting.undoManager redo];
    }
}

- (void) accept:(id<WDDocumentChangeVisitor>)visitor
{
    [visitor visitRedo:self];
}

+ (WDRedoChange *) redoChange
{
    return [[WDRedoChange alloc] init];
}

@end
