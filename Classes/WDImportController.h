//
//  WDImportController.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DBRestClient.h>


@protocol WDImportControllerDelegate;

@interface WDImportController : UIViewController <DBRestClientDelegate, UIAlertViewDelegate> {
	UIBarButtonItem					*importButton_;
	IBOutlet UIActivityIndicatorView	*activityIndicator_;
	IBOutlet UITableView				*contentsTable_;
	NSArray							*dropboxItems_;
	NSMutableSet						*selectedItems_;
	NSMutableDictionary				*itemsKeyedByImagePath_;
	NSMutableSet						*itemsFailedImageLoading_;
	NSString							*remotePath_;
	BOOL								isRoot_;
	NSString							*imageCacheDirectory_;
	DBRestClient						*dropboxClient_;
	NSFileManager					*fileManager_;
	
}

@property (nonatomic, copy) NSString *remotePath;
@property (nonatomic, weak) id <WDImportControllerDelegate> delegate;

+ (BOOL) isBrushesType:(NSString *)extension;
+ (BOOL) isFontType:(NSString *)extension;
+ (BOOL) isImageType:(NSString *)extension;
+ (BOOL) canImportType:(NSString *)extension;

@end

@protocol WDImportControllerDelegate <NSObject>
@optional
- (void) importController:(WDImportController *)controller didSelectDropboxItems:(NSArray *)dropboxItems;
@end
