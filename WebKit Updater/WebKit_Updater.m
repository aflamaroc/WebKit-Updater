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
- (IBAction)showHelpPopover:(id)sender {
		[_helpPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
}

- (void)mainViewDidLoad
{
	_helpPopover.behavior = NSPopoverBehaviorTransient;
	[_authView setString:"system.preferences"];
	[_authView setAutoupdate:YES];
	[_authView setDelegate:self];
	[_authView updateStatus:self];
	_helpPopover.contentViewController = [[NSViewController alloc] initWithNibName:@"popover" bundle:[NSBundle bundleForClass:[self class]]];
	;
}

- (void) authorizationViewDidAuthorize:(SFAuthorizationView *)view{
	NSLog(@"i can doo what you want me to dooo");
	[[_authView authorization] authorizationRef];
	[_s7onDiskButton setEnabled:YES];
	
}

-(void) authorizationViewDidDeauthorize:(SFAuthorizationView *)view{
	NSLog(@"i cannot do what you want me to doooo");
	[_s7onDiskButton setEnabled:NO];
}

@end
