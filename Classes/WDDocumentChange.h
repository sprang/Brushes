//
//  WDDocumentChange.h
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
#import "WDCoding.h"

@class WDPainting;
@protocol WDDocumentChangeVisitor;

@protocol WDDocumentChange <WDCoding>

@property int changeIndex;

- (int) animationSteps:(WDPainting *)painting;
- (void) beginAnimation:(WDPainting *)painting;
- (BOOL) applyToPaintingAnimated:(WDPainting *)painting step:(int)step of:(int)steps undoable:(BOOL)undoable;
- (void) endAnimation:(WDPainting *)painting;

- (void) accept:(id<WDDocumentChangeVisitor>)visitor;
- (void) scale:(float)scale;

@end

extern NSString *WDDocumentChangedNotification;
extern NSString *WDDocumentChangedNotificationChange;
extern NSString *WDHistoryVersion;

extern void changeDocument(WDPainting *painting, id<WDDocumentChange> change);
