//
//  WDDocumentReplay.m
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

#import "WDCanvas.h"
#import "WDDocument.h"
#import "WDDocumentReplay.h"
#import "WDJSONCoder.h"
#import "WDPainting.h"
#import "WDPaintingManager.h"
#import "WDReplayUndoAnalyzer.h"
#import "WDSleepTimer.h"
#import "WDUtilities.h"

@implementation WDDocumentReplay {
    BOOL includeUndos_;
    NSSet *undone_;
    NSArray *history_;
    CGSize size_;
    NSMutableDictionary *images_;
    int changeNumber_;
    id<WDDocumentChange> change_;
    int animationStep_;
    int lastAnimationStep_;
    NSDate *startTime_;
}

@synthesize delay;
@synthesize errorCount;
@synthesize painting;
@synthesize paintingName;
@synthesize paused;
@synthesize replayDelegate;
@synthesize scale = scale_;

- (id) initWithDocument:(WDDocument *)document includeUndos:(BOOL)undos scale:(float)scale
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    history_ = document.history;
    includeUndos_ = undos;
    [self optimizeUndos];
    scale_ = scale;
    size_ = WDMultiplySizeScalar(document.painting.dimensions, scale);
    images_ = document.painting.imageData;
    self.delay = 0;
    self.paintingName = document.displayName;
    
    [self restart];
    
    return self;
}

- (void) dealloc
{
    // make sure we're not disabling the sleep timer
    [[WDSleepTimer sharedInstance] enableTimer:self];
}

- (void) optimizeUndos
{
    WDReplayUndoAnalyzer *analyzer = [[WDReplayUndoAnalyzer alloc] init];
    for (NSData *change in history_) {
        if ([change length] > 100) {
            [analyzer visitOther:change];
        } else {
            NSString *s = [[NSString alloc] initWithData:change encoding:NSUTF8StringEncoding];
            if ([s rangeOfString:@"WDUndoChange"].location != NSNotFound) {
                [analyzer visitUndo:change];
            } else if ([s rangeOfString:@"WDRedoChange"].location != NSNotFound) {
                [analyzer visitRedo:change];
            } else if ([s rangeOfString:@"WDClearUndoStack"].location != NSNotFound) {
                [analyzer visitClearUndoStack:change];
            } else {
                [analyzer visitOther:change];
            }
        }
    }
    if (includeUndos_) {
        undone_ = [analyzer undone];
    } else {
        history_ = [analyzer changesWithoutUndos];
    }
}

- (BOOL) isFinished
{
    return (changeNumber_ >= history_.count && change_ == nil);
}

- (BOOL) isPlaying
{
    // YES if not paused and not finished
    return (!self.paused && !self.isFinished);
}

- (void) restart
{
    [self pause];
    self.painting = [[WDPainting alloc] initWithSize:size_];
    self.painting.imageData = [images_ mutableCopy];
    if (!includeUndos_) {
        [self.painting.undoManager disableUndoRegistration];
    }
    self.errorCount = 0;
    changeNumber_ = 0;
}

- (void) play
{
    if (self.paused) {
        [[WDSleepTimer sharedInstance] disableTimer:self];
        self.paused = NO;
        startTime_ = [NSDate date];
        [self performSelector:@selector(step) withObject:nil afterDelay:0];
    }
}

- (void) pause
{
    if (!self.paused) {
        [[WDSleepTimer sharedInstance] enableTimer:self];
        self.paused = YES;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];
    }
}

- (id<WDDocumentChange>) nextChange
{
    if (changeNumber_ < history_.count) {
        NSData *json = history_[changeNumber_++];
        NSError *error = nil;
        id entry = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
        WDJSONCoder *coder = [[WDJSONCoder alloc] initWithProgress:nil];
        id decoded = [coder reconstruct:entry binary:nil];
        if (!decoded) {
            WDLog(@"ERROR: Couldn't decode replay object: %@", error);
        } else if ([decoded conformsToProtocol:@protocol(WDDocumentChange)]) {
            if (scale_ != 1.f) {
                [decoded scale:scale_];
            }
            return decoded;
        } else {
            WDLog(@"ERROR: Unexpected object in replay: %@", decoded);
        }
    }
    return nil;
}

- (BOOL) clearToProceed
{
    // check for foreground before attempting any graphic operation, otherwise crash is possible
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        [self pause];
        return NO;
    } else {
        return YES;
    }
}

- (void) saveConversion
{
    [[WDPaintingManager sharedInstance] installPainting:self.painting withName:nil initializer:^(WDDocument *document) {
        for (NSData* json in history_) {
            NSError *error = nil;
            id entry = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
            WDJSONCoder *coder = [[WDJSONCoder alloc] initWithProgress:nil];
            id decoded = [coder reconstruct:entry binary:nil];
            if (scale_ != 1.f) {
                [decoded scale:scale_];
            }
            [document recordChange:decoded];
        }
    }];
}

- (void) step
{
    if (self.paused) {
        return;
    }
    
    if (!change_) {
        change_ = [self nextChange];
        if (!change_) {
            WDLog(@"Replay finished, time since last play: %gs", -[startTime_ timeIntervalSinceNow]);
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"autoconvert"]) {
                // activate with "-autoconvert YES" command line option
                [self saveConversion];
            }
            [self pause];
            [self.replayDelegate replayFinished];
            return;
        }
        animationStep_ = 1;
        lastAnimationStep_ = [change_ animationSteps:self.painting];

        if (![self clearToProceed]) return;
        [change_ beginAnimation:self.painting];
    }
    
    if (animationStep_ <= lastAnimationStep_) { // lastAnimationStep could be 0!
        if (![self clearToProceed]) return;
        BOOL undone = includeUndos_ && [undone_ containsObject:history_[changeNumber_ - 1]];
        BOOL success = NO;
        if (!undone && [painting.undoManager isUndoRegistrationEnabled]) {
            [painting.undoManager disableUndoRegistration];
            success = [change_ applyToPaintingAnimated:self.painting step:animationStep_++ of:lastAnimationStep_ undoable:NO];
            [painting.undoManager enableUndoRegistration];
        } else if (![painting.undoManager isUndoRegistrationEnabled]) {
            success = [change_ applyToPaintingAnimated:self.painting step:animationStep_++ of:lastAnimationStep_ undoable:NO];
        } else {
            success = [change_ applyToPaintingAnimated:self.painting step:animationStep_++ of:lastAnimationStep_ undoable:YES];
        }
        if (!success) {
            ++self.errorCount;
            WDLog(@"ERROR: Replay change failed: %@", change_);
            [self.replayDelegate replayError];
        }
    }

    if (animationStep_ > lastAnimationStep_) {
        if (![self clearToProceed]) return;
        [change_ endAnimation:self.painting];
        change_ = nil;
    }
    
    [self performSelector:@selector(step) withObject:nil afterDelay:self.delay];
}

@end
