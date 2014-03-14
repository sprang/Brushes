//
//  WDDocumentChangeVisitor.h
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

#import <Foundation/Foundation.h>

@class WDAddPath;
@class WDRedoChange;
@class WDUndoChange;
@protocol WDDocumentChange;

@protocol WDDocumentChangeVisitor <NSObject>

- (void) visitAddPath:(WDAddPath *)change;
- (void) visitClearUndoStack;
- (void) visitGeneric:(id<WDDocumentChange>)change;
- (void) visitRedo:(WDRedoChange *)change;
- (void) visitUndo:(WDUndoChange *)change;

@end
