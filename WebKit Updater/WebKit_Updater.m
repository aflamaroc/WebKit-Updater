//
//  WebKit_Updater.m
//  WebKit Updater
//
//  Created by Rayan Mohammed Majdi on 8/1/26.
//  Copyright (c) 2026 Rayan Mohammed Majdi. All rights reserved.
//

#import "WebKit_Updater.h"

@implementation WebKit_Updater
- (IBAction)bugReport:(id)sender {
	
}

- (void)mainViewDidLoad
{
	[_authView setString:"system.preferences"];
	[_authView setAutoupdate:YES];
	[_authView updateStatus:self];
}

@end
