//
//  WebKit_Updater.m
//  WebKit Updater
//
//  do whatever.
//

#import "WebKit_Updater.h"

@implementation WebKit_Updater
- (IBAction)bugReport:(id)sender {
	
}
- (IBAction)showHelpPopover:(id)sender {
		[_helpPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
}
- (IBAction)downloadWebkit:(id)sender {
	[_authView setEnabled:NO];
	NSLog(@"we are downloading!");
	__block NSString *webkitDownloadURL;
	NSURLSession *session = [NSURLSession sharedSession];
	NSURLSessionDataTask *releasesDownload = [session dataTaskWithURL:[NSURL URLWithString:@"https://api.github.com/repos/Wowfunhappy/WebKit/releases"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[self setViewsUsable:NO];
		[self setLogString:@"Fetching releases JSON."];
		if (error){
			[self setLogString:@"Fetching releases failed"];
			NSLog(error.localizedDescription);
			[_progress stopAnimation:nil];
			return;
		}

		NSError *jsonSerializationError = nil;
		NSArray *releasesArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
		if (jsonSerializationError){
			[self setLogString:@"Serialization failed"];
			[_progress stopAnimation:nil];
			NSLog(jsonSerializationError.localizedDescription);
		}
		
		webkitDownloadURL = [[[[releasesArray objectAtIndex:0] valueForKey:@"assets"] objectAtIndex:0] valueForKey:@"browser_download_url"];
		NSLog(@"Downloading asset from github with URL: %@", webkitDownloadURL);
		[self setLogString:@"Found .zip, downloading"];
		NSData *webkitRelease = [NSData dataWithContentsOfURL:[NSURL URLWithString:webkitDownloadURL]];
		if (!webkitRelease){
			[self setLogString:@"Downloading Release Failed"];
			[_progress stopAnimation:nil];
		}
		
		[webkitRelease writeToFile:@"/tmp/Webkit.zip" atomically:YES];
		
		[self setLogString:@"Unzipping Release"];
		[SSZipArchive unzipFileAtPath:@"/tmp/Webkit.zip" toDestination:@"/tmp/WebkitRelease/"];
		[self setLogString:@"Copying Release to /System"];

		AuthorizationExecuteWithPrivileges([[_authView authorization] authorizationRef], [@"wkinstallerscript.sh" UTF8String], kAuthorizationFlagDefaults, nil, nil);
		
		
	}];
	[releasesDownload resume];

}

- (void)mainViewDidLoad{
	[_authView setString:"system.preferences"];
	[_authView setAutoupdate:YES];
	[_authView setDelegate:self];
	[_authView updateStatus:self];
	_helpPopover.behavior = NSPopoverBehaviorTransient;
	_helpPopover.contentViewController = [[NSViewController alloc] initWithNibName:@"popover" bundle:[NSBundle bundleForClass:[self class]]];
}

- (void) authorizationViewDidAuthorize:(SFAuthorizationView *)view{
	NSLog(@"i can doo what you want me to dooo");
	[self setViewsUsable:YES];
	
}

- (void) authorizationViewDidDeauthorize:(SFAuthorizationView *)view{
	NSLog(@"i cannot do what you want me to doooo");
	[self setViewsUsable:NO];
}

- (void) setViewsUsable:(bool)state{
	[_s7onDiskButton setEnabled:state];
	[_s7OTAbutton setEnabled:state];
	[_dlWebKitButton setEnabled:state];
}

- (void) setLogString:(NSString *)string{
	[_log setStringValue:string];
	[_log setHidden:NO];
	[_progress setHidden:NO];
	[_progress startAnimation:nil];
}

- (void) hideLog{
	[_log setHidden:YES];
	[_log setStringValue:@"You shouldn't see this."];
	[_progress stopAnimation:nil];
	[_progress setHidden:YES];
}

@end
