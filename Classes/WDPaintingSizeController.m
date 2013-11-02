//
//  WDPaintingSizeController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "NSArray+Additions.h"
#import "UIView+Additions.h"
#import "WDBrowserController.h"
#import "WDPaintingSizeController.h"
#import "WDUtilities.h"

NSString *WDPaintingSizeIndex = @"WDPaintingSizeIndex";
NSString *WDCustomSizeWidth = @"WDCustomSizeWidth";
NSString *WDCustomSizeHeight = @"WDCustomSizeHeight";
NSString *WDPaintingOrientationRotated = @"WDPaintingOrientationRotated";

const NSUInteger WDMinimumDimension = 64;
const NSUInteger WDMaximumDimension = 2048;

#define kWDEdgeBuffer 25

@interface WDGradientView : UIView
@property (nonatomic) CGPoint pivot;
@end

@implementation WDGradientView
@synthesize pivot;

+ (Class) layerClass {
    return [CAGradientLayer class];
}

- (void) setPivot:(CGPoint)inPivot
{
    pivot = inPivot;
    self.sharpCenter = pivot;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    CAGradientLayer *layer = (CAGradientLayer *) self.layer;
    layer.contents = (id) [UIImage imageNamed:@"swoosh.png"].CGImage;
    layer.contentsGravity = @"resizeAspect";
    
    layer.shadowOffset = CGSizeMake(0, 1);
    layer.shadowRadius = 2;
    layer.shadowOpacity = 0.25f;
    layer.colors = @[(id) [UIColor whiteColor].CGColor,
                    (id)([UIColor colorWithWhite:0.9f alpha:1.0f].CGColor)];
    
    return self;
}

@end

@implementation WDPaintingSizeController {
    UIView          *rotatingBackground;
    WDGradientView  *rotatingMiniCanvas;
}

@synthesize scrollView;
@synthesize pageControl;
@synthesize titleLabel;
@synthesize sizeLabel;
@synthesize xLabel;
@synthesize widthField;
@synthesize heightField;
@synthesize currentPage;
@synthesize rotateButton;
@synthesize configuration;
@synthesize width;
@synthesize height;
@synthesize browserController;
@synthesize miniCanvases;

+ (void) registerDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *path = WDCanUseHDTextures() ? @"DocSizes.plist" : @"DocSizes_LowRes.plist";
    NSString *settingsPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path];
    NSArray *docSizes = [NSArray arrayWithContentsOfFile:settingsPath];
    
    BOOL needToRebuildIndex = NO;
    
    if (![defaults objectForKey:WDPaintingSizeIndex]) {
        needToRebuildIndex = YES;
    } else {
        NSInteger currentIndex = [defaults integerForKey:WDPaintingSizeIndex];        
        needToRebuildIndex = (currentIndex < 0 || currentIndex >= docSizes.count) ? YES : NO;
    }
    
    if (needToRebuildIndex) {
        // find the best fit for this screen
        CGSize      screenSize = WDMultiplySizeScalar([UIScreen mainScreen].bounds.size, [UIScreen mainScreen].scale);
        NSInteger   myArea = screenSize.width * screenSize.height;
        NSInteger   currentIndex = 0, bestIndex = 0;
        NSInteger   bestDelta = INT32_MAX;
        NSNumber    *w, *h;
        BOOL        isCustom;
        
        for (NSDictionary *config in docSizes) {
            isCustom = config[@"Custom"] ? YES : NO;
            
            if (isCustom) {
                w = [[NSUserDefaults standardUserDefaults] objectForKey:WDCustomSizeWidth];
                h = [[NSUserDefaults standardUserDefaults] objectForKey:WDCustomSizeHeight];
            } else {
                w = config[@"Width"];
                h = config[@"Height"];
            }
            
            NSInteger area = [w integerValue] * [h integerValue];
            NSInteger delta = abs((int)(area - myArea));
            if (delta < bestDelta) {
                bestDelta = delta;
                bestIndex = currentIndex;
            }
            
            currentIndex++;
        }
        
        [defaults setObject:@(bestIndex) forKey:WDPaintingSizeIndex];
    }
    
    // set up the default size chooser orientations
    NSArray *landscapes = [defaults objectForKey:WDPaintingOrientationRotated];
    if (!landscapes || landscapes.count != docSizes.count) {
        NSArray *orientations = [NSArray arrayByReplicating:@NO times:docSizes.count];
        [defaults setObject:orientations forKey:WDPaintingOrientationRotated];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (!self) {
        return nil;
    }
    
    self.title = NSLocalizedString(@"New Painting", @"New Painting");
    self.miniCanvases = [NSMutableArray array];
    
    return self;
}

- (void) commitEdits
{
    [widthField endEditing:NO];
    [heightField endEditing:NO];
}

- (void) cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void) create:(id)sender
{
    [self commitEdits];
    
    [self.browserController createNewPainting:CGSizeMake(width, height)];
    [self dismissModalViewControllerAnimated:YES];
}

- (NSArray *) defaultToolbarItems
{
    self.pageControl = [[UIPageControl alloc] init];
    pageControl.numberOfPages = [self configuration].count;
    pageControl.defersCurrentPageDisplay = YES;
    [pageControl addTarget:self action:@selector(pageControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [pageControl sizeToFit];
    
    if (WDUseModernAppearance()) {
        pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    }

    CGRect frame = pageControl.frame;
    frame.size.width = 320;
    pageControl.frame = frame;
    
    UIBarButtonItem *pageItem = [[UIBarButtonItem alloc] initWithCustomView:pageControl];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                  target:nil action:nil];
    
    return @[flexibleItem, pageItem, flexibleItem];
}

- (BOOL) isCustomSize
{
    return (self.configuration)[currentPage][@"Custom"] ? YES : NO;
}

- (NSArray *) configuration
{
    if (!configuration) {
        NSString *docSizes = WDCanUseHDTextures() ? @"DocSizes.plist" : @"DocSizes_LowRes.plist";
        NSString *settingsPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:docSizes];
        configuration = [NSArray arrayWithContentsOfFile:settingsPath];
    }
    
    return configuration;
}

- (NSUInteger) maxDimension
{
    return WDCanUseHDTextures() ? WDMaximumDimension : WDMaximumDimension / 2;
}

- (float) canvasScalePercentage
{
    float percentage = MIN(CGRectGetWidth(scrollView.frame), CGRectGetHeight(scrollView.frame));
    percentage -= (kWDEdgeBuffer * 2);
    percentage /= [self maxDimension];
    
    return percentage;
}

- (void) handleDoubleTapGesture:(UIGestureRecognizer*)gestureRecognizer
{
    [self create:nil];
}

- (void) handleTapGesture:(UIGestureRecognizer*)gestureRecognizer
{
    [self rotate:nil];
}

- (void) configureScrollView
{
    WDGradientView *miniCanvas;
    
    CGSize contentSize = scrollView.bounds.size;
    contentSize.width = CGRectGetWidth(scrollView.bounds) * self.configuration.count;
    scrollView.contentSize = contentSize;
    scrollView.contentOffset = CGPointZero;
    
    CGPoint center = WDCenterOfRect(scrollView.bounds);
    float   offset = CGRectGetWidth(scrollView.frame);
    CGSize  size;
    int     ix = 0;
    BOOL    buildMiniCanvases = self.miniCanvases.count == 0 ? YES : NO;
    
    for (NSDictionary *dict in self.configuration) {
        size = [self sizeForPage:ix];
        
        float percentage = [self canvasScalePercentage];
        CGRect frame = CGRectMake(0, 0, size.width * percentage, size.height * percentage);
        frame = CGRectIntegral(frame);
        
        if (buildMiniCanvases) {
            miniCanvas = [[WDGradientView alloc] initWithFrame:frame];
            [scrollView addSubview:miniCanvas];
            miniCanvas.pivot = WDAddPoints(center, CGPointMake(offset * ix, 0));
            
            UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] init];
            [doubleTapRecognizer addTarget:self action:@selector(handleDoubleTapGesture:)];
            doubleTapRecognizer.numberOfTapsRequired = 2;
            [miniCanvas addGestureRecognizer:doubleTapRecognizer];
            
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] init];
            [tapRecognizer addTarget:self action:@selector(handleTapGesture:)];
            [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
            [miniCanvas addGestureRecognizer:tapRecognizer];
            
            miniCanvas.userInteractionEnabled = YES;
            [self.miniCanvases addObject:miniCanvas];
        } else {
            miniCanvas = miniCanvases[ix];
            miniCanvas.frame = frame;
            miniCanvas.pivot = WDAddPoints(center, CGPointMake(offset * ix, 0));
        }
     
        ix++;
    }
}

- (void) updateDimensions
{
    if ([self isCustomSize]) {
        widthField.text = [NSString stringWithFormat:@"%lu", (unsigned long)width];
        heightField.text = [NSString stringWithFormat:@"%lu", (unsigned long)height];
    } else {
        sizeLabel.text = [NSString stringWithFormat:@"%lu × %lu", (unsigned long)width, (unsigned long)height];
    }
    
    // update mini canvas
    WDGradientView *miniCanvas = (self.miniCanvases)[currentPage];
    
    float percentage = [self canvasScalePercentage];
    CGRect frame = CGRectMake(0, 0, width * percentage, height * percentage);
    frame = CGRectIntegral(frame);
    
    [UIView animateWithDuration:0.2f animations:^{
        CGPoint pivot = miniCanvas.pivot;
        
        float w = CGRectGetWidth(frame);
        float h = CGRectGetHeight(frame);
        CGRect adjustedFrame = CGRectMake(floorf(pivot.x - w / 2), floorf(pivot.y - h / 2), w, h);
        miniCanvas.frame = adjustedFrame;
    }];
}

- (void) rotate:(id)sender
{
    [self commitEdits];
    
    NSUInteger temp = width;
    self.width = height;
    self.height = temp;
    
    [self updateDimensions];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self isCustomSize]) {
        [defaults setFloat:width forKey:WDCustomSizeWidth];
        [defaults setFloat:height forKey:WDCustomSizeHeight];
    } else {
        BOOL landscape = (width > height) ? YES : NO;
        NSMutableArray *landscapeFlags = [[defaults objectForKey:WDPaintingOrientationRotated] mutableCopy];
        landscapeFlags[self.currentPage] = @(landscape);
        [defaults setObject:landscapeFlags forKey:WDPaintingOrientationRotated];
    }
}

- (void) fieldEdited:(UITextField *)sender
{
    NSNumberFormatter   *formatter = [[NSNumberFormatter alloc] init];
    NSNumber            *newValue = [formatter numberFromString:sender.text];
    
    if (newValue) {
        float value = roundf(WDClamp(WDMinimumDimension, [self maxDimension], newValue.floatValue));
        if (sender == widthField) {
            if (width != value) {
                self.width = value;
                [[NSUserDefaults standardUserDefaults] setFloat:value forKey:WDCustomSizeWidth];
                [self updateDimensions];
            }
        } else {
            if (height != value) {
                self.height = value;
                [[NSUserDefaults standardUserDefaults] setFloat:value forKey:WDCustomSizeHeight];
                [self updateDimensions];
            }
        }
    }
    
    // make sure the fields aren't stuck showing an invalid value
    widthField.text = [NSString stringWithFormat:@"%lu", (unsigned long)width];
    heightField.text = [NSString stringWithFormat:@"%lu", (unsigned long)height];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString        *proposed = textField.text;
    NSCharacterSet  *numericSet = [NSCharacterSet decimalDigitCharacterSet];
        
    if (![string isEqualToString:@"\n"]) {
        proposed = [proposed stringByReplacingCharactersInRange:range withString:string];
    }
    
    if (proposed.length == 0) {
        return YES;
    }
    
    for (NSUInteger ix = 0; ix < proposed.length; ix++) {
        unichar c = [proposed characterAtIndex:ix];
        if (![numericSet characterIsMember:c]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.toolbarHidden = NO;
    
    UIBarButtonItem *create = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Create", @"Create")
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(create:)];
    self.navigationItem.rightBarButtonItem = create;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancel;
    }
    
    self.view.backgroundColor = (WDUseModernAppearance() && !WDDeviceIsPhone()) ? nil : [UIColor colorWithWhite:0.95 alpha:1];
    self.toolbarItems = [self defaultToolbarItems];
    
    if (WDUseModernAppearance()) {
        // we don't want to go under the nav bar and tool bar
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
        UIImage *tintable = [[UIImage imageNamed:@"rotate.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [rotateButton setImage:tintable forState:UIControlStateNormal];
        [rotateButton setTintColor:[UIColor colorWithRed:0 green:(118.0f / 255.0f) blue:1 alpha:1]];
    }
    
    // add a gray bar to the title background view
    UIView *controlView = self.titleLabel.superview;
    CGRect frame = controlView.frame;
    frame.size.height = 1.0f / [UIScreen mainScreen].scale;
    frame.origin.y = CGRectGetHeight(controlView.frame) - frame.size.height;
    UIView *line = [[UIView alloc] initWithFrame:frame];
    line.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    line.backgroundColor = [UIColor lightGrayColor];
    [controlView addSubview:line];
    
    widthField.delegate = self;
    heightField.delegate = self;

    UIControlEvents eventFlags = (UIControlEventEditingDidEnd | UIControlEventEditingDidEndOnExit);
    [widthField addTarget:self action:@selector(fieldEdited:) forControlEvents:eventFlags];
    [heightField addTarget:self action:@selector(fieldEdited:) forControlEvents:eventFlags];

    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.opaque =  YES;
    
    self.contentSizeForViewInPopover = self.view.frame.size;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configureScrollView];
    
    self.currentPage = [[NSUserDefaults standardUserDefaults] integerForKey:WDPaintingSizeIndex];
    [self scrollToProperPage:NO];
    pageControl.currentPage = currentPage;
}

- (CGRect) currentMiniCanvasFrame
{
    WDGradientView *miniCanvas = miniCanvases[self.currentPage];
    CGRect frame = miniCanvas.frame;
    
    // account for scroll offset
    frame.origin.x -= scrollView.bounds.origin.x;
    
    return frame;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    rotatingBackground = [[UIView alloc] initWithFrame:scrollView.frame];
    rotatingBackground.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1];
    [self.view insertSubview:rotatingBackground aboveSubview:scrollView];
    
    rotatingMiniCanvas = [[WDGradientView alloc] initWithFrame:[self currentMiniCanvasFrame]];
    [rotatingBackground addSubview:rotatingMiniCanvas];
    rotatingMiniCanvas.sharpCenter = WDCenterOfRect(rotatingBackground.bounds);
    
    // turn off the rotating canvas shadow to improve performance while rotating
    rotatingMiniCanvas.layer.shadowOpacity = 0.0f;
    
    // ignore the scrollview for a bit
    scrollView.delegate = nil;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    scrollView.hidden = YES;
    
    // rebuild the world
    [UIView setAnimationsEnabled:NO];
    [self configureScrollView];
    scrollView.delegate = self;
    [self scrollToProperPage:NO];
    [UIView setAnimationsEnabled:YES];
    
    // we want this to animate
    rotatingMiniCanvas.frame = [self currentMiniCanvasFrame];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [rotatingBackground removeFromSuperview];
    rotatingBackground = nil;
    rotatingMiniCanvas = nil;
    
    scrollView.hidden = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) scrollToPage:(NSUInteger)ix animated:(BOOL)animated
{
    float offset = ix * CGRectGetWidth(scrollView.bounds);
    [scrollView setContentOffset:CGPointMake(offset, 0) animated:animated];
}

- (void) scrollToProperPage:(BOOL)animated
{
    [self scrollToPage:currentPage animated:animated];
}
     
- (void) pageControlValueChanged:(id)sender
{
    if (self.currentPage != pageControl.currentPage) {
        [self scrollToPage:pageControl.currentPage animated:YES];
    }
}

- (NSUInteger) maxValidPage
{
    return self.configuration.count;
}

- (void) scrollViewDidScroll:(UIScrollView *)inScrollView
{
    NSUInteger newPage = round(inScrollView.contentOffset.x / CGRectGetWidth(inScrollView.bounds));
    
    if (newPage >= [self maxValidPage]) {
        newPage = [self maxValidPage] - 1;
    }
    
    if (currentPage != newPage) {
        [self commitEdits];
        
        self.currentPage = newPage;
        pageControl.currentPage = newPage;
    }
}

- (CGSize) sizeForPage:(NSUInteger)page
{
    NSNumber    *w, *h;
    BOOL        isCustom = (self.configuration)[page][@"Custom"] ? YES : NO;
    
    if (isCustom) {
        w = [[NSUserDefaults standardUserDefaults] objectForKey:WDCustomSizeWidth];
        h = [[NSUserDefaults standardUserDefaults] objectForKey:WDCustomSizeHeight];
    } else {
        w = (self.configuration)[page][@"Width"];
        h = (self.configuration)[page][@"Height"];
        
        NSArray *landscapes = [[NSUserDefaults standardUserDefaults] objectForKey:WDPaintingOrientationRotated];
        if ([landscapes[page] boolValue]) {
            // swap
            NSNumber *temp = w;
            w = h;
            h = temp;
        }
    }
    
    return CGSizeMake([w integerValue], [h integerValue]);
}

- (void) setCurrentPage:(NSUInteger)inCurrentPage
{
    currentPage = inCurrentPage;
    
    titleLabel.text = (self.configuration)[currentPage][@"Name"];
    
    BOOL isCustomSize = [self isCustomSize];
    
    sizeLabel.hidden = isCustomSize;
    widthField.hidden = !isCustomSize;
    heightField.hidden = !isCustomSize;
    xLabel.hidden = !isCustomSize;
    
    CGSize size = [self sizeForPage:inCurrentPage];
    self.width = size.width;
    self.height = size.height;
    
    if (isCustomSize) {
        widthField.text = [NSString stringWithFormat:@"%lu", (unsigned long)width];
        heightField.text = [NSString stringWithFormat:@"%lu", (unsigned long)height];
    } else {
        sizeLabel.text = [NSString stringWithFormat:@"%lu × %lu", (unsigned long)width, (unsigned long)height];
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.currentPage forKey:WDPaintingSizeIndex];
}

@end
