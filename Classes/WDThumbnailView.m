//
//  WDThumbnailCell.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//


#import "WDThumbnailView.h"
#import "WDPaintingManager.h"
#import "WDUtilities.h"
#import "WDThumbButton.h"
#import "UIImage+Additions.h"
#import "UIView+Additions.h"

@interface WDThumbnailView (Private)
- (void) reloadFilenameFields_;
@end

@implementation WDThumbnailView

@synthesize filename = filename_;
@synthesize titleField = titleField_;
@synthesize target, action, selected, delegate;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.clearsContextBeforeDrawing = NO;
    self.opaque = NO;
    self.backgroundColor = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawingRenamed:) name:WDPaintingRenamed object:nil];
    
    CALayer *layer = self.layer;
    layer.shouldRasterize = YES;
    layer.rasterizationScale = [UIScreen mainScreen].scale;

    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) runningOnPhone
{    
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? YES : NO;
}

- (CAAnimation*) getPulseAnimation
{
    float bigScale = 1.05;
    float smallScale = 0.95;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    NSValue *big = [NSValue valueWithCATransform3D:CATransform3DMakeScale(bigScale, bigScale, 1)];
    NSValue *small = [NSValue valueWithCATransform3D:CATransform3DMakeScale(smallScale, smallScale, 1)];

    animation.values = @[big, small];
    animation.autoreverses = YES;
    animation.duration = 0.2;
    animation.repeatCount = HUGE_VALF;
    
    return animation;
}

- (void) setSelected:(BOOL)flag
{
    if (selected == flag) {
        return;
    }
    
    selected = flag;
    
    if (flag) {
        if (!selectedIndicator_) {
            UIImage *checkmark = [UIImage relevantImageNamed:@"checkmark.png"];
            selectedIndicator_ = [[UIImageView alloc] initWithImage:checkmark];
            [self addSubview:selectedIndicator_];
        }
        
        CGPoint topRightCorner = CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMinY(self.bounds));
        CGPoint mySize = CGPointMake(CGRectGetWidth(selectedIndicator_.frame), -CGRectGetHeight(selectedIndicator_.frame));
        mySize = WDMultiplyPointScalar(mySize, 0.5f);
        CGPoint center = WDSubtractPoints(topRightCorner, mySize);
        selectedIndicator_.sharpCenter = center;
        //[selectedIndicator_.layer addAnimation:[self getPulseAnimation] forKey:@"pulse"];
    } else if (!flag && selectedIndicator_){
        [selectedIndicator_ removeFromSuperview];
        selectedIndicator_ = nil;
    }
 }

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField;  
{
    BOOL shouldBegin = YES;
    
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(thumbnailShouldBeginEditing:)]) {
            shouldBegin = [self.delegate thumbnailShouldBeginEditing:self];
        }
    }
    
    return shouldBegin;
}

- (void) textEditingDidEnd:(id)sender
{
    NSString *newName = titleField_.text;
    NSString *errorMessage = nil;
    
    // tell the delegate we're done
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(thumbnailDidEndEditing:)]) {
            [self.delegate performSelector:@selector(thumbnailDidEndEditing:) withObject:self];
        }
    }
    
    if ([newName isEqualToString:[filename_ stringByDeletingPathExtension]]) {
        // nothing changed
        return;
    }
    
    if (newName.length == 0) {
        // no need to warn about blank names
        // errorMessage = @"The drawing name cannot be blank.";
        [self reloadFilenameFields_];
    } else if ([newName characterAtIndex:0] == '.') {
        errorMessage = NSLocalizedString(@"The painting name cannot begin with a dot “.”.",
                                         @"The painting name cannot begin with a dot “.”.");
    } else if ([newName rangeOfString:@"/"].length > 0 || [newName rangeOfString:@":"].length > 0) {
        errorMessage = NSLocalizedString(@"The painting name cannot contain “:” or “/”.",
                                         @"The painting name cannot contain “:” or “/”.");
    } else if ([[WDPaintingManager sharedInstance] paintingExists:newName]) {
        NSString *format = NSLocalizedString(@"A painting with the name “%@” already exists. Please choose a different name.",
                                             @"A painting with the name “%@” already exists. Please choose a different name.");
        errorMessage = [NSString stringWithFormat:format, newName];
    } else {
        [[WDPaintingManager sharedInstance] renamePainting:filename_ newName:titleField_.text];
    }
    
    if (errorMessage) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        [self reloadFilenameFields_];
    }
}

- (void) textEdited:(id)sender
{
}

- (void) stopEditing
{
    [titleField_ endEditing:YES];
}

- (void) imageTapped:(id)sender
{
    [[UIApplication sharedApplication] sendAction:self.action to:self.target from:self forEvent:nil];
}

- (NSInteger) titleFieldHeight
{
    return [self runningOnPhone] ? 24 : 30;
}

- (void) setFilename:(NSString *)filename
{
    if ([filename isEqualToString:self.filename]) {
        return;
    }
    
    filename_ = filename;
    
    if (!titleField_) {
        CGRect frame = CGRectMake(0, 0, self.bounds.size.width, self.titleFieldHeight);
        
        titleField_ = [[UITextField alloc] initWithFrame:frame];
        titleField_.textAlignment = UITextAlignmentCenter;
        titleField_.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        titleField_.delegate = self;
        titleField_.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:([self runningOnPhone] ? 16 : 20)];
        titleField_.textColor = [UIColor blackColor];
        titleField_.clearButtonMode = UITextFieldViewModeWhileEditing;
        titleField_.returnKeyType = UIReturnKeyDone;
        titleField_.autocapitalizationType = UITextAutocapitalizationTypeWords;
        titleField_.borderStyle = UITextBorderStyleNone;
        titleField_.opaque = NO;
        titleField_.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        [titleField_ addTarget:self action:@selector(textEdited:) forControlEvents:(UIControlEventEditingDidEndOnExit)]; 
        [titleField_ addTarget:self action:@selector(textEditingDidEnd:) forControlEvents:(UIControlEventEditingDidEnd)];
        
        [titleField_ sizeToFit];
        frame = titleField_.frame;
        frame.size.width = CGRectGetWidth(self.bounds);
        frame.size.height += 4;
        frame.origin = CGPointMake(0, CGRectGetHeight(self.bounds) - frame.size.height);
        titleField_.frame = frame;
        
        [self addSubview:titleField_];
    }
    
    [self reload];
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(thumbnailDidBeginEditing:)]) {
            [self.delegate thumbnailDidBeginEditing:self];
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString    *proposed = textField.text;
    
    if (![string isEqualToString:@"\n"]) {
        proposed = [proposed stringByReplacingCharactersInRange:range withString:string];
    }
    
    if (proposed.length && [proposed characterAtIndex:0] == '.') {
        return NO;
    }
    
    if ([string isEqualToString:@":"]) {
        return NO;
    }
    
    if ([string isEqualToString:@"/"]) {
        return NO;
    }
    
    return YES;
}

- (void) drawingRenamed:(NSNotification *)aNotification
{
    NSDictionary *userInfo = [aNotification userInfo];
    
    if ([userInfo[WDPaintingOldFilenameKey] isEqualToString:filename_]) {
        self.filename = userInfo[WDPaintingNewFilenameKey];
    }
}

- (void) updateThumbnail:(UIImage *)thumbnail
{
    if (thumbnail) {
        thumbButton_.image = thumbnail;
    }
}

- (void) clear
{
    thumbButton_.image = nil;
}

- (void) reload
{
    if (!thumbButton_) {
        thumbButton_ = [WDThumbButton thumbButtonWithFrame:self.bounds];
        thumbButton_.target = self;
        thumbButton_.action = @selector(imageTapped:);
        [self insertSubview:thumbButton_ atIndex:0];
    }

    if (thumbButton_.image != nil) {
        // clear the image and set the name, but only if it's a recycled thumbnail -- otherwise the text appears before the image
        thumbButton_.image = nil;
        [self reloadFilenameFields_];
    }
    [[WDPaintingManager sharedInstance] getThumbnail:filename_ withHandler:^void(UIImage *image) {
        [self updateThumbnail:image];
        [self reloadFilenameFields_];
    }];
}

- (NSComparisonResult) compare:(WDThumbnailView *)thumbView
{
    return [self.filename compare:thumbView.filename options:NSNumericSearch];
}

- (void) startActivity
{
    if (self.superview) {
        UIActivityIndicatorViewStyle style = WDDeviceIsPhone() ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleWhiteLarge;
        activityView_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        
        // create a background view to make the indicator more visible
        float inset = WDDeviceIsPhone() ? -5 : -10;
        CGRect frame = CGRectInset(activityView_.frame, inset, inset);
        UIView *bgView = [[UIView alloc] initWithFrame:frame];
        bgView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.333f];
        bgView.opaque = NO;
        bgView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        
        // adjust the layer properties to get the appearance that we want
        CALayer *layer = bgView.layer;
        layer.cornerRadius = CGRectGetWidth(frame) / 2;
        
        activityView_.sharpCenter = WDCenterOfRect(bgView.bounds);
        bgView.sharpCenter = WDCenterOfRect(self.bounds);
        
        [bgView addSubview:activityView_];
        [self addSubview:bgView];
        
        [activityView_ startAnimating];
        [CATransaction flush];
    }
}

- (void) stopActivity
{
    if (activityView_) {
        [activityView_ stopAnimating];
        [[activityView_ superview] removeFromSuperview];
        activityView_ = nil;
    }
}

@end

@implementation WDThumbnailView (Private)

- (void) reloadFilenameFields_
{
    NSString *strippedFilename = [self.filename stringByDeletingPathExtension];
    
    titleField_.text = strippedFilename;
}

@end

