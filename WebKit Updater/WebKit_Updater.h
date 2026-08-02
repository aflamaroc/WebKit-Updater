//
//  WebKit_Updater.h
//  WebKit Updater
//
//  Created by Rayan Mohammed Majdi on 8/1/26.
//  Copyright (c) 2026 Rayan Mohammed Majdi. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>

@interface WebKit_Updater : NSPreferencePane
@property (weak) IBOutlet SFAuthorizationView *authView;
- (void)mainViewDidLoad;

@end
