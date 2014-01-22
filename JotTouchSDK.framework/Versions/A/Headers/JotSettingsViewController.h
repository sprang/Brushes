//
//  SettingsViewController.h
//  JotTouchSDK
//
//  Created  on 3/3/13.
//  Copyright (c) 2013 Adonit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JotSettingsViewController : UINavigationController

/*! Initialization of settings view controller with or without adonit jot family toggle.
 * \param showSwitch A boolean that determines whether to show jot family toggle.
 */
-(id)initWithOnOffSwitch:(BOOL)showSwitch;

/*! Initialization of settings view controller with or without adonit jot family toggle and palm rejection toggle.
 * \param showSwitch A boolean that determines whether to show jot family toggle
 * \param showPalmRejection A boolean that determines whether to show palm rejection toggle
 */
-(id)initWithOnOffSwitch:(BOOL)showSwitch andShowPalmRejection:(BOOL)showPalmRejection;
@end
