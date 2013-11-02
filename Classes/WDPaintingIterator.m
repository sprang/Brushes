//
//  WDPaintingIterator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Original implementation by Scott Vachalek
//
//  Copyright (c) 2012-2013 Steve Sprang
//


#import "WDPaintingIterator.h"
#import "WDDocument.h"
#import "WDPaintingManager.h"
#import "WDUtilities.h"


@implementation WDPaintingIterator {

}

@synthesize paintings;
@synthesize index;
@synthesize block;

- (void) processNext
{
    // process sequentially such that we don't get a ton of documents open simultaneously on bg queues
    if (index < paintings.count) {
        NSString *name = paintings[index++];
        WDDocument *document = [[WDPaintingManager sharedInstance] paintingWithName:name];
        [document openWithCompletionHandler:^void(BOOL success) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^void() {
                    self.block(document);
                    [document closeWithCompletionHandler:^void(BOOL success) {
                        dispatch_async(dispatch_get_main_queue(), ^void() {
                            [self processNext];
                        });
                    }];
                });
            } else {
                WDLog(@"Failed to open document! %@", document.displayName);    
            }
        }];
    } else {
        if (self.completed) {
            self.completed(self.paintings);
        }
    }
}

@end
