//
//  WDPaintingManager.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDPainting;
@class WDDocument;

@interface WDPaintingManager : NSObject {
    NSMutableArray  *paintingNames_;
}

+ (WDPaintingManager *) sharedInstance;

- (NSString *) documentDirectory;
- (NSString *) paintingPath;
- (NSURL *) urlForName:(NSString *)name;
- (BOOL) paintingExists:(NSString *)painting;

- (void) createNewPaintingWithSize:(CGSize)size afterSave:(void (^)(WDDocument *document))afterSave;
- (BOOL) createNewPaintingWithImage:(UIImage *)image;
- (BOOL) createNewPaintingWithImageAtURL:(NSURL *)imageURL;

- (WDDocument *) paintingWithName:(NSString *)name;
- (WDDocument *) paintingAtIndex:(NSUInteger)index;
- (NSData *) packedPainting:(NSString *)name;

- (NSUInteger) numberOfPaintings;
- (NSArray *) paintingNames;

- (NSString *) fileAtIndex:(NSUInteger)ix;

- (WDDocument *) duplicatePainting:(WDDocument *)painting;

- (void) installSamples:(NSArray *)urls;
- (NSString *) installPaintingFromURL:(NSURL *)url error:(NSError **)outError;

- (void) installPainting:(WDPainting *)painting
                        withName:(NSString *)paintingName
                     initializer:(void (^)(WDDocument *document))initializer;

- (void) installPainting:(WDPainting *)painting
                withName:(NSString *)paintingName
             initializer:(void (^)(WDDocument *document))initializer
               afterSave:(void (^)(WDDocument *document))afterSave;

- (void) deletePainting:(WDDocument *)painting;
- (void) deletePaintings:(NSMutableSet *)set;

- (NSString *) uniqueFilenameWithPrefix:(NSString *)prefix;
- (void) renamePainting:(NSString *)painting newName:(NSString *)newName;

- (void) getThumbnail:(NSString *)name withHandler:(void(^)(UIImage *))handler;

@end


extern NSString *WDPaintingFileExtension;

// notifications
extern NSString *WDPaintingsDeleted;
extern NSString *WDPaintingAdded;
extern NSString *WDPaintingRenamed;

extern NSString *WDPaintingOldFilenameKey;
extern NSString *WDPaintingNewFilenameKey;

