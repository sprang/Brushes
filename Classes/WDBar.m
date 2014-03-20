//
//  WDBar.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDBar.h"
#import "WDUtilities.h"

const NSUInteger    kWDDefaultBarHeight = 44;
const NSUInteger    kWDLandscapePhoneBarHeight = 32;
const float         kWDBarItemShadowOpacity = 0.9f;

@implementation WDBarItem

@synthesize view;
@synthesize landscapeView;
@synthesize type;
@synthesize width;
@synthesize enabled;
@synthesize phoneLandscapeMode;

- (id) init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    self.enabled = YES;
    
    return self;
}

+ (WDBarItem *) barItemWithView:(UIView *)view
{
    WDBarItem *item = [[WDBarItem alloc] init];
    item.view = view;
    item.type = WDBarTypeView;
    item.width = CGRectGetWidth(view.frame);
    return item;
}

+ (WDBarItem *) barItemWithView:(UIView *)view landscapeView:(UIView *)landscapeView
{
    WDBarItem *item = [[WDBarItem alloc] init];
    item.view = view;
    item.landscapeView = landscapeView;
    item.type = WDBarTypeView;
    item.width = CGRectGetWidth(view.frame);
    return item;
}

+ (WDBarItem *) flexibleItem
{
    WDBarItem *item = [[WDBarItem alloc] init];
    item.type = WDBarTypeFlexible;
    return item;
}

+ (WDBarItem *) barItemWithImage:(UIImage *)inImage target:(id)target action:(SEL)action
{
    return [self barItemWithImage:inImage landscapeImage:nil target:target action:action];
}

+ (UIImage *) addShadowToImage:(UIImage *)inImage
{
    if (!inImage) {
        return nil;
    }
    
    CGSize  size = WDAddSizes(inImage.size, CGSizeMake(4,4)); // add a small buffer for the shadow
    float   shadowRadius = ([UIScreen mainScreen].scale == 1.0f) ? 1.5f : 2.0f;
    float   shadowOpacity = ([UIScreen mainScreen].scale == 1.0f) ? (kWDBarItemShadowOpacity - 0.1) : kWDBarItemShadowOpacity;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, 2, 2);
    CGContextSetShadowWithColor(ctx, CGSizeZero, shadowRadius, [UIColor colorWithWhite:0.0f alpha:shadowOpacity].CGColor);
    [inImage drawInRect:CGRectMake(0, 0, inImage.size.width, inImage.size.height)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

+ (UIButton *) buttonWithImage:(UIImage *)image height:(float)height
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    
    button.adjustsImageWhenHighlighted = NO;
    button.showsTouchWhenHighlighted = YES;
    float width = MAX(kWDDefaultBarHeight, image.size.width);
    button.frame = CGRectMake(0, 0, width, height);
    //button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    return button;
}

+ (WDBarItem *) barItemWithImage:(UIImage *)inImage landscapeImage:(UIImage *)inLandscapeImage target:(id)target action:(SEL)action
{
    UIButton *button = nil;
    UIButton *landscapeButton = nil;
    
    inImage = [self addShadowToImage:inImage];
    button = [WDBarItem buttonWithImage:inImage height:kWDDefaultBarHeight];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    if (inLandscapeImage) {
        inLandscapeImage = [self addShadowToImage:inLandscapeImage];
        landscapeButton = [WDBarItem buttonWithImage:inLandscapeImage height:kWDLandscapePhoneBarHeight];
        [landscapeButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    
    return [WDBarItem barItemWithView:button landscapeView:landscapeButton];
}

+ (UIImage *) backImageWithTitle:(NSString *)string landscape:(BOOL)landscape
{
    UIImage *result = nil;
    
    if (WDUseModernAppearance()) {
        UIFont  *font = [UIFont systemFontOfSize:17];
        CGSize  textSize = [string sizeWithFont:font];
        CGSize  size = textSize;
        float   arrowSize = 9, arrowInset = 4;

        // add some space for the back arrow
        size.width += 20;
        
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        [[UIColor whiteColor] set];
        CGPoint origin;
        origin.x = (size.width - textSize.width); // align right
        origin.y = (size.height - textSize.height) / 2.0f; // center vertically
        [string drawAtPoint:origin withFont:font];
        
        // draw back arrow
        CGContextMoveToPoint(ctx, arrowInset + arrowSize, size.height / 2 - arrowSize);
        CGContextAddLineToPoint(ctx, arrowInset, size.height / 2);
        CGContextAddLineToPoint(ctx, arrowInset + arrowSize, size.height / 2 + arrowSize);
        CGContextSetLineCap(ctx, kCGLineCapButt);
        CGContextSetLineJoin(ctx, kCGLineJoinMiter);
        CGContextSetLineWidth(ctx, 2.5);
        CGContextStrokePath(ctx);
        
        result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } else {
        UIFont *font = [UIFont boldSystemFontOfSize:(landscape ? 12 : 13)];
        CGSize textSize = [string sizeWithFont:font];
        CGSize size = textSize;
        
        UIImage *backImage = landscape ? [UIImage imageNamed:@"backButtonLandscape.png"] : [UIImage imageNamed:@"backButton.png"];
        
        size.width += 20;
        size.height = backImage.size.height;
        
        float inset = landscape ? 11 : 16;
        UIImage *background = [backImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, inset, 0, inset)];
         
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
        [background drawInRect:rect];
        [[UIColor whiteColor] set];

        CGPoint origin;
        origin.x = (size.width - textSize.width) / 2.0f + 2.0f;
        origin.y = (size.height - textSize.height) / 2.0f;
        [string drawAtPoint:origin withFont:font];
        
        result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return result;
}

+ (WDBarItem *) backButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    return [self barItemWithImage:[self backImageWithTitle:title landscape:NO]
                   landscapeImage:[self backImageWithTitle:title landscape:YES]
                           target:target
                           action:action];
}

+ (WDBarItem *) fixedItemWithWidth:(NSUInteger)width
{
    WDBarItem *item = [[WDBarItem alloc] init];
    item.type = WDBarTypeFixed;
    item.width = width;
    return item;
}

- (float) maxAlpha
{
    return (self.enabled ? 1.0f : 0.5f);
}

- (void) setEnabled:(BOOL)inEnabled
{
    enabled = inEnabled;
    
    if (self.view) {
        self.view.alpha = [self maxAlpha];
        self.view.userInteractionEnabled = inEnabled;
    }
    
    if (self.landscapeView) {
        self.landscapeView.alpha = [self maxAlpha];
        self.landscapeView.userInteractionEnabled = inEnabled;
    }
}

- (void) setImage:(UIImage *)inImage
{
    if (self.view && [self.view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)self.view;
        [button setImage:[WDBarItem addShadowToImage:inImage] forState:UIControlStateNormal];
    }
}

- (void) setWidth:(NSUInteger)inWidth
{
    if (self.activeView) {
        CGRect frame = self.activeView.frame;
        frame.size.width = inWidth;
        self.activeView.frame = frame;
    } else {
        width = inWidth;
    }
}

- (NSUInteger) width
{
    if (self.activeView) {
        return (NSUInteger) CGRectGetWidth(self.view.frame);
    }
    
    return width;
}

- (UIView *) activeView
{
    if (phoneLandscapeMode && landscapeView) {
        return landscapeView;
    }
    
    return view;
}

- (void) removeFromSuperviewAnimated:(BOOL)animated
{
    if (!self.view) {
        return;
    }
    
    UIView *viewToRemove = [view superview] ? view : landscapeView;
    
    if (viewToRemove) {
        if (animated) {
            [UIView animateWithDuration:0.2f animations:^{
                viewToRemove.alpha = 0.0f;
            } completion:^(BOOL finished) {
                [viewToRemove removeFromSuperview];
            }];
        } else {
            [viewToRemove removeFromSuperview];
        }
    }
}

- (void) setPhoneLandscapeMode:(BOOL)inPhoneLandscapeMode
{
    phoneLandscapeMode = inPhoneLandscapeMode;
    
    if ([self.view respondsToSelector:@selector(setPhoneLandscapeMode:)]) {
        [((WDBarItem *) self.view) setPhoneLandscapeMode:inPhoneLandscapeMode];
    }
}

@end

@implementation WDBar

@synthesize items;
@synthesize titleLabel;
@synthesize ignoreTouches;
@synthesize animateAfterLayout;
@synthesize barType;
@synthesize defaultFlexibleSpacing;
@synthesize phoneLandscapeMode;
@synthesize tightHitTest;

+ (WDBar *) bottomBar
{
    WDBar *bar = [[WDBar alloc] initWithFrame:CGRectMake(0, 0, kWDDefaultBarHeight, kWDDefaultBarHeight)];
    bar.barType = WDBarTypeBottom;
    
    return bar;
}

+ (WDBar *) topBar
{
    WDBar *bar = [[WDBar alloc] initWithFrame:CGRectMake(0, 0, kWDDefaultBarHeight, kWDDefaultBarHeight)];
    bar.barType = WDBarTypeTop;
    
    return bar;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.opaque = NO;
    self.backgroundColor = nil;
    self.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
    self.defaultFlexibleSpacing = 10;
    
    self.ignoreTouches = YES;
    
    return self;
}

- (void) setBarType:(WDBarType)inBarType
{
    barType = inBarType;
    
    UIViewAutoresizing mask = UIViewAutoresizingFlexibleWidth;
    mask |= (barType == WDBarTypeBottom) ? UIViewAutoresizingFlexibleTopMargin : UIViewAutoresizingFlexibleBottomMargin;
    self.autoresizingMask = mask;
}

- (void) setItems:(NSArray *)inItems animated:(BOOL)animated
{
    if ([inItems isEqual:items]) {
        return;
    }
    
    // remove old cells
    for (WDBarItem *item in self.items) {
        [item removeFromSuperviewAnimated:animated];
    }
    
    // release old and retain new
    items = inItems;
    
    // add the new cells to the view
    for (WDBarItem *item in self.items) {
        item.phoneLandscapeMode = phoneLandscapeMode;
        
        UIView *view = item.activeView;
        if (view) {
            [self addSubview:view];
            
            if (animated) {
                // this will get animated back to 1.0 after layout
                view.alpha = 0.0f;
            }
        }
    }

    self.animateAfterLayout = animated;
    
    [self setNeedsLayout];
}

- (void) setItems:(NSArray *)inItems
{
    [self setItems:inItems animated:NO];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    float           totalWidth = 0.0f;
    NSUInteger      numberOfFlexibleItems = 0;
    NSMutableArray  *flexibleContentItems = [NSMutableArray array];
    
    for (WDBarItem *item in self.items) {
        totalWidth += item.width;
        if (item.type == WDBarTypeFlexible) {
            numberOfFlexibleItems++;
        } else if (item.flexibleContent) {
            [flexibleContentItems addObject:item];
            totalWidth -= item.width; // this now counts as slack
        }
    }
    
    float slack = CGRectGetWidth(self.bounds) - totalWidth;
    float flex = slack / numberOfFlexibleItems;
    
    if (flexibleContentItems.count != 0) {
        flex = self.defaultFlexibleSpacing;
        slack -= flex * numberOfFlexibleItems;
        
        // slack must now be divided between remaining flexible content items
        float itemFlex = roundf(slack / flexibleContentItems.count);
        
        for (WDBarItem *item in flexibleContentItems) {
            CGRect frame = item.activeView.frame;
            frame.size.width = itemFlex;
            item.activeView.frame = frame;
        }
    }
    
    CGPoint currentOrigin = CGPointZero;
    CGRect  frame;
    float   left = 0, right = 0;
    
    for (WDBarItem *item in self.items) {
        if (item.activeView) {
            frame = item.activeView.frame;
            frame.origin = WDRoundPoint(currentOrigin);
            frame.origin.y = floorf((CGRectGetHeight(self.bounds) - CGRectGetHeight(item.activeView.frame)) / 2.0f);
            item.activeView.frame = frame;
        }
        
        if (item.type != WDBarTypeFlexible) {
            currentOrigin.x += item.width;
        } else { // flexible item
            if (self.titleLabel) {
                // NOTE: this heuristic only works if there's one centered flexible item 
                left = currentOrigin.x;
                right = currentOrigin.x + flex;
            }
            currentOrigin.x += flex;
        }
    }
    
    if (self.titleLabel) {
        CGRect frame = self.bounds;
        float inset = MAX(left, CGRectGetWidth(frame) - right) + 10;
        frame = CGRectInset(frame, inset, 0);
        self.titleLabel.frame = frame;
    }
    
    if (self.animateAfterLayout) {
        for (WDBarItem *item in self.items) {
            if (item.activeView) {
                [UIView animateWithDuration:0.2f animations:^{
                    item.activeView.alpha = [item maxAlpha];
                } completion:nil];
            }
        }
        
        self.animateAfterLayout = NO;
    } else {
        // make sure the items aren't invisible
        for (WDBarItem *item in self.items) {
            if (item.activeView) {
                item.activeView.alpha = [item maxAlpha];
            }
        }
    }
}

- (UIFont *) portraitFont
{
    if (WDUseModernAppearance()) {
        return [UIFont boldSystemFontOfSize:17.0f];
    } else {
        return [UIFont boldSystemFontOfSize:20.0f];
    }
}

- (UIFont *) landscapeFont
{
    if (WDUseModernAppearance()) {
        return [UIFont boldSystemFontOfSize:17.0f];
    } else {
        return [UIFont boldSystemFontOfSize:18.0f];
    }
}

- (void) setTitle:(NSString *)title
{
    if (!title) {
        [self.titleLabel removeFromSuperview];
        self.titleLabel = nil;
        return;
    }
    
    if (!self.titleLabel) {
        UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
        label.backgroundColor = nil;
        label.opaque = NO;
        label.textColor = [UIColor whiteColor];
        label.textAlignment = UITextAlignmentCenter;
        label.lineBreakMode = UILineBreakModeMiddleTruncation;
        label.font = [self portraitFont];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        CALayer *layer = label.layer;
        layer.shadowRadius = 1;
        layer.shadowOpacity = kWDBarItemShadowOpacity;
        layer.shadowOffset = CGSizeZero;
        layer.shouldRasterize = YES;
        layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        self.titleLabel = label;
        [self addSubview:label];
    }
    
    self.titleLabel.text = title;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hit = [super hitTest:point withEvent:event];
    
    if (!self.ignoreTouches) {
        return hit;
    }
    
    if (hit == self && !self.tightHitTest) {
         // make sure we're not too close to one of our subviews
        
        for (WDBarItem *item in self.items) {
            if (!item.activeView) {
                continue;
            }
            
            CGRect frame = item.activeView.frame;
            frame = CGRectInset(frame, -20, -20);
            
            if (CGRectContainsPoint(frame, point)) {
                hit = item.activeView;
            }
        }
    }
    
    // we ignore taps that aren't inside a subview
    return ((hit != self) && (hit != self.titleLabel)) ? hit : nil;
}

- (void) addEdge:(UIColor *)color offset:(float)offset
{
    CGRect frame = self.bounds;
    frame.origin.y = (barType == WDBarTypeTop) ? (CGRectGetMaxY(frame) - offset) : (offset - 1);
    frame.size.height = 1;
    
    UIView *edge = [[UIView alloc] initWithFrame:frame];
    edge.backgroundColor = color;
    edge.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    if (self.barType == WDBarTypeTop) {
        edge.autoresizingMask |= UIViewAutoresizingFlexibleTopMargin;
    }
    
    [self addSubview:edge];
}

- (void) addEdge
{
    self.backgroundColor = [UIColor colorWithWhite:0.667f alpha:0.667f];
    //self.backgroundColor = [UIColor colorWithRed:(34.0 / 255) green:(62.0 / 255) blue:(83.0 / 255) alpha:0.5];
    
    // main edge
    [self addEdge:[UIColor darkGrayColor] offset:1];
}

- (void) setOrientation:(UIInterfaceOrientation)orientation
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return;
    }
    
    phoneLandscapeMode = UIInterfaceOrientationIsLandscape(orientation);
    float height = phoneLandscapeMode ? kWDLandscapePhoneBarHeight : kWDDefaultBarHeight;

    CGRect frame = self.frame;
    
    if (self.barType == WDBarTypeBottom) {
        float shift = CGRectGetHeight(frame) - height;
        frame.origin.y += shift;
    }
    
    frame.size.height = height;
    self.frame = frame;
    
    self.titleLabel.font = phoneLandscapeMode ? [self landscapeFont] : [self portraitFont];
    
    for (WDBarItem *item in items) {
        item.phoneLandscapeMode = phoneLandscapeMode;
    }
    
    NSArray *tempItems = self.items;
    [self setItems:nil];
    [self setItems:tempItems]; // reload the views and layout
}

@end
