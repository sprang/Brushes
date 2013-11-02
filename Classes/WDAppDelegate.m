//
//  WDAppDelegate.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "WDAppDelegate.h"
#import "WDBrowserController.h"
#import "WDColor.h"
#import "WDCanvasController.h"
#import "WDPaintingManager.h"
#import "WDPaintingSizeController.h"
#import "WDDocument.h"
#import "WDStylusManager.h"

NSString *WDDropboxWasUnlinkedNotification = @"WDDropboxWasUnlinkedNotification";

@implementation WDAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize browserController;
@synthesize performAfterDropboxLoginBlock;

#pragma mark -
#pragma mark Application lifecycle

- (void) setupDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *defaultPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Defaults.plist"];
    [defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:defaultPath]];
    
    [WDPaintingSizeController registerDefaults];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    #if !WD_DEBUG
    #warning "Set appropriate Dropbox keys before submitting to the app store."
    #endif
    
    NSLog(@"No Dropbox Keys!");
    NSString *appKey = @"xxxx";
    NSString *appSecret = @"xxxx";
    
    DBSession *session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:kDBRootDropbox];
    session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
    [DBSession setSharedSession:session];
    
    [self setupDefaults];
    
    browserController = [[WDBrowserController alloc] initWithNibName:nil bundle:nil];
    navigationController = [[UINavigationController alloc] initWithRootViewController:browserController];
    
    // set a good background color for the superview so that orientation changes don't look hideous
    window.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    
    window.rootViewController = navigationController;
    [window makeKeyAndVisible];

    // use this line to forget registered Pogo Connects
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"T1PogoManagerKnownPeripherals"];
    
    // create the shared stylus manager so it can set things up for the pressure pens
    [WDStylusManager sharedStylusManager];
}

void uncaughtExceptionHandler(NSException *exception) {
#if WD_DEBUG
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
#endif
}

- (void) startEditingDocument:(id)name
{
    WDDocument *document = [[WDPaintingManager sharedInstance] paintingWithName:name];
    [browserController openDocument:document editing:NO];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            if (self.performAfterDropboxLoginBlock) {
                self.performAfterDropboxLoginBlock();
                self.performAfterDropboxLoginBlock = nil;
            }
        }
        return YES;
    }
    
    NSError *error = nil;
    NSString *name = [[WDPaintingManager sharedInstance] installPaintingFromURL:url error:&error];

    if (!name) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Broken Painting", @"Broken Painting")
                                                            message:NSLocalizedString(@"Brushes could not open the requested painting.", @"Brushes could not open the requested painting.")
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    } else if (navigationController.topViewController == browserController) {
        [browserController dismissViewControllerAnimated:NO completion:nil];
        [self performSelector:@selector(startEditingDocument:) withObject:name afterDelay:0];
    } else {
        WDCanvasController *controller = (WDCanvasController *) navigationController.topViewController;
        WDDocument *doc = [[WDPaintingManager sharedInstance] paintingWithName:name];
        [doc openWithCompletionHandler:^(BOOL success) {
            if (success) {
                controller.document = doc;
            } else {
                [browserController showOpenFailure:doc];
            }
        }];
    }
    
    return (name ? YES : NO);
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
{
    
}

#pragma mark -
#pragma mark Dropbox unlinking

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    if ([[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] unlinkAll];
    } 
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WDDropboxWasUnlinkedNotification object:self];
}

- (void) unlinkDropbox
{
    if (![[DBSession sharedSession] isLinked]) {
        return;
    } 
    
    NSString *title = NSLocalizedString(@"Unlink Dropbox", @"Unlink Dropbox");
    NSString *message = NSLocalizedString(@"Are you sure you want to unlink your Dropbox account?", @"Are you sure you want to unlink your Dropbox account?");
    
    NSString *unlinkButtonTitle = NSLocalizedString(@"Unlink", @"Title of Unlink button");
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Title of Cancel button");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:unlinkButtonTitle, cancelButtonTitle, nil];
    alertView.cancelButtonIndex = 1;
    
    [alertView show];
}

@end
