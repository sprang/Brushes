//
//  WDDocument.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import "WDDocumentChange.h"

extern NSString *kWDBrushesFileType;
extern NSString *kWDBrushesUnpackedFileType;
extern NSString *kWDBrushesMimeType;

extern NSString *WDDocumentStartedSavingNotification;
extern NSString *WDDocumentFinishedSavingNotification;

@class WDCanvas;
@class WDPainting;
@class WDSynchronizer;

@interface WDDocument : UIDocument

@property (nonatomic, strong, readonly) WDPainting *painting;
@property (nonatomic) UIImage *thumbnail;
@property (weak, nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) WDSynchronizer *synchronizer;
@property (nonatomic, assign) BOOL loadOnlyThumbnail;

- (id) initWithFileURL:(NSURL *)url painting:(WDPainting *)painting;
- (BOOL) writeTemp:(NSString *)path type:(NSString *)contentType error:(NSError **)outError;
- (NSString *) mimeType;
- (NSString *) mimeTypeForContentType:(NSString *)typeName;
- (void) recordChange:(id<WDDocumentChange>)change;
- (void) setSavingFileType:(NSString *)typeName;
- (NSArray *) history;

+ (NSString *) contentTypeForFormat:(NSString *)name;

@end
