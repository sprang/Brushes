//
//  WDActiveState.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <Foundation/Foundation.h>

@class WDBrush;
@class WDColor;
@class WDStampGenerator;
@class WDTool;

@interface WDActiveState : NSObject {
    NSMutableDictionary     *swatches_;
    NSMutableArray          *canonicalGenerators_;
}

@property (nonatomic, readonly) NSString *deviceID;
@property (nonatomic, weak) WDTool *activeTool;
@property (nonatomic) WDColor *paintColor;
@property (nonatomic, readonly) WDBrush *brush;
@property (nonatomic, readonly) BOOL eraseMode;
@property (nonatomic, readonly) NSArray *tools;
@property (nonatomic, readonly) NSUInteger brushesCount;
@property (weak, nonatomic, readonly) NSArray *stampClasses;
@property (nonatomic, readonly) NSMutableArray *canonicalGenerators;

+ (WDActiveState *) sharedInstance;

- (WDColor *) swatchAtIndex:(NSUInteger)index;
- (void) setSwatch:(WDColor *)color atIndex:(NSUInteger)index;

- (WDBrush *) brushAtIndex:(NSUInteger)index;
- (WDBrush *) brushWithID:(NSString *)uuid;
- (NSUInteger) indexOfBrush:(WDBrush *)brush;
- (NSUInteger) indexOfActiveBrush;

- (void) saveBrushes;
- (void) addBrush:(WDBrush *)brush;
- (void) addTemporaryBrush:(WDBrush *)brush;
- (BOOL) canDeleteBrush;
- (void) deleteActiveBrush;

- (void) moveBrushAtIndex:(NSUInteger)origin toIndex:(NSUInteger)dest;

- (void) selectBrushAtIndex:(NSUInteger)index;

- (void) setCanonicalGenerator:(WDStampGenerator *)aGenerator;
- (NSUInteger) indexForGeneratorClass:(Class)class;

- (void) resetActiveTool;

@end

// notifications
extern NSString *WDActiveToolDidChange;
extern NSString *WDActivePaintColorDidChange;

extern NSString *WDActiveBrushDidChange;
extern NSString *WDBrushAddedNotification;
extern NSString *WDBrushDeletedNotification;

