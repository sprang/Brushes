//
//  WDClearUndoStack.m
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

#import "WDClearUndoStack.h"
#import "WDDocumentChangeVisitor.h"
#import "WDPainting.h"

@implementation WDClearUndoStack

- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable
{
    return undoable;
}

- (void) endAnimation:(WDPainting *)painting
{
    if ([painting.undoManager isUndoRegistrationEnabled]) {
        // calling this when undo registration is disable will explode
        [painting.undoManager removeAllActions];
        [painting clearSelectionStack];
    }
}

- (void) accept:(id<WDDocumentChangeVisitor>)visitor
{
    [visitor visitClearUndoStack];
}

+ (WDClearUndoStack *) clearUndoStack 
{
    return [[WDClearUndoStack alloc] init];
}

@end
