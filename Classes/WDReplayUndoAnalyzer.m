//
//  WDReplayUndoAnalyzer.m
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

#import "WDReplayUndoAnalyzer.h"
#import "WDUtilities.h"

@implementation WDReplayUndoAnalyzer {
    int index_;
    NSMutableArray *stack_;
    NSMutableSet *undone_;
}

- (id) init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    stack_ = [NSMutableArray array];
    index_ = 0;
    
    undone_ = [NSMutableSet set];
    
    return self;
}

- (NSArray *) changesWithoutUndos
{
    return [stack_ subarrayWithRange:NSMakeRange(0, index_)];
}

- (NSSet *) undone
{
    return undone_;
}

- (void) visitOther:(NSData *)change
{
    if (index_ >= stack_.count) { 
        [stack_ addObject:change];
    } else {
        stack_[index_] = change;
    }
    ++index_;
}

- (void) visitRedo:(NSData *)change
{
    [undone_ addObject:change]; // leave undo management on for all undo/redo ops
    if (index_ < [stack_ count]) {
        ++index_;
    } else {
        WDLog(@"ERROR: log contains too many redos");
    }
}

- (void) visitUndo:(NSData *)change
{
    [undone_ addObject:change]; // leave undo management on for all undo/redo ops
    --index_;
    [undone_ addObject:stack_[index_]];
}

- (void) visitClearUndoStack:(NSData *)clear
{
    [undone_ addObject:clear];
}

@end
