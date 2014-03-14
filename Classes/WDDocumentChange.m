//
//  WDDocumentChange
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Original implementation by Scott Vachalek
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDDocumentChange.h"
#import "WDPainting.h"

// 1.0.0: first marked version
// 1.0.1: fix missing operations caused by autosave
// 1.0.2: paths are stored without offsets
// 1.0.3: brush properties are simplified
// 1.0.4: tweaked a couple of stamp generators which will alter replay fidelity
// 1.0.5: store paths as binary
// 1.0.6: add feature list to WDStartEditing
// 1.0.7: add image
NSString *WDHistoryVersion = @"1.0.7";

NSString *WDDocumentChangedNotification = @"WDDocumentChangedNotification";
NSString *WDDocumentChangedNotificationChange = @"change";

void changeDocument(WDPainting *painting, id<WDDocumentChange> change) {
    change.changeIndex = ++painting.changeCount;
    NSDictionary *info = @{WDDocumentChangedNotificationChange: change};
    [[NSNotificationCenter defaultCenter] postNotificationName:WDDocumentChangedNotification object:painting userInfo:info];
}
