//
//  WDActionNameView.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDActionNameView.h"

#define kWDActionNameFadeDelay          0.666f
#define kWDActionNameFadeOutDuration    0.2f
#define kWDActionNameCornerRadius       9

@implementation WDActionNameView

@synthesize titleLabel;
@synthesize messageLabel;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.opaque = NO;
    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5f];
    self.autoresizesSubviews = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CALayer *layer = self.layer;
    layer.cornerRadius = kWDActionNameCornerRadius;
    
    frame = CGRectInset(self.bounds, 10, 5);
    frame.size.height /= 2;
    self.titleLabel = [[UILabel alloc] initWithFrame:frame];
    titleLabel.font = [UIFont boldSystemFontOfSize:20.0f];
    titleLabel.textAlignment = UITextAlignmentCenter;
    titleLabel.backgroundColor = nil;
    titleLabel.opaque = NO;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.shadowColor = [UIColor blackColor];
    titleLabel.shadowOffset = CGSizeMake(0,1);
    [self addSubview:titleLabel];
    
    frame = CGRectOffset(frame, 0, CGRectGetHeight(frame));
    self.messageLabel = [[UILabel alloc] initWithFrame:frame];
    messageLabel.font = [UIFont systemFontOfSize:17.0f];
    messageLabel.textAlignment = UITextAlignmentCenter;
    messageLabel.backgroundColor = nil;
    messageLabel.opaque = NO;
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:messageLabel];
    
    return self;
}

- (void) fadeOut:(id)obj
{
    if (delegate) {
        [delegate fadingOutActionNameView:self];
    }
    
    [UIView animateWithDuration:kWDActionNameFadeOutDuration animations:^{
        self.alpha = 0.0f;
        self.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void) setUndoActionName:(NSString *)undoActionName
{
    titleLabel.text = NSLocalizedString(@"Undo", @"Undo");
    messageLabel.text = undoActionName;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(fadeOut:) withObject:nil afterDelay:kWDActionNameFadeDelay];
}

- (void) setRedoActionName:(NSString *)redoActionName
{
    titleLabel.text = NSLocalizedString(@"Redo", @"Redo");
    messageLabel.text = redoActionName;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(fadeOut:) withObject:nil afterDelay:kWDActionNameFadeDelay];
}

- (void) setConnectedDeviceName:(NSString *)deviceName
{
    titleLabel.text = NSLocalizedString(@"Connected", @"Connected");
    messageLabel.text = deviceName;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(fadeOut:) withObject:nil afterDelay:kWDActionNameFadeDelay];
}

- (void) setDisconnectedDeviceName:(NSString *)deviceName;
{
    titleLabel.text = NSLocalizedString(@"Disconnected", @"Disconnected");
    messageLabel.text = deviceName;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(fadeOut:) withObject:nil afterDelay:kWDActionNameFadeDelay];
}

@end

