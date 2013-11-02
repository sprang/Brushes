//
//  WDColorBalanceController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDAppDelegate.h"
#import "WDBlockingView.h"
#import "WDCanvas.h"
#import "WDCanvasController.h"
#import "WDColor.h"
#import "WDColorAdjustmentController.h"
#import "WDLayer.h"
#import "WDModalTitleBar.h"
#import "WDPaletteBackgroundView.h"
#import "UIView+Additions.h"

#define kCornerRadius       7
#define kVelocityDampening  0.85f
#define kEdgeBuffer         5

@interface WDTouchEatingView : UIView
@end

@implementation WDTouchEatingView

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

@end

@implementation WDColorAdjustmentController

@synthesize formatter = formatter_;
@synthesize painting = painting_;
@synthesize canvas;
@synthesize defaultsName;


- (void) blockingViewTapped:(id)sender
{
    // run a little pop animation to show that the modal panel needs to be dismissed
    
    [UIView animateWithDuration:0.1f
                     animations:^{
                         self.view.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.1f
                                          animations:^{
                                              self.view.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.1f
                                                               animations:^{
                                                                   self.view.transform = CGAffineTransformIdentity;      
                                                               }
                                               ];
                                          }
                          ];
                     }
     ];
}

- (void) dismissAnimated:(BOOL)animated
{
    [blockingView_ removeFromSuperview];
    blockingView_ = nil;

    [super viewWillDisappear:animated];
    
    if (animated) {
        [UIView animateWithDuration:0.2f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{ self.view.alpha = 0; }
                         completion:^(BOOL finished){ 
                             [self.view removeFromSuperview];
                             // release the view to avoid a corruption bug that occurs sometimes after 
                             // repeatedly hiding/showing the panel and rotating the device
                             self.view = nil;
                             [super viewDidDisappear:animated];
                             self.canvas.gesturesDisabled = NO;
                         }];
    } else {
        [self.view removeFromSuperview];
        [super viewDidDisappear:animated];
        self.canvas.gesturesDisabled = NO;
        self.view = nil;
    }
    
    [self.canvas.controller showInterface]; 
}

- (IBAction) cancel:(id)sender
{
    [painting_.activeLayer tossColorAdjustments];
    [self.canvas drawView];
    
    [self dismissAnimated:NO];
}

- (IBAction) accept:(id)sender
{    
    [self dismissAnimated:NO];
}

- (NSNumberFormatter *) formatter
{
    if (!formatter_) {
        formatter_ = [[NSNumberFormatter alloc] init];
        
        [formatter_ setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatter_ setMaximumFractionDigits:0];
        [formatter_ setUsesGroupingSeparator:NO];
        [formatter_ setPositiveFormat:@"+###"];
        [formatter_ setNegativeFormat:@"-###"];
        [formatter_ setZeroSymbol:@"0"];
    }
    
    return formatter_;
}

- (void) resetShiftsToZero
{
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    UIView *panView = [[WDTouchEatingView alloc] initWithFrame:CGRectInset(navBar_.frame, 75, 0)];
    panView.backgroundColor = nil;
    panView.opaque = NO;
    [self.view addSubview:panView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [panView addGestureRecognizer:panGesture];
    panView.exclusiveTouch = YES;
    panGesture.delaysTouchesBegan = YES;
    panGesture.delegate = self;
        
    background_.cornerRadius = kCornerRadius;
    background_.roundedCorners = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    
    navBar_.cornerRadius = kCornerRadius;
    navBar_.roundedCorners = UIRectCornerTopLeft | UIRectCornerTopRight;
    
    self.view.backgroundColor = nil;
    self.view.opaque = NO;
    
    // add a shadow
    CALayer *layer = self.view.layer;
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.view.bounds cornerRadius:kCornerRadius];
    layer.shadowPath = shadowPath.CGPath;
    layer.shadowOpacity = 0.4f;
    layer.shadowRadius = 2;
    layer.shadowOffset = CGSizeZero;
}

- (CGRect) constrainRect
{
    return self.view.superview.bounds;
}

- (void) constrainOriginToSuperview:(CGPoint)origin animated:(BOOL)animated
{
    CGRect frame = self.view.frame;
    
    CGRect constrain = CGRectInset([self constrainRect], kEdgeBuffer, kEdgeBuffer);
    constrain.size.width -= CGRectGetWidth(frame);
    constrain.size.height -= CGRectGetHeight(frame);
    
    frame.origin.x = WDClamp(CGRectGetMinX(constrain), CGRectGetMaxX(constrain), origin.x);
    frame.origin.y = WDClamp(CGRectGetMinY(constrain), CGRectGetMaxY(constrain), origin.y);
    
    if (animated) {
        [UIView animateWithDuration:0.3f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{ self.view.sharpCenter = WDCenterOfRect(frame); }
                         completion:NULL];
    } else {
        self.view.sharpCenter = WDCenterOfRect(frame);
    }
}

- (void) bringOnScreenAnimated:(BOOL)animated
{
    if (CGRectContainsRect([self constrainRect], self.view.frame)) {
        return;
    }
    
    [self constrainOriginToSuperview:self.view.frame.origin animated:animated];
}

- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    UIView *view = sender.view.superview;
    
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateChanged) {
        CGPoint pan = [sender translationInView:view];

        self.view.sharpCenter = WDAddPoints(self.view.center, pan);
        [sender setTranslation:CGPointZero inView:view];
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [sender velocityInView:view];
        
        BOOL xSign = (velocity.x < 0) ? -1 : 1;
        BOOL ySign = (velocity.y < 0) ? -1 : 1;
        
        velocity.x = powf(fabs(velocity.x), kVelocityDampening) * xSign;
        velocity.y = powf(fabs(velocity.y), kVelocityDampening) * ySign;
        
        if (WDDistance(velocity, CGPointZero) > 128) {
            CGPoint endPoint = WDAddPoints(self.view.frame.origin, velocity);
            [self constrainOriginToSuperview:endPoint animated:YES];
        } else {
            [self bringOnScreenAnimated:YES];   
        }
        
        [[NSUserDefaults standardUserDefaults] setValue:NSStringFromCGPoint(self.view.frame.origin) forKey:self.defaultsName];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void) runModalOverView:(WDCanvas *)view
{
    blockingView_ = [[WDBlockingView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    WDAppDelegate *delegate = (WDAppDelegate *) [UIApplication sharedApplication].delegate;
    
    blockingView_.passthroughViews = @[self.view];

    blockingView_.target = self;
    blockingView_.action = @selector(blockingViewTapped:);
    
    [delegate.window addSubview:blockingView_];
    
    // adjust frame origin
    NSString *originString = [[NSUserDefaults standardUserDefaults] objectForKey:self.defaultsName];
    CGPoint origin = WDCenterOfRect(view.bounds);
    origin = WDSubtractPoints(origin, CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2));
    origin = WDFloorPoint(origin);
    
    if (originString) {
        origin = CGPointFromString(originString);
    }
    
    CGRect frame = self.view.frame;
    frame.origin = origin;
    self.view.sharpCenter = WDCenterOfRect(frame);
    
    [self resetShiftsToZero];
    
    [super viewWillAppear:NO];
    [view.superview addSubview:self.view];
    [super viewDidAppear:NO];
    
    // make sure it's on screen (the device might have rotated since we last saved the frame)
    [self bringOnScreenAnimated:NO];
    
    self.canvas = view;
    self.canvas.gesturesDisabled = YES;
    
    [self.canvas.controller hideInterface];
}

@end
