//
//  WDPaintingManager.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "UIImage+Additions.h"
#import "WDAddImage.h"
#import "WDAddLayer.h"
#import "WDClearUndoStack.h"
#import "WDDocument.h"
#import "WDJSONCoder.h"
#import "WDLayer.h"
#import "WDPaintingManager.h"
#import "WDTar.h"
#import "WDUtilities.h"

#define BLOCKING_THUMBNAILS YES

NSString *WDPaintingFileExtension = @"brushes_unpacked";

// notifications
NSString *WDPaintingsDeleted = @"WDPaintingsDeleted";
NSString *WDPaintingAdded = @"WDPaintingAdded";
NSString *WDPaintingRenamed = @"WDPaintingRenamed";

NSString *WDPaintingOldFilenameKey = @"WDPaintingOldFilenameKey";
NSString *WDPaintingNewFilenameKey = @"WDPaintingNewFilenameKey";


@interface NSString (WDAdditions)
- (NSComparisonResult) compareNumeric:(NSString *)string;
@end

@implementation NSString (WDAdditions)
- (NSComparisonResult) compareNumeric:(NSString *)string {
    return [self compare:string options:NSNumericSearch];
}
@end

@interface WDPaintingManager (Private)
- (void) createNecessaryDirectories_;
- (void) savePaintingOrder_;
@end

@implementation WDPaintingManager

+ (WDPaintingManager *) sharedInstance
{
    static WDPaintingManager *shared = nil;

    @synchronized (self) {
        if (!shared) {
            shared = [[WDPaintingManager alloc] init];
        }
    }

    return shared;
}

- (NSString *) paintingOrderPath
{
    return [[self paintingPath] stringByAppendingPathComponent:@".order.plist"];
}

- (NSArray *) filterFiles:(NSArray *)files
{
    NSMutableArray *filtered = [[NSMutableArray alloc] init];
    
    for (NSString *file in files) {
        if ([[file pathExtension] compare:WDPaintingFileExtension options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            [filtered addObject:[file stringByDeletingPathExtension]];
        }
    }
    
    return filtered;
}

- (id) init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    [self createNecessaryDirectories_];
    
    // load the plist containing the drawing order
    NSData          *data = [NSData dataWithContentsOfFile:[self paintingOrderPath]];
    NSFileManager   *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:[self paintingPath] error:NULL];
    
    files = [self filterFiles:files];
    
    if (data) {
        NSMutableArray  *finalNames = [NSMutableArray array];
        NSArray         *names = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL];
        
        // strip out duplicates
        for (__strong NSString *name in names) {
            name = [name stringByDeletingPathExtension];
            if (![finalNames containsObject:name]) {
                [finalNames addObject:name];
            }
        }
        
        //
        // make sure this list matches the file system
        //
        NSSet *knownFiles = [NSSet setWithArray:finalNames];
        NSSet *allFiles = [NSSet setWithArray:files];
        
        // see if the saved list of files contains drawings that don't actually exist in the file system
        NSMutableSet *bogus = [knownFiles mutableCopy];
        [bogus minusSet:allFiles];
        
        // remove any bogus files
        for (NSString *missingFile in [bogus allObjects]) {
            [finalNames removeObject:missingFile];
        }
        
        //
        // see if the file system contains drawings that we're not tracking
        //
        NSMutableSet *extras = [allFiles mutableCopy];
        [extras minusSet:knownFiles];
        
        // add any extra files
        for (NSString *newFile in [extras allObjects]) {
            [finalNames addObject:[newFile stringByDeletingPathExtension]];
        }
        
        paintingNames_ = finalNames;
    } else {
        paintingNames_ = [[files sortedArrayUsingSelector:@selector(compareNumeric:)] mutableCopy];
    }
    
    // save the accurate file list
    [self savePaintingOrder_];
    
    return self;
}


- (NSString *) documentDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = paths[0]; 
    return documentsDirectory;
}

- (NSString *) paintingPath
{
    return [[self documentDirectory] stringByAppendingPathComponent:@"paintings"];
}

- (BOOL) paintingExists:(NSString *)painting
{
    if ([self.paintingNames containsObject:painting]) {
        return YES;
    } else {
        NSString        *filename = [[painting stringByDeletingPathExtension] stringByAppendingPathExtension:WDPaintingFileExtension];
        NSString        *path = [[self paintingPath] stringByAppendingPathComponent:filename];
        NSFileManager   *fm = [NSFileManager defaultManager];
        return [fm fileExistsAtPath:path];
    }
}

- (NSUInteger) numberOfPaintings
{
    return [paintingNames_ count];
}

- (NSArray *) paintingNames
{
    return paintingNames_;
}

- (NSString *) uniqueFilename
{
    return [self uniqueFilenameWithPrefix:@"Painting"];
}

- (NSString *) cleanPrefix:(NSString *)prefix
{
    // if the last "word" of the prefix is an int, strip it off
    NSArray *components = [prefix componentsSeparatedByString:@" "];
    BOOL    hasNumericalSuffix = NO;
    
    if (components.count > 1) {
        NSString *lastComponent = [components lastObject];
        hasNumericalSuffix = YES;
        
        for (int i = 0; i < lastComponent.length; i++) {
            if (![[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[lastComponent characterAtIndex:i]]) {
                hasNumericalSuffix = NO;
                break;
            }
        }
    }
    
    if (hasNumericalSuffix) {
        NSString *newPrefix = @"";
        for (int i = 0; i < components.count - 1; i++) {
            newPrefix = [newPrefix stringByAppendingString:components[i]];
            if (i != components.count - 2) {
                newPrefix = [newPrefix stringByAppendingString:@" "];
            }
        }
        
        prefix = newPrefix;
    }
    
    return prefix;
}

- (NSString *) uniqueFilenameWithPrefix:(NSString *)prefix
{
    NSString *unique = prefix;
    if ([self paintingExists:prefix]) {
        prefix = [self cleanPrefix:prefix];

        int         uniqueIx = 1;
        
        do {
            unique = [NSString stringWithFormat:@"%@ %d", prefix, uniqueIx];
            uniqueIx++;
        } while ([self paintingExists:unique]);
    }

    [paintingNames_ addObject:unique];
    return unique;
}

- (void) installPainting:(WDPainting *)painting withName:(NSString *)paintingName
             initializer:(void (^)(WDDocument *document))initializer
{
    [self installPainting:painting withName:paintingName initializer:initializer afterSave:nil];
}

- (void) installPainting:(WDPainting *)painting withName:(NSString *)paintingName
             initializer:(void (^)(WDDocument *document))initializer
               afterSave:(void (^)(WDDocument *document))afterSave
{
    if (!paintingName) {
        paintingName = [self uniqueFilename];
    }
    
    NSString *path = [[self paintingPath] stringByAppendingPathComponent:[paintingName stringByAppendingPathExtension:WDPaintingFileExtension]];
    NSURL *url = [NSURL fileURLWithPath:path];
    WDDocument *document = [[WDDocument alloc] initWithFileURL:url painting:painting];
    [document openWithCompletionHandler:^(BOOL success) {
        if (initializer) {
            // call after painting is attached to document history
            initializer(document);
            // don't allow undo of initialization
            changeDocument(painting, [WDClearUndoStack clearUndoStack]);
        }
        [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:WDPaintingAdded object:paintingName];
            });
            
            if (afterSave) {
                // do something with the document we created
                afterSave(document);
            } else {
                // othewise, close it so we don't leak
                [document closeWithCompletionHandler:nil];
            }
        }];
    }];

    [self savePaintingOrder_];
}

- (void) createNewPaintingWithSize:(CGSize)size afterSave:(void (^)(WDDocument *document))afterSave
{   
    WDPainting *painting = [[WDPainting alloc] initWithSize:size];
    [self installPainting:painting withName:[self uniqueFilename]
              initializer:^(WDDocument *document) {
                  // create initial layer
                  changeDocument(painting, [WDAddLayer addLayerAtIndex:0]);
              }
                afterSave:afterSave];
}

- (BOOL) createNewPaintingWithImage:(UIImage *)image imageName:(NSString *)imageName
{
    if (!image) {
        return NO;
    }
    
    image = [image downsampleWithMaxDimension:1024];
    
    WDPainting *painting = [[WDPainting alloc] initWithSize:image.size];
    NSString *paintingName = [self uniqueFilenameWithPrefix:imageName];
    [self installPainting:painting withName:paintingName initializer:^(WDDocument *document){
        // create initial layer with image
        changeDocument(painting, [WDAddImage addImage:image atIndex:0 mergeDown:NO transform:CGAffineTransformIdentity]);
    }];
    
    return YES;
}

- (BOOL) createNewPaintingWithImage:(UIImage *)image
{
    NSString *imageName = NSLocalizedString(@"Photo", @"Photo");
    return [self createNewPaintingWithImage:image imageName:imageName];
}

- (BOOL) createNewPaintingWithImageAtURL:(NSURL *)imageURL
{
    // need to force load here to avoid errors if (when) file is deleted
    NSData *imageData = [NSData dataWithContentsOfFile:imageURL.path options:0 error:nil];
    UIImage *image = [UIImage imageWithData:imageData];
    NSString *imageName = [[imageURL lastPathComponent] stringByDeletingPathExtension];
    return [self createNewPaintingWithImage:image imageName:imageName];
}

- (NSData *) packedPainting:(NSString *)name 
{
    // to be really correct about this, we should open the document and write it in the packed format;
    // however this results in a lot of unnecessary decompressing/compressing
    NSString *path = [self pathForName:name];
    NSURL *url = [self urlForName:name];
    WDTar *tar = [[WDTar alloc] init];
    NSOutputStream *stream = [NSOutputStream outputStreamToMemory];
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    [stream open];
    [tar writeTarToStream:stream withFiles:nil baseURL:url order:files];
    [stream close];
    return [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
}

- (dispatch_queue_t) importQueue
{
    static dispatch_queue_t importQueue = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        importQueue = dispatch_queue_create("com.taptrix.brushes.import", DISPATCH_QUEUE_SERIAL);
    });
    
    return importQueue;
}


- (NSString *) fileAtIndex:(NSUInteger)ix
{
    if (ix < [paintingNames_ count]) {
        return paintingNames_[ix];
    }
    
    return nil;
}

- (NSString *) pathForName:(NSString *)name
{
    return [[[self paintingPath] stringByAppendingPathComponent:name] stringByAppendingPathExtension:WDPaintingFileExtension];
}

- (NSURL *) urlForName:(NSString *)name
{
    return [NSURL fileURLWithPath:[self pathForName:name]];
}

- (WDDocument *) paintingWithName:(NSString *)name
{
    NSURL *url = [self urlForName:name];
    WDDocument *document = [[WDDocument alloc] initWithFileURL:url];
    document.loadOnlyThumbnail = NO;
    return document;
}

- (WDDocument *) paintingAtIndex:(NSUInteger)index
{
    return [self paintingWithName:paintingNames_[index]];
}

- (WDDocument *) duplicatePainting:(WDDocument *)document
{ 
    if (document.documentState != UIDocumentStateClosed) {
        [NSException raise:@"Invalid state" format:@"Attempting to duplicate an open document"];
    }

    NSString *duplicateName = [self uniqueFilenameWithPrefix:document.displayName];
    // change uuid of painting so this is considered a new one
    document.painting.uuid = generateUUID();
    // copy all files over, so previously saved layers and images are not lost
    NSError *error = nil;
    NSURL *url = [self urlForName:duplicateName];
    [[NSFileManager defaultManager] copyItemAtURL:document.fileURL toURL:url error:&error];
    WDDocument *duplicate = [[WDDocument alloc] initWithFileURL:url painting:document.painting];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:WDPaintingAdded object:duplicateName];
    });
    [self savePaintingOrder_];
    return duplicate;
}

- (NSString *) installPaintingFromURL:(NSURL *)url error:(NSError **)outError
{
    WDTar *tar = [[WDTar alloc] init];
    NSDictionary *files = [tar readTar:url error:outError];
    if (files && files.count) {
        NSString *base = [[[url path] lastPathComponent] stringByDeletingPathExtension];
        NSString *paintingName = [self uniqueFilenameWithPrefix:base];
        NSString *newPath = [[self paintingPath] stringByAppendingPathComponent:[paintingName stringByAppendingPathExtension:WDPaintingFileExtension]];
        NSURL *newUrl = [NSURL fileURLWithPath:newPath];
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:outError]) {
            return nil;
        }
        WDJSONCoder *coder = [[WDJSONCoder alloc] initWithProgress:nil];
        WDPainting *painting = [coder decodeRoot:@"painting.json" from:files][@"painting"];
        if (!painting) {
            [fm removeItemAtURL:newUrl error:NULL];
            [paintingNames_ removeObject:paintingName];
            return nil; // outError set by NSJSONSerialization
        }
        BOOL isHD = painting.dimensions.height > 1024 || painting.dimensions.width > 1024;
        if (isHD && !WDCanUseHDTextures()) {
            // TODO downsample instead
            if (outError) {
                *outError = [NSError errorWithDomain:@"WDPaintingManager" code:2 userInfo:nil];
            }
            [fm removeItemAtURL:newUrl error:NULL];
            [paintingNames_ removeObject:paintingName];
            return nil;
        }
        for (NSString *name in files) {
            NSString *path = [[newUrl path] stringByAppendingPathComponent:name];
            NSData *data = files[name];
            if (![fm createFileAtPath:path contents:data attributes:nil]) {
                if (outError) {
                    *outError = [NSError errorWithDomain:@"WDPaintingManager" code:1 userInfo:@{@"path": path}];
                }
                [fm removeItemAtURL:newUrl error:NULL];
                [paintingNames_ removeObject:paintingName];
                return nil;
            }
        }
        [self savePaintingOrder_];
        [[NSNotificationCenter defaultCenter] postNotificationName:WDPaintingAdded object:paintingName];
        return paintingName;
    } else {
        return nil;
    }
}

- (void) installSamples:(NSArray *)urls
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSURL *url in urls) {
        NSString *prefix = [[url lastPathComponent] stringByDeletingPathExtension];
        NSString *unique = [self uniqueFilenameWithPrefix:prefix];
        
        NSString *dstPath = [[self paintingPath] stringByAppendingPathComponent:unique];
        dstPath = [dstPath stringByAppendingPathExtension:WDPaintingFileExtension];
        [fm copyItemAtURL:url toURL:[NSURL fileURLWithPath:dstPath] error:NULL];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WDPaintingAdded object:unique];
    }
    
    [self savePaintingOrder_];
}

- (void) deletePaintings:(NSMutableSet *)set
{
    NSFileManager   *fm = [NSFileManager defaultManager];
    
    for (NSString *name in set) {
        NSError *error = nil;
        if ([fm removeItemAtURL:[self urlForName:name] error:&error]) {
            [paintingNames_ removeObject:name];
        } else {
            WDLog(@"ERROR: could not delete file %@: %@", name, error);
        }
    }
    
    [self savePaintingOrder_];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WDPaintingsDeleted object:set];
}

- (void) deletePainting:(WDDocument *)painting
{
    NSFileManager   *fm = [NSFileManager defaultManager];
    
    [fm removeItemAtURL:painting.fileURL error:NULL];
    
    [paintingNames_ removeObject:painting.displayName];
    [self savePaintingOrder_];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WDPaintingsDeleted object:[NSSet setWithObject:painting.displayName]];
}

- (void) getThumbnail:(NSString *)name withHandler:(void (^)(UIImage *))handler
{
#ifdef BLOCKING_THUMBNAILS
    NSString *jpegPath = [[self pathForName:name] stringByAppendingPathComponent:@"thumbnail.jpg"];
    UIImage *thumbnail = [UIImage imageWithContentsOfFile:jpegPath];
    if (thumbnail) {
        handler(thumbnail);
    } else {
        NSString *pngPath = [[self pathForName:name] stringByAppendingPathComponent:@"thumbnail.png"];
        thumbnail = [UIImage imageWithContentsOfFile:pngPath];
        if (thumbnail) {
            NSData *jpegThumbnail = UIImageJPEGRepresentation(thumbnail, 0.9);
            [[NSFileManager defaultManager] createFileAtPath:jpegPath contents:jpegThumbnail attributes:nil];
            handler(thumbnail);
        } else {
            handler(nil);
        }
    }
#else
    NSURL *url = [self urlForName:name];
    
    WDDocument *document = [[WDDocument alloc] initWithFileURL:url];
    document.loadOnlyThumbnail = YES;
    
    [document openWithCompletionHandler:^void(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                handler(document.thumbnail);
                [document closeWithCompletionHandler:nil];
            } else {
                WDLog(@"ERROR: Couldn't load thumbnail for: %@", url);
                handler([UIImage imageNamed:@"Icon-72.png"]);
            }
        });
    }];
#endif
}

- (void) renamePainting:(NSString *)painting newName:(NSString *)newName
{
    NSFileManager   *fm = [NSFileManager defaultManager];
    NSString        *originalPath = [[[self paintingPath] stringByAppendingPathComponent:painting] stringByAppendingPathExtension:WDPaintingFileExtension];
    
    if (![fm fileExistsAtPath:originalPath]) {
        return;
    }
    
    NSString *newPath = [[[self paintingPath] stringByAppendingPathComponent:newName] stringByAppendingPathExtension:WDPaintingFileExtension];
    
    [fm moveItemAtPath:originalPath toPath:newPath error:NULL];
    paintingNames_[[paintingNames_ indexOfObject:painting]] = newName;
    
    [self savePaintingOrder_];
    
    NSDictionary *info = @{WDPaintingOldFilenameKey: painting, WDPaintingNewFilenameKey: newName};
    [[NSNotificationCenter defaultCenter] postNotificationName:WDPaintingRenamed object:self userInfo:info];
}

@end

@implementation WDPaintingManager (Private)

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[URL path]]) {
        WDLog(@"URL does not exist: %@", URL);
        return NO;
    }
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue:@YES
                                  forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (!success){
        WDLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    
    return success;
}

- (void) createNecessaryDirectories_
{
    NSFileManager   *fm = [NSFileManager defaultManager];
    BOOL createSamples = NO;
    
    if (![fm fileExistsAtPath:[self paintingPath]]) {
        // assume this is the first time we've been run... copy over the sample drawings
        createSamples = YES;
    }
    
    [fm createDirectoryAtPath:[self paintingPath] withIntermediateDirectories:YES attributes:nil error:NULL];
    
    if (createSamples) {
        NSString *samplesDirectory = WDCanUseHDTextures() ? @"Samples HD" : @"Samples";
        NSArray *samplePaths = [[NSBundle mainBundle] pathsForResourcesOfType:WDPaintingFileExtension
                                                                  inDirectory:samplesDirectory];
        
        for (NSString *path in samplePaths) {
            NSString *galleryPath = [[self paintingPath] stringByAppendingPathComponent:[path lastPathComponent]];
            [fm copyItemAtPath:path toPath:galleryPath error:NULL];
            
            [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:galleryPath]];
        }
    }
}

- (void) savePaintingOrder_
{
    [[NSPropertyListSerialization dataWithPropertyList:paintingNames_ format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL]
     writeToFile:[self paintingOrderPath] atomically:YES];
}

@end
