//
//  WDCanvas.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "gl_matrix.h"
#import "UIView+Additions.h"
#import "UIImage+Additions.h"
#import "WDActiveState.h"
#import "WDAddImage.h"
#import "WDCanvas.h"
#import "WDCanvasController.h"
#import "WDColor.h"
#import "WDGLRegion.h"
#import "WDEyedropper.h"
#import "WDGLUtilities.h"
#import "WDLabel.h"
#import "WDLayer.h"
#import "WDModifyLayer.h"
#import "WDPanGestureRecognizer.h"
#import "WDTransformOverlay.h"
#import "WDTool.h"
#import "WDShader.h"
#import "WDShadowQuad.h"
#import "WDTexture.h"
#import "WDTransformLayer.h"
#import "WDUtilities.h"

#define kDissimalarAspectInset      44
#define kMaxZoom                    64.0f
#define kJumpToZoom                 3.0f
#define kMessageFadeDelay           0.5
#define kImageMessageFadeDelay      0.5
#define kMinimumMessageWidth        80
#define kDropperActivationDelay     0.5f
#define kDropperRadius              80
#define kDropperAnimationDuration   0.2f
#define kAnimationSteps             10

#define DEBUG_DIRTY_RECTS           NO

NSString *WDGestureBeganNotification = @"WDGestureBegan";
NSString *WDGestureEndedNotification = @"WDGestureEnded";

@interface WDCanvas (Private)
- (void) setTrueViewScale_:(float)scale;
- (void) rebuildViewTransform_;
- (void) rebuildViewTransformAndRedraw_:(BOOL)flag;
@end

@implementation WDCanvas {
    NSData *colorBits;
}

@synthesize scale = scale_;
@synthesize painting = painting_;
@synthesize controller = controller_;
@synthesize eyedropper = eyedropper_;
@synthesize context = context_;
@synthesize gesturesDisabled;
@synthesize isZooming;
@synthesize interfaceWasHidden;

@synthesize mainRegion;
@synthesize photo = photo_;
@synthesize photoTexture = photoTexture_;
@synthesize photoTransform = photoTransform_;
@synthesize layerTransform = layerTransform_;
@synthesize rawLayerTransform;
@synthesize rawPhotoTransform;
@synthesize hasEverBeenScaledToFit;
@synthesize shadowSegments;
@synthesize dirtyRect;
@synthesize currentlyPainting;

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (void) configureGestures
{
    // Create a long press recognizer to auto-activate the eyedropper tool
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    longPress.minimumPressDuration = kDropperActivationDelay;
    longPress.delegate = self;
    [self addGestureRecognizer:longPress];
    
    // Create a two finger tap double tap recognizer to auto-fit the doc
    UITapGestureRecognizer *twoFingerDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerDoubleTap:)];
    twoFingerDoubleTap.numberOfTouchesRequired = 2;
    twoFingerDoubleTap.numberOfTapsRequired = 2;
    twoFingerDoubleTap.delegate = self;
    [self addGestureRecognizer:twoFingerDoubleTap];
    
    // Create a two finger tap recognizer to auto-hide the interface
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerTap:)];
    twoFingerTap.numberOfTouchesRequired = 2;
    twoFingerTap.delegate = self;
    [twoFingerTap requireGestureRecognizerToFail:twoFingerDoubleTap];
    [self addGestureRecognizer:twoFingerTap];
    
    // create a one finger tap to auto-hide or paint a dot
    UITapGestureRecognizer *oneFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(oneTap:)];
    oneFingerTap.numberOfTouchesRequired = 1;
    oneFingerTap.delegate = self;
    [self addGestureRecognizer:oneFingerTap];
    
    // Create a pinch recognizer to scale the canvas
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(handlePinchGesture:)];
    pinchGesture.delegate = self;
    [self addGestureRecognizer:pinchGesture];
    
    // Create a pan gesture for painting
    WDPanGestureRecognizer *panGesture = [[WDPanGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.maximumNumberOfTouches = 1;
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];
    
//    // add a swipe left (3 fingers) to trigger undo
//    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
//    swipeLeft.delegate = self;
//    swipeLeft.numberOfTouchesRequired = 3;
//    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
//    [self addGestureRecognizer:swipeLeft];
//    
//    // add a swipe right (3 fingers) to trigger redo
//    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
//    swipeRight.delegate = self;
//    swipeRight.numberOfTouchesRequired = 3;
//    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
//    [self addGestureRecognizer:swipeRight];
//    
//    // constraints
//    [longPress requireGestureRecognizerToFail:swipeLeft];
//    [panGesture requireGestureRecognizerToFail:swipeLeft];
//    [pinchGesture requireGestureRecognizerToFail:swipeLeft];
//    
//    [longPress requireGestureRecognizerToFail:swipeRight];
//    [panGesture requireGestureRecognizerToFail:swipeRight];
//    [pinchGesture requireGestureRecognizerToFail:swipeRight];
}

- (void) swipeLeft:(UISwipeGestureRecognizer *)recognizer
{
    if (self.controller.isEditing) {
        [self.controller undo:nil];
    }
}

- (void) swipeRight:(UISwipeGestureRecognizer *)recognizer
{
    if (self.controller.isEditing) {
        [self.controller redo:nil];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.gesturesDisabled) {
        return NO;
    } else if (!self.controller.isEditing) {
        return ![gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]];
    }
    
    return YES;
}

- (id) initWithFrame:(CGRect)frame
{    
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    scale_ = 1.0f;
    canvasTransform_ = CGAffineTransformIdentity;
    
    self.multipleTouchEnabled = YES;
    self.contentMode = UIViewContentModeCenter;
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.exclusiveTouch = YES;
    self.opaque = YES;
    self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    
    [self configureGestures];
    
    return self;
}

- (id) initWithPainting:(WDPainting *)painting
{    
    self = [super initWithFrame:painting.bounds];
    
    if (!self) {
        return nil;
    }
    
    scale_ = 1.0f;

    self.multipleTouchEnabled = YES;
    self.contentMode = UIViewContentModeCenter;
    self.exclusiveTouch = YES;
    
    [self configureGestures];
    
    return self;
}

- (void) registerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidateFromNotification:)
                                                 name:WDLayersReorderedNotification
                                               object:painting_];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidateFromNotification:)
                                                 name:WDLayerAddedNotification
                                               object:painting_];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidateFromNotification:)
                                                 name:WDLayerDeletedNotification
                                               object:painting_];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidateFromNotification:)
                                                 name:WDLayerContentsChangedNotification
                                               object:painting_];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidateFromNotification:)
                                                 name:WDLayerVisibilityChanged
                                               object:painting_];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidateFromNotification:)
                                                 name:WDLayerOpacityChanged
                                               object:painting_];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidateFromNotification:)
                                                 name:WDLayerBlendModeChanged
                                               object:painting_];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidateFromNotification:)
                                                 name:WDStrokeAddedNotification
                                               object:painting_];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidateFromNotification:)
                                                 name:WDLayerTransformChangedNotification
                                               object:painting_];
}

- (void) setPainting:(WDPainting *)inPainting
{
    if (painting_ == inPainting) {
        return;
    }
    
    if (painting_) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:painting_];

        [EAGLContext setCurrentContext:painting_.context];
        [self.shadowSegments makeObjectsPerformSelector:@selector(freeGLResources)];
        
        self.shadowSegments = nil;
    }

    if (painting_.aspectRatio != inPainting.aspectRatio) {
        CGPoint centerOfOldPainting = CGPointMake(painting_.width / 2.0f, painting_.height / 2.0f);
        CGPoint centerOfNewPainting = CGPointMake(inPainting.width / 2.0f, inPainting.height / 2.0f);
                    
        deviceSpacePivot_ = CGPointApplyAffineTransform(centerOfOldPainting, canvasTransform_);
        userSpacePivot_ = centerOfNewPainting;
        
        [self rebuildViewTransformAndRedraw_:NO];
    }
    painting_ = inPainting;

    if (painting_) {
        [self registerNotifications];
        self.context = painting_.context;
        [self setNeedsLayout];
    }
}

- (CGPoint) constrainPointToPainting:(CGPoint)pt
{
    pt = [self convertPointToDocument:pt];
    pt.x = WDClamp(0.5f, self.painting.dimensions.width - 0.5f, pt.x);
    pt.y = WDClamp(0.5f, self.painting.dimensions.height - 0.5f, pt.y);
    pt = [self convertPointFromDocument:pt];
    
    return pt;
}

- (WDColor *) colorAtPoint:(CGPoint)pt
{
    pt = [self convertPointToDocument:pt];
    pt.x = WDClamp(0.5f, self.painting.dimensions.width - 0.5f, pt.x);
    pt.y = WDClamp(0.5f, self.painting.dimensions.height - 0.5f, pt.y);

    UInt8 pixel[4];
    NSUInteger loc = (int) pt.y * painting_.width * 4 + (int) pt.x * 4;
    [colorBits getBytes:pixel range:NSMakeRange(loc, 4)];
        
    float alpha = pixel[3] / 255.0f;
    
    // premultiply blend over white
    return [WDColor colorWithRed:(pixel[0] / 255.0f) + (1.0f - alpha)
                           green:(pixel[1] / 255.0f) + (1.0f - alpha)
                            blue:(pixel[2] / 255.0f) + (1.0f - alpha)
                           alpha:1.0f];
}

- (void) longPress:(UIGestureRecognizer*)gestureRecognizer
{
    CGPoint docLoc = [gestureRecognizer locationInView:self];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [controller_ hidePopovers];
        self.interfaceWasHidden = self.controller.interfaceHidden;
        [self.controller hideInterface];
        
        // make sure the bits are defined
        colorBits = [painting_ imageDataWithSize:painting_.dimensions backgroundColor:[UIColor whiteColor]];
        
        [self displayEyedropperAtPoint:docLoc];
        self.eyedropper.color = [self colorAtPoint:docLoc];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        [self moveEyedropperToPoint:docLoc];
        self.eyedropper.color = [self colorAtPoint:docLoc];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        WDColor *currentColor = [WDActiveState sharedInstance].paintColor;
        WDColor *pickedColor = [[self colorAtPoint:docLoc] colorWithAlphaComponent:currentColor.alpha];
        [WDActiveState sharedInstance].paintColor = pickedColor;
        [self dismissEyedropper];
        
        colorBits = nil;
        
        if (!self.interfaceWasHidden) {
            [self.controller showInterface];
        }
    }
}

- (void) twoFingerDoubleTap:(UIGestureRecognizer*)gestureRecognizer
{
    [controller_ hidePopovers];
    
    if (self.isScaledToFit) {
        CGPoint location = [gestureRecognizer locationInView:self];
        
        userSpacePivot_ = [self convertPointToDocument:location];
        
        location.y = CGRectGetHeight(self.bounds) - location.y;
        deviceSpacePivot_ = location;
        
        [self scaleBy:kJumpToZoom autoHide:YES animate:YES];
    } else {
        [self scaleDocumentToFit:YES];
    }
}

- (void) displayEyedropperAtPoint:(CGPoint)pt 
{
    if (eyedropper_) {
        return;
    }
    
    eyedropper_ = [[WDEyedropper alloc] initWithFrame:CGRectMake(0, 0, kDropperRadius * 2, kDropperRadius * 2)];
    
    eyedropper_.sharpCenter = [self convertPoint:[self constrainPointToPainting:pt] toView:self];
    [eyedropper_ setBorderWidth:20];
    
    [self.superview addSubview:eyedropper_];
}

- (void) moveEyedropperToPoint:(CGPoint)pt
{
    eyedropper_.sharpCenter = [self convertPoint:[self constrainPointToPainting:pt] toView:self];
}

- (void) dismissEyedropper
{
    [UIView animateWithDuration:kDropperAnimationDuration
                     animations:^{ eyedropper_.alpha = 0.0f; eyedropper_.transform = CGAffineTransformMakeScale(0.1f, 0.1f); }
                     completion:^(BOOL finished) {
                         [eyedropper_ removeFromSuperview];
                         eyedropper_ = nil;
                     }];
    
}

- (void) adjustForReplayScale:(float)scale
{
    if (scale != 1.0f) {
        float inverseScale = (1.0f / scale);
        userSpacePivot_ = WDMultiplyPointScalar(userSpacePivot_, scale);
        [self setTrueViewScale_:trueViewScale_ * inverseScale];
        [self rebuildViewTransformAndRedraw_:NO];
    }
}

- (float) fitScale
{
    CGRect  bounds = WDMultiplyRectScalar(self.superview.bounds, [UIScreen mainScreen].scale);
    float   documentAspect = painting_.dimensions.width / painting_.dimensions.height;
    float   boundsAspect = CGRectGetWidth(bounds) / CGRectGetHeight(bounds);
    BOOL    similarAspects = (documentAspect == boundsAspect) ? YES : NO;
    float   numerator, denominator;
    
    if (documentAspect > boundsAspect) {
        numerator = CGRectGetWidth(bounds);
        denominator = painting_.width;
    } else {
        numerator = CGRectGetHeight(bounds);
        denominator = painting_.height;
    }
    
    if (!similarAspects) {
        float extraPadding = self.controller.runningOnPhone ? 1.0 : 2.0f;
        numerator -= (kDissimalarAspectInset * [UIScreen mainScreen].scale * extraPadding);
    }
    
    return (numerator / denominator);
}

- (BOOL) isScaledToFit
{
    if (!self.painting) {
        return NO;
    }
    
    if (!CGPointEqualToPoint(userSpacePivot_, self.painting.center)) {
        return NO;
    }
    
    if (!CGPointEqualToPoint(deviceSpacePivot_, WDCenterOfRect(self.bounds))) {
        return NO;
    }
    
    if (trueViewScale_ != [self fitScale]) {
        return NO;
    }
    
    return YES;
}

- (void) scaleDocumentToFit:(BOOL)animated
{
    if (!self.painting) {
        return;
    }
    
    // note this, so that we can avoid resetting in particular cases
    hasEverBeenScaledToFit = YES;
    
    if (animated) {
        [self animateViewToScale:[self fitScale]];
    } else {
        [self setTrueViewScale_:[self fitScale]];
    }
    
    userSpacePivot_ = painting_.center;
    deviceSpacePivot_ = WDCenterOfRect(self.bounds);
    
    [self rebuildViewTransform_];
}

- (void) setScale:(float)scale
{
    scale_ = scale;
    
    [controller_ updateTitle];
}

- (CGSize) documentSize
{
    return painting_.dimensions;
}

- (CGRect) visibleRect
{
    CGAffineTransform   iTx = CGAffineTransformInvert(canvasTransform_);
    return CGRectApplyAffineTransform(self.bounds, iTx);
}

- (void) renderPhoto:(GLfloat *)proj withTransform:(CGAffineTransform)transform
{
    WDShader *blitShader = [self.painting getShader:@"nonPremultipliedBlit"];
    glUseProgram(blitShader.program);
    
    glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
    glUniform1i([blitShader locationForUniform:@"texture"], (GLuint) 0);
    glUniform1f([blitShader locationForUniform:@"opacity"], 1.0f);
    
    glActiveTexture(GL_TEXTURE0);
    // Bind the texture to be used
    glBindTexture(GL_TEXTURE_2D, photoTexture_.textureName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    CGRect rect = CGRectMake(0, 0, photo_.size.width, photo_.size.height);
    WDGLRenderInRect(rect, transform);
    WDCheckGLError();
}

- (CGRect) convertRectFromDocument:(CGRect)rect
{
    return CGRectApplyAffineTransform(rect, canvasTransform_);
}

- (void) updateIfNeeded
{
    if (CGRectEqualToRect(self.dirtyRect, CGRectZero)) {
        return;
    }
    
    [self drawViewInRect:self.dirtyRect];
}

- (void) drawViewAtEndOfRunLoop
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawView) object:nil];
    [self performSelector:@selector(drawView) withObject:nil afterDelay:0];
}

- (void) drawView
{
    [self drawViewInRect:[self visibleRect]];
}

- (void) drawViewInRect:(CGRect)rect
{
    float scale = [UIScreen mainScreen].scale;
    
    [EAGLContext setCurrentContext:self.context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, mainRegion.framebuffer);
    glViewport(0, 0, mainRegion.width, mainRegion.height);
    
    if (WDCanUseScissorTest()) {
        CGRect scissorRect = [self convertRectFromDocument:rect];
        scissorRect = WDMultiplyRectScalar(scissorRect, scale);
        scissorRect = CGRectIntegral(scissorRect);
        glScissor(scissorRect.origin.x, scissorRect.origin.y, scissorRect.size.width, scissorRect.size.height);
        glEnable(GL_SCISSOR_TEST);
    }
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    // handle viewing matrices
    GLfloat proj[16], effectiveProj[16], final[16];
    // setup projection matrix (orthographic)        
    mat4f_LoadOrtho(0, mainRegion.width / scale, 0, mainRegion.height / scale, -1.0f, 1.0f, proj);
    
    mat4f_LoadCGAffineTransform(effectiveProj, canvasTransform_);
    mat4f_MultiplyMat4f(proj, effectiveProj, final);
    
    [self drawWhiteBackground:final];

    // ask the painter to render
    [self.painting blit:final];

    // restore blending functions
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

    if (photoPlacementMode_) {
        [self renderPhoto:final withTransform:photoTransform_];
    }
    
    WDShader *blitShader = [self.painting getShader:@"straightBlit"];
    [WDShadowQuad configureBlit:final withShader:blitShader];
    for (WDShadowQuad *shadowSegment in self.shadowSegments) {
        [shadowSegment blitWithScale:self.scale];
    }

    if (DEBUG_DIRTY_RECTS) {
        WDColor *randomColor = [WDColor randomColor];
        glClearColor(randomColor.red, randomColor.green, randomColor.blue, 0.5f);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    glDisable(GL_SCISSOR_TEST);

    [mainRegion present];
    
    WDCheckGLError();
    
    self.dirtyRect = CGRectZero;
}

- (void) drawWhiteBackground:(GLfloat *)proj
{
    WDShader *blitShader = [self.painting getShader:@"simple"];

    glUseProgram(blitShader.program);

    glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
    glUniform4f([blitShader locationForUniform:@"color"], 1, 1, 1, 1);

    glBindVertexArrayOES(self.painting.quadVAO);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    // unbind VAO
    glBindVertexArrayOES(0);
}

- (NSArray *) shadowSegments
{
    if (!shadowSegments) {
        NSUInteger      index = 0;
        NSMutableArray  *segments = [NSMutableArray array];
        NSArray         *images = @[@"shadow_topleft.png", @"shadow_top.png", @"shadow_topright.png", @"shadow_right.png",
                                   @"shadow_bottomright.png", @"shadow_bottom.png", @"shadow_bottomleft.png", @"shadow_left.png"];
        
        for (NSString *imageName in images) {
            WDShadowQuad *quad = [WDShadowQuad imageQuadWithImage:[UIImage imageNamed:imageName]
                                                      dimension:(10.0 * [UIScreen mainScreen].scale)
                                                          segment:(WDShadowSegment)index++];
            quad.shadowedRect = self.painting.bounds;
            [segments addObject:quad];
        }

        shadowSegments = segments;
    }
    
    return shadowSegments;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [mainRegion resize];

    [self drawView];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [EAGLContext setCurrentContext:self.context];
    [self.shadowSegments makeObjectsPerformSelector:@selector(freeGLResources)];
    
    [self nixMessageLabel];
    [self nixImageMessageView];
    
    self.context = nil; // clears OpenGL objects
}

- (void)setContext:(EAGLContext *)context
{
    if (context == context_) {
        return;
    }

    context_ = context;
    
    if (context_) {
        mainRegion = [WDGLRegion regionWithContext:context_ andLayer:(CAEAGLLayer *) self.layer];
        [mainRegion resize];
    }
}

- (float) displayableScale
{    
    return round(self.scale * 100);
}

- (void) offsetUserSpacePivot:(CGPoint)delta
{
    userSpacePivot_ = WDAddPoints(userSpacePivot_, delta);
}

- (void) setFrame:(CGRect)frame
{
    if (self.painting) {
        [self resetUserSpacePivot];
        
        CGRect bounds = frame;
        bounds.origin = CGPointZero;
        deviceSpacePivot_ = WDCenterOfRect(bounds);
        
        [self rebuildViewTransformAndRedraw_:NO];
    }
    
    [super setFrame:frame];
}

- (void) resetUserSpacePivot
{
    userSpacePivot_ = [self convertPointToDocument:WDCenterOfRect(self.bounds)];
}

- (void) resetDeviceSpacePivot
{
    deviceSpacePivot_ = WDCenterOfRect(self.bounds);
    [self rebuildViewTransform_];
}
    
- (void) rebuildViewTransformAndRedraw_:(BOOL)flag
{    
    float screenScale = [UIScreen mainScreen].scale;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, deviceSpacePivot_.x, deviceSpacePivot_.y);
    transform = CGAffineTransformScale(transform, scale_ / screenScale, -scale_ / screenScale);
    transform = CGAffineTransformTranslate(transform, -userSpacePivot_.x, -userSpacePivot_.y);
    
    transform.tx = roundf(transform.tx);
    transform.ty = roundf(transform.ty);
    
    canvasTransform_ = transform;
    
    if (flag) {
        [self drawView];
    }
}

- (void) rebuildViewTransform_
{    
    [self rebuildViewTransformAndRedraw_:YES];
}

- (void) offsetByDelta:(CGPoint)delta
{
    deviceSpacePivot_ = WDAddPoints(deviceSpacePivot_, delta);
    [self rebuildViewTransform_];
}

- (void) setTrueViewScale_:(float)scale
{
    trueViewScale_ = scale;
    
    if (trueViewScale_ > 0.95f && trueViewScale_ < 1.05) {
        self.scale = 1.0f;
    } else {
        self.scale = trueViewScale_;
    }
}

- (float) minimumZoom
{
    float maxDimension = MAX(self.painting.width, self.painting.height);
    float minBounds = MIN(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
    
    float scale = ((minBounds / 2.0f) / maxDimension) * [UIScreen mainScreen].scale;

    return MIN(scale, 1.0);
}

- (void) scaleBy:(double)scale
{
    [self scaleBy:scale autoHide:NO animate:NO];
}

- (void) showZoomMessage:(BOOL)autoHide
{
    if (autoHide && !WDDeviceIsPhone() && !self.controller.interfaceHidden) {
        return;
    }
    
    int zoom = round(self.displayableScale);
    float yPosition = self.controller.runningOnPhone ? 80 : 128;
    [self showMessage:[NSString stringWithFormat:@"%d%%", zoom]
             autoHide:autoHide
             position:CGPointMake(CGRectGetMidX(self.superview.bounds), yPosition)
             duration:kMessageFadeDelay];
}

- (void) animateViewToScale:(float)endScale
{
    userSpacePivot_ = self.painting.center;
    deviceSpacePivot_ = [self convertPointFromDocument:userSpacePivot_];
    deviceSpacePivot_.y = CGRectGetHeight(self.bounds) - deviceSpacePivot_.y;

    CGPoint startDevicePivot = deviceSpacePivot_;
    CGPoint endDevicePivot = WDCenterOfRect(self.bounds);
    CGPoint deviceDelta = WDSubtractPoints(endDevicePivot, startDevicePivot);
    float   startScale = scale_;
    float   scaleDelta = endScale - startScale;
    float   step = 1.0f / kAnimationSteps;
    
    self.painting.flattenMode = !(self.controller.replay.isPlaying);
    
    for (float t = step; t < 1.0f; t += step) {
        float interpT = WDSineCurve(t);
        scale_ = startScale + (interpT * scaleDelta);
        deviceSpacePivot_ = WDAddPoints(startDevicePivot, WDMultiplyPointScalar(deviceDelta, interpT));
        [self rebuildViewTransform_];
    }
    
    deviceSpacePivot_ = endDevicePivot;
    [self setTrueViewScale_:endScale];
    [self rebuildViewTransform_];
    
    self.painting.flattenMode = NO;

    [self showZoomMessage:YES];
}

- (void) doScaleAnimationFrom:(float)start to:(float)end
{
    float delta = end - start;
    float step = 1.0f / kAnimationSteps;
    
    self.painting.flattenMode = !(self.controller.replay.isPlaying);
    
    for (float t = step; t < 1.0f; t += step) {
        scale_ = start + WDSineCurve(t) * delta;
        [self rebuildViewTransform_];
    }
    
    [self setTrueViewScale_:end];
    [self rebuildViewTransform_];
    
    self.painting.flattenMode = NO;
}

- (void) scaleBy:(double)scale autoHide:(BOOL)autoHide animate:(BOOL)animate
{
    float minZoom = [self minimumZoom];
    
    if (scale * scale_ > kMaxZoom) {
        scale = kMaxZoom / scale_;
    } else if (scale * scale_ < minZoom) {
        scale = minZoom / scale_;
    }
    
    float finalScale = trueViewScale_ * scale;
    
    if (animate) {
        [self doScaleAnimationFrom:scale_ to:finalScale];
    } else {
        [self setTrueViewScale_:finalScale];
        [self rebuildViewTransform_];
    }
    
    [self showZoomMessage:autoHide];
}

- (BOOL) canSendTouchToActiveTool
{
    if (!self.controller.isEditing) {
        return NO;
    }
    
    BOOL    locked = painting_.activeLayer.locked;
    BOOL    hidden = !painting_.activeLayer.visible;
    
    return !(locked || hidden);
}

- (CGPoint) convertPointToDocument:(CGPoint)pt
{
    pt.y = CGRectGetHeight(self.bounds) - pt.y;
    
    CGAffineTransform iTx = CGAffineTransformInvert(canvasTransform_);
    CGPoint transformed = CGPointApplyAffineTransform(pt, iTx);
    
    return transformed;
}

- (CGPoint) convertPointFromDocument:(CGPoint)pt
{
    pt = CGPointApplyAffineTransform(pt, canvasTransform_);
    pt.y = CGRectGetHeight(self.bounds) - pt.y;
    return pt;
}

- (void) handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        [controller_ hidePopovers];
        
        CGPoint flipped = [sender locationInView:self];
        flipped.y = CGRectGetHeight(self.bounds) - flipped.y;
        deviceSpacePivot_ = flipped;
        
        userSpacePivot_ = [self convertPointToDocument:[sender locationInView:self]];
        
        lastTouchCount_ = sender.numberOfTouches;
        correction_ = CGPointZero;
        
        self.isZooming = YES;
        self.interfaceWasHidden = self.controller.interfaceHidden;
        self.painting.flattenMode = !(self.controller.replay.isPlaying);
        
        [self.controller hideInterface];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint flipped = [sender locationInView:self];
        flipped.y = CGRectGetHeight(self.bounds) - flipped.y;
        
        if (sender.numberOfTouches != lastTouchCount_) {
            correction_ = WDSubtractPoints(deviceSpacePivot_, flipped);
            lastTouchCount_ = sender.numberOfTouches;
        }
        
        deviceSpacePivot_ = WDAddPoints(flipped, correction_);
        [self scaleBy:sender.scale / previousScale_]; 
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        self.isZooming = NO;        
        [self nixMessageLabel];
        
        if (!self.interfaceWasHidden) {
            [self.controller showInterface];
        }
        
        self.painting.flattenMode = NO;
    }
    
    previousScale_ = sender.scale;
}

- (void) showCannotEditMessage
{
    if (!self.controller.isEditing) {
        return;
    }
    
    BOOL    locked = painting_.activeLayer.locked;
    BOOL    hidden = !painting_.activeLayer.visible;
    
    NSMutableArray *images = [NSMutableArray array];
    
    if (locked) {
        [images addObject:[UIImage imageNamed:@"lockMessage.png"]];
    }
    
    if (hidden){
        [images addObject:[UIImage imageNamed:@"hiddenMessage.png"]];
    }
    
    [self showImageMessage:images];
}

- (void) twoFingerTap:(UITapGestureRecognizer *)sender
{
    [controller_ hidePopovers];
    [self.controller oneTap:sender];
}

- (void) oneTap:(UITapGestureRecognizer *)sender
{
    if (controller_.popoverVisible) {
        [controller_ hidePopovers];
        return;
    }
    
    BOOL oneFingerTapsCanPaint = [[NSUserDefaults standardUserDefaults] boolForKey:@"WDTwoFingerInterfaceToggle"];
    
    if (!self.controller.editing || !oneFingerTapsCanPaint) {
        [self.controller oneTap:sender];
        return;
    }
    
    if (![self canSendTouchToActiveTool]) {
        [self showCannotEditMessage];
        return;
    }
    
    [[WDActiveState sharedInstance].activeTool gestureBegan:sender];
    [[WDActiveState sharedInstance].activeTool gestureEnded:sender];
}

- (void) handlePanGesture:(WDPanGestureRecognizer *)sender
{
    if (![self canSendTouchToActiveTool]) {
        [self showCannotEditMessage];
        return;
    }
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WDGestureBeganNotification object:nil];
        currentlyPainting = YES;
        [controller_ hidePopovers];
        [[WDActiveState sharedInstance].activeTool gestureBegan:sender];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        [[WDActiveState sharedInstance].activeTool gestureMoved:sender];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WDGestureEndedNotification object:nil];
        currentlyPainting = NO;
        [[WDActiveState sharedInstance].activeTool gestureEnded:sender];
    } else if (sender.state == UIGestureRecognizerStateCancelled) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WDGestureEndedNotification object:nil];
        currentlyPainting = NO;
        [[WDActiveState sharedInstance].activeTool gestureCanceled:sender];
    }
}

- (void) cancelUpdate
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateIfNeeded) object:nil];
}

- (void) invalidateFromNotification:(NSNotification *)aNotification
{    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateIfNeeded) object:nil];
    [self performSelector:@selector(updateIfNeeded) withObject:nil afterDelay:0.0f];

    NSDictionary *userInfo = aNotification.userInfo;
    if (userInfo && userInfo[@"rect"]) {
        NSValue *rect = userInfo[@"rect"];
        self.dirtyRect = WDUnionRect(self.dirtyRect, rect.CGRectValue);
    } else {
        self.dirtyRect = [self visibleRect];
    }
}

- (void) startActivity
{
    if (self.superview) {
        activityView_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        // make sure this doesn't look fuzzy
        activityView_.sharpCenter = WDCenterOfRect(self.superview.bounds);
        
        [self.superview addSubview:activityView_];
        
        [activityView_ startAnimating];
        [CATransaction flush];
    }
}

- (void) stopActivity
{
    if (activityView_) {
        [activityView_ stopAnimating];
        [activityView_ removeFromSuperview];
        activityView_ = nil;
    }
}

- (void) nixMessageLabel
{
    if (messageTimer_) {
        [messageTimer_ invalidate];
        messageTimer_ = nil;
    }
    
    if (messageLabel_) {
        [messageLabel_ removeFromSuperview];
        messageLabel_ = nil;
    }
}

- (void) nixImageMessageView
{
    if (imageMessageTimer_) {
        [imageMessageTimer_ invalidate];
        imageMessageTimer_ = nil;
    }
    
    if (imageMessageView_) {
        [imageMessageView_ removeFromSuperview];
        imageMessageView_ = nil;
    }
}

- (void) hideMessage:(NSTimer *)timer
{
    [UIView animateWithDuration:0.2f
                     animations:^{ messageLabel_.alpha = 0.0f; }
                     completion:^(BOOL finished) {
                         [self nixMessageLabel];
                     }];
   
}

- (void) hideImageMessage:(NSTimer *)timer
{
    [UIView animateWithDuration:0.2f
                     animations:^{ imageMessageView_.alpha = 0.0f; }
                     completion:^(BOOL finished) {
                         [self nixImageMessageView];
                     }];
    
}

- (void) showImageMessage:(NSArray *)images
{
    if (!imageMessageView_) {
        NSMutableArray  *imageViews = [NSMutableArray array];
        float           totalWidth = 0;
        float           maxHeight = 0;
        
        // create an image view for each image, and simultaneously compute bounds
        for (UIImage *image in images) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            [imageViews addObject:imageView];
            
            totalWidth += CGRectGetWidth(imageView.frame);
            maxHeight = MAX(maxHeight, CGRectGetHeight(imageView.frame));
            
        }
        
        // create a view to hold the image views
        imageMessageView_ = [[UIView alloc] initWithFrame:CGRectMake(0, 0, totalWidth, maxHeight)];
        imageMessageView_.backgroundColor = nil;
        
        // add the sub image views
        float offset = 0;
        for (UIImageView *imageView in imageViews) {
            imageView.frame = CGRectOffset(imageView.frame, offset, 0);
            [imageMessageView_ addSubview:imageView];
            offset += CGRectGetWidth(imageView.frame);
        }
        
        // give the parent view a nice shadow to offset it against the background
        CALayer *layer = imageMessageView_.layer;
        layer.shadowOpacity = 0.5f;
        layer.shadowRadius = 3;
        layer.shadowOffset = CGSizeZero;
        layer.rasterizationScale = [UIScreen mainScreen].scale;
        layer.shouldRasterize = YES;
        
        // center and show the message view
        imageMessageView_.sharpCenter = WDCenterOfRect(self.superview.bounds);
        [self.superview addSubview:imageMessageView_];
    }
    
    if (imageMessageTimer_) {
        [imageMessageTimer_ invalidate];
        imageMessageTimer_ = nil;
    }
    
    imageMessageTimer_ = [NSTimer scheduledTimerWithTimeInterval:kImageMessageFadeDelay
                                                          target:self
                                                        selector:@selector(hideImageMessage:)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void) showMessage:(NSString *)message
{
    [self showMessage:message autoHide:YES position:WDCenterOfRect(self.superview.bounds) duration:kMessageFadeDelay];
}

- (void) showMessage:(NSString *)message autoHide:(BOOL)autoHide position:(CGPoint)position duration:(float)duration
{
    BOOL created = NO;
    
    [self nixImageMessageView];
    
    if (!messageLabel_) {
        messageLabel_ = [[WDLabel alloc] initWithFrame:CGRectInset(CGRectMake(0,0,100,40), -8, -8)];
        messageLabel_.textColor = [UIColor whiteColor];
        messageLabel_.font = [UIFont boldSystemFontOfSize:24.0f];
        messageLabel_.textAlignment = UITextAlignmentCenter;
        messageLabel_.opaque = NO;
        messageLabel_.backgroundColor = nil;
        messageLabel_.alpha = 0;
        
        created = YES;
    }
    
    if ([message length] > 20 && self.controller.runningOnPhone) {
        messageLabel_.font = [UIFont boldSystemFontOfSize:15.0f];
    } else {
        messageLabel_.font = [UIFont boldSystemFontOfSize:24.0f];
    }
    
    messageLabel_.text = message;
    [messageLabel_ sizeToFit];
    
    CGRect frame = messageLabel_.frame;
    frame.size.width = MAX(frame.size.width, kMinimumMessageWidth);
    frame = CGRectInset(frame, -20, -15);
    messageLabel_.frame = frame;
    messageLabel_.sharpCenter = position;
    
    if (created) {
        [self.superview addSubview:messageLabel_];
        
        [UIView animateWithDuration:0.2f animations:^{ messageLabel_.alpha = 1; }];
    }
    
    // start message dismissal timer
    if (messageTimer_) {
        [messageTimer_ invalidate];
        messageTimer_ = nil;
    }
    
    if (autoHide) {
        messageTimer_ = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideMessage:) userInfo:nil repeats:NO];
    }
}

- (void) updateFromSettings:(NSDictionary *)settings
{
    scale_ = [settings[@"scale"] floatValue];
    trueViewScale_ = [settings[@"trueViewScale"] floatValue];
    userSpacePivot_ = [settings[@"userSpacePivot"] CGPointValue];
    deviceSpacePivot_ = [settings[@"deviceSpacePivot"] CGPointValue];
    
    [self rebuildViewTransform_];
}

- (NSDictionary *) viewSettings
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"scale"] = @(scale_);
    dict[@"trueViewScale"] = @(trueViewScale_);
    dict[@"userSpacePivot"] = [NSValue valueWithCGPoint:userSpacePivot_];
    dict[@"deviceSpacePivot"] = [NSValue valueWithCGPoint:deviceSpacePivot_];
    
    return dict;
}

@end

@implementation WDCanvas (WDPlacePhotoMode)

- (CGAffineTransform) photoFlipTransform
{
    CGAffineTransform flip = CGAffineTransformIdentity;
    
    if (transformOverlay_.horizontalFlip || transformOverlay_.verticalFlip) {
        CGPoint center = CGPointMake(photo_.size.width / 2, photo_.size.height / 2);
        flip = CGAffineTransformTranslate(flip, center.x, center.y);
        flip = CGAffineTransformScale(flip, (transformOverlay_.horizontalFlip ? -1 : 1), (transformOverlay_.verticalFlip ? -1 : 1));
        flip = CGAffineTransformTranslate(flip, -center.x, -center.y);
    }
    
    return flip;
}

- (void) photoTransformChanged:(WDTransformOverlay *)sender
{
    rawPhotoTransform = sender.alignedTransform;
    photoTransform_ = CGAffineTransformConcat([self photoFlipTransform], rawPhotoTransform);
    
    [self drawView];
}

- (void) beginPhotoPlacement:(UIImage *)image
{
    [self.controller hideInterface];
    
    transformOverlay_ = [[WDTransformOverlay alloc] initWithFrame:self.superview.frame];
    transformOverlay_.userInteractionEnabled = YES;
    [self.superview addSubview:transformOverlay_];
    
    if ([image hasAlpha] && ![image reallyHasAlpha]) {
        // the image thinks it has alpha, but it really doesn't, so let's make it a JPEG
        image = [image JPEGify:1.0];
    }
    
    self.photo = image;
    self.photoTexture = [WDTexture textureWithImage:image];
    transformOverlay_.prompt = NSLocalizedString(@"Drag and pinch to position photo.",
                                                 @"Drag and pinch to position photo.");
    transformOverlay_.title = NSLocalizedString(@"Place Photo", @"Place Photo");
    transformOverlay_.alpha = 0.0f; // for fade in
    transformOverlay_.showToolbar = YES;
    transformOverlay_.canvas = self;
    
    __unsafe_unretained WDCanvas *canvas = self;
    transformOverlay_.cancelBlock = ^{ [canvas cancelPhotoPlacement]; };
    transformOverlay_.acceptBlock = ^{ [canvas placePhoto]; };
    
    [transformOverlay_ addTarget:self action:@selector(photoTransformChanged:)
                forControlEvents:UIControlEventValueChanged];
    
    photoTransform_ = [transformOverlay_ configureInitialPhotoTransform];
    rawPhotoTransform = photoTransform_;
    
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                     animations:^{ transformOverlay_.alpha = 1.0f; }
                     completion:^(BOOL finished) {
                     }];
    
    photoPlacementMode_ = YES;
    [self drawView];
}

- (void) cancelPhotoPlacement
{
    if (!self.controller.runningOnPhone) {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                         animations:^{ transformOverlay_.alpha = 0.0f; }
                         completion:^(BOOL finished) {
                             [transformOverlay_ removeFromSuperview];
                             transformOverlay_ = nil;
                             
                             [self.controller showInterface];
                         }];
    } else {
        [transformOverlay_ removeFromSuperview];
        transformOverlay_ = nil;
        
        [self.controller showInterface];
    }
    
    self.photo = nil;
    
    [EAGLContext setCurrentContext:self.painting.context];
    [self.photoTexture freeGLResources];
    self.photoTexture = nil;
    
    photoPlacementMode_ = NO;
    [self drawView];
}

- (void) placePhoto
{
    photoTransform_ = CGAffineTransformConcat([self photoFlipTransform], rawPhotoTransform);
    
    NSUInteger  index = [painting_ layers].count;
    BOOL mergeDown = NO;
    changeDocument(painting_, [WDAddImage addImage:photo_ atIndex:index mergeDown:mergeDown transform:photoTransform_]);
    
    [self cancelPhotoPlacement];
}

@end

@implementation WDCanvas (WDLayerTransformMode)

- (void) layerTransformChanged:(WDTransformOverlay *)sender
{
    CGAffineTransform flip = CGAffineTransformIdentity;
    
    if (sender.horizontalFlip || sender.verticalFlip) {
        CGPoint center = WDCenterOfRect(self.painting.bounds);
        flip = CGAffineTransformTranslate(flip, center.x, center.y);
        flip = CGAffineTransformScale(flip, (sender.horizontalFlip ? -1 : 1), (sender.verticalFlip ? -1 : 1));
        flip = CGAffineTransformTranslate(flip, -center.x, -center.y);
    }
    
    rawLayerTransform = sender.alignedTransform;
    layerTransform_ = CGAffineTransformConcat(flip, rawLayerTransform);
    self.painting.activeLayer.transform = layerTransform_;
}

- (void) beginLayerTransformation
{
    [self.controller hideInterface];
    
    transformOverlay_ = [[WDTransformOverlay alloc] initWithFrame:self.superview.frame];
    transformOverlay_.userInteractionEnabled = YES;
    [self.superview addSubview:transformOverlay_];
    
    transformOverlay_.prompt = NSLocalizedString(@"Drag and pinch to position layer.",
                                                 @"Drag and pinch to position layer.");
    transformOverlay_.title = NSLocalizedString(@"Transform Layer", @"Transform Layer");
    transformOverlay_.showToolbar = controller_.runningOnPhone ? YES : NO;
    transformOverlay_.alpha = 0.0f; // for fade in
    transformOverlay_.canvas = self;
    
    __unsafe_unretained WDCanvas *canvas = self;
    transformOverlay_.cancelBlock = ^{ [canvas cancelLayerTransformation]; };
    transformOverlay_.acceptBlock = ^{ [canvas transformActiveLayer]; };
    
    [transformOverlay_ addTarget:self action:@selector(layerTransformChanged:)
                forControlEvents:UIControlEventValueChanged];
            
    layerTransform_ = CGAffineTransformIdentity;
    rawLayerTransform = CGAffineTransformIdentity;
    
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                     animations:^{ transformOverlay_.alpha = 1.0f; }
                     completion:^(BOOL finished) {
                     }];

    [self.painting.activeLayer enableLinearInterpolation:YES];
    self.painting.activeLayer.transform = layerTransform_;
}

- (void) cancelLayerTransformation
{    
    if (!self.controller.runningOnPhone) {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                         animations:^{ transformOverlay_.alpha = 0.0f; }
                         completion:^(BOOL finished) {
                             [transformOverlay_ removeFromSuperview];
                             transformOverlay_ = nil;
                             
                             [self.controller showInterface];
                         }];
    } else {
        [transformOverlay_ removeFromSuperview];
        transformOverlay_ = nil;
        
        [self.controller showInterface];
    }
    
    [self.painting.activeLayer enableLinearInterpolation:NO];
    self.painting.activeLayer.transform = CGAffineTransformIdentity;
}

- (void) transformActiveLayer
{
    if (transformOverlay_.horizontalFlip) {
        changeDocument(self.painting, [WDModifyLayer modifyLayer:self.painting.activeLayer withOperation:WDFlipLayerHorizontal]);
    }
    
    if (transformOverlay_.verticalFlip) {
        changeDocument(self.painting, [WDModifyLayer modifyLayer:self.painting.activeLayer withOperation:WDFlipLayerVertical]);
    }
    
    // only change the doc if the transform actually changed
    if (!CGAffineTransformIsIdentity(rawLayerTransform)) {
        changeDocument(self.painting, [WDTransformLayer transformLayer:self.painting.activeLayer transform:rawLayerTransform]);
    }
    
    [self cancelLayerTransformation];
}

@end
