//
//  WDTransformOverlay.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "WDCanvas.h"
#import "WDPainting.h"
#import "WDTransformOverlay.h"
#import "WDUtilities.h"

#define kRotationSnapTolerance (1.0f)
#define kControlOffset 64

@implementation WDTransformOverlay

@synthesize canvas;
@synthesize cancelBlock;
@synthesize acceptBlock;
@synthesize horizontalFlip;
@synthesize verticalFlip;
@synthesize prompt;
@synthesize title;
@synthesize showToolbar;

- (void) setPrompt:(NSString *)inPrompt
{
    prompt = inPrompt;
    
    if (navbar_) {
        UINavigationItem *item = [[navbar_ items] lastObject];
        item.prompt = prompt;
    }
}

- (void) setTitle:(NSString *)inTitle
{
    title = inTitle;
    
    if (navbar_) {
        UINavigationItem *item = [[navbar_ items] lastObject];
        item.title = title;
    }
}

- (void) createGestureRecognizers
{
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(handlePinchGesture:)];
    [self addGestureRecognizer:pinchGesture];
    pinchGesture.delegate = self;
    
    UIRotationGestureRecognizer *rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationGesture:)];
    [self addGestureRecognizer:rotateGesture];
    rotateGesture.delegate = self;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:panGesture];
    panGesture.delegate = self;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(accept:)];
    [self addGestureRecognizer:tapGesture];
    tapGesture.delegate = self;
    tapGesture.numberOfTapsRequired = 2;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
            shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void) cancel:(id)sender
{
    cancelBlock();
}

- (void) accept:(id)sender
{
    acceptBlock();
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.opaque = NO;
    self.backgroundColor = nil;
    self.clearsContextBeforeDrawing = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    transform_ = CGAffineTransformIdentity;
    
    [self createGestureRecognizers];
    return self;
}

- (CGAffineTransform) configureInitialPhotoTransform
{
    CGSize      paintingSize = canvas.painting.dimensions;
    CGSize      photoSize = canvas.photo.size;
    CGPoint     paintingCenter = CGPointMake(paintingSize.width / 2, paintingSize.height / 2);
    CGPoint     photoCenter = CGPointMake(photoSize.width / 2, photoSize.height / 2);
    
    CGPoint offset = WDSubtractPoints(paintingCenter, photoCenter);
    transform_ = CGAffineTransformIdentity;
    transform_ = CGAffineTransformTranslate(transform_, offset.x, offset.y);
    
    return transform_;
}

- (float) cleanAngle:(float)angle 
{
    float   degrees = angle * (180.0f / M_PI);
    BOOL    correct = YES;
    
    degrees = fmod(degrees, 360.0f);
    if (degrees < 0) {
        degrees += 360.0f;
    }
    
    if (degrees > (90 - kRotationSnapTolerance) && degrees < (90 + kRotationSnapTolerance)) {
        degrees = 90;
    } else if (degrees > (180 - kRotationSnapTolerance) && degrees < (180 + kRotationSnapTolerance)) {
        degrees = 180;
    } else if (degrees > (270 - kRotationSnapTolerance) && degrees < (270 + kRotationSnapTolerance)) {
        degrees = 270;
    } else if (degrees > (360 - kRotationSnapTolerance) || degrees < kRotationSnapTolerance) {
        degrees = 0;
    } else {
        correct = NO;
    }
    
    return correct ? degrees * (M_PI / 180.0f) : angle;
}

- (CGAffineTransform) alignedTransform
{
    CGPoint a = CGPointZero; // pivot
    CGPoint b = CGPointMake(1.0f, 0.0f);
    
    a = CGPointApplyAffineTransform(a, transform_);
    b = CGPointApplyAffineTransform(b, transform_);
    
    CGPoint delta = WDSubtractPoints(b, a);
    float angle = atan2(delta.y, delta.x);
    float cleanAngle = [self cleanAngle:angle];
    
    if (cleanAngle == angle) {
        return transform_;
    }
    
    float scale = WDDistance(b, a);
    
    // rebuild bigger, stronger and faster
    CGAffineTransform tX = CGAffineTransformIdentity;
    tX = CGAffineTransformTranslate(tX, a.x, a.y);
    tX = CGAffineTransformScale(tX, scale, scale);
    tX = CGAffineTransformRotate(tX, cleanAngle);
    
    return tX;
}

- (void) updateTransform:(id)obj
{   
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void) delayedUpdateTransform
{   
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(updateTransform:) withObject:nil afterDelay:0.0f];
}

- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint loc = [sender translationInView:canvas];
        loc = WDMultiplyPointScalar(loc, 1.0f / canvas.scale * [UIScreen mainScreen].scale);
        [sender setTranslation:CGPointZero inView:canvas];
        
        CGAffineTransform tX = CGAffineTransformIdentity;
        tX = CGAffineTransformTranslate(tX, loc.x, loc.y);
        
        transform_ = CGAffineTransformConcat(transform_, tX);
        [self delayedUpdateTransform];
    }
}

- (IBAction) handlePinchGesture:(UIGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        initialScale_ = [(UIPinchGestureRecognizer *)sender scale];
        return;
    }
    
    float scale = [(UIPinchGestureRecognizer *)sender scale];
    float newScale = scale / initialScale_;
    
    if (newScale != 0 && sender.state == UIGestureRecognizerStateChanged) {
        CGPoint pivot = [sender locationInView:self.canvas];
        pivot = [self.canvas convertPointToDocument:pivot];
        
        CGAffineTransform tX = CGAffineTransformIdentity;
        tX = CGAffineTransformTranslate(tX, pivot.x, pivot.y);
        tX = CGAffineTransformScale(tX, newScale, newScale);
        tX = CGAffineTransformTranslate(tX, -pivot.x, -pivot.y);
        
        transform_ = CGAffineTransformConcat(transform_, tX);
        
        [self delayedUpdateTransform];
        
        initialScale_ = scale;
    }
}

- (void) handleRotationGesture:(UIRotationGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        initialAngle_ = [(UIRotationGestureRecognizer *)sender rotation];
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        float rotation  = [(UIRotationGestureRecognizer *)sender rotation];
        float angle = rotation  - initialAngle_;
        
        CGPoint pivot = [sender locationInView:self.canvas];
        pivot = [self.canvas convertPointToDocument:pivot];
        
        CGAffineTransform tX = CGAffineTransformIdentity;
        tX = CGAffineTransformTranslate(tX, pivot.x, pivot.y);
        tX = CGAffineTransformRotate(tX, angle);
        tX = CGAffineTransformTranslate(tX, -pivot.x, -pivot.y);

        transform_ = CGAffineTransformConcat(transform_, tX);
        [self delayedUpdateTransform];
        
        initialAngle_ = rotation;
    }
}

- (void) flipHorizontally:(id)sender
{
    self.horizontalFlip = !self.horizontalFlip;
    [self updateTransform:nil];
}

- (void) flipVertically:(id)sender
{
    self.verticalFlip = !self.verticalFlip;
    [self updateTransform:nil];
}

- (NSArray *) toolbarItems
{
    UIBarButtonItem *flipHorizontally = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Flip Horizontally", @"Flip Horizontally")
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self action:@selector(flipHorizontally:)];
                               
    UIBarButtonItem *flipVertically = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Flip Vertically", @"Flip Vertically")
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self action:@selector(flipVertically:)];
    
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil action:nil];
    
    NSArray *result = @[flipHorizontally, flexible, flipVertically];
    
    
    return result;
}

- (void) buildToolbar
{
    if (toolbar_) {
        return;
    }
    
    CGRect frame = self.bounds;
    frame.origin.y = CGRectGetHeight(self.bounds) - 44;
    frame.size.height = 44;
    toolbar_ = [[UIToolbar alloc] initWithFrame:frame];
    toolbar_.items = [self toolbarItems];
    toolbar_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    toolbar_.barStyle = UIBarStyleDefault;
    toolbar_.translucent = YES;
    
    [self addSubview:toolbar_];
}

- (void) buildNavBar
{
    if (navbar_) {
        return;
    }
    
    CGRect frame = self.bounds;
    frame.size.height = 44;
    navbar_ = [[UINavigationBar alloc] initWithFrame:frame];
    navbar_.barStyle = UIBarStyleDefault;
    navbar_.translucent = YES;
    navbar_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:self.title];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self action:@selector(cancel:)];
    
    UIBarButtonItem *accept = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Accept", @"Accept")
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self action:@selector(accept:)];
    
    navItem.leftBarButtonItem = cancel;
    navItem.rightBarButtonItem = accept;
    navItem.prompt = prompt;
    
    [navbar_ pushNavigationItem:navItem animated:NO];
    [self addSubview:navbar_];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    [self buildNavBar];
    
    if (showToolbar) {
        [self buildToolbar];
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

@end
