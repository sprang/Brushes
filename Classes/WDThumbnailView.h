//
//  WDThumbnailCell.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDThumbButton;

@interface WDThumbnailView : UIView <UITextFieldDelegate> {
    NSString                    *filename_;
    WDThumbButton               *thumbButton_;
    UIImageView                 *selectedIndicator_;
    UIActivityIndicatorView     *activityView_;
    UITextField                 *titleField_;
}

@property (nonatomic) NSString *filename;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, weak) id delegate;
@property (nonatomic, readonly) UITextField *titleField;
@property (nonatomic, readonly) NSInteger titleFieldHeight;

// image management
- (void) reload;
- (void) updateThumbnail:(UIImage *)thumbnail;
- (void) clear;

- (void) stopEditing;

- (NSComparisonResult) compare:(WDThumbnailView *)thumbView;

- (void) startActivity;
- (void) stopActivity;

@end

@protocol WDThumbnailViewDelegate <NSObject>
- (BOOL) thumbnailShouldBeginEditing:(WDThumbnailView *)thumb;
- (void) thumbnailDidBeginEditing:(WDThumbnailView *)thumb;
- (void) thumbnailDidEndEditing:(WDThumbnailView *)thumb;
@end
