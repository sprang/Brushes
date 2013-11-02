//
//  WDDocumentReplay.h
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

@class WDDocument;
@class WDPainting;

@protocol WDDocumentReplayDelegate <NSObject>

- (void) replayFinished;
- (void) replayError;

@end

@interface WDDocumentReplay : NSObject

@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, strong) WDPainting *painting;
@property (nonatomic) NSString *paintingName;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, weak) id<WDDocumentReplayDelegate> replayDelegate;
@property (nonatomic) int errorCount;
@property (nonatomic, assign) float scale;

- (id) initWithDocument:(WDDocument *)document includeUndos:(BOOL)undos scale:(float)scale;
- (void) play;
- (void) pause;
- (void) restart;
- (BOOL) isFinished;
- (BOOL) isPlaying;

@end
