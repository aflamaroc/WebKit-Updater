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
	NSFileManager *fileMan = [NSFileManager defaultManager];
	NSURLSessionDataTask *releasesDownload = [session dataTaskWithURL:[NSURL URLWithString:@"https://api.github.com/repos/Wowfunhappy/WebKit/releases"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[self setViewsUsable:NO];
		
		// Fetch releases JSON from Github
		[self setLogString:@"Fetching releases JSON."];
		if (error){
			[self setLogString:@"Fetching releases failed"];
			NSLog(@"%@", error.localizedDescription);
			[_progress stopAnimation:nil];
			return;
		}
		
		// Serialize JSON (could fail because of a malformed return
		NSError *jsonSerializationError = nil;
		NSArray *releasesArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
		if (jsonSerializationError){
			[self setLogString:@"Serialization failed"];
			[_progress stopAnimation:nil];
			NSLog(@"%@", jsonSerializationError.localizedDescription);
			return;
		}
		
		// Actually Download WebKit
		webkitDownloadURL = [[[[releasesArray objectAtIndex:0] valueForKey:@"assets"] objectAtIndex:0] valueForKey:@"browser_download_url"];
		NSLog(@"Downloading asset from github with URL: %@", webkitDownloadURL);
		[self setLogString:@"Found .zip, downloading"];
		NSData *webkitRelease = [NSData dataWithContentsOfURL:[NSURL URLWithString:webkitDownloadURL]];
		if (!webkitRelease){
			[self setLogString:@"Downloading Release Failed"];
			[_progress stopAnimation:nil];
			return;
		}
		[webkitRelease writeToFile:@"/tmp/Webkit.zip" atomically:YES];
		
		// Unzip Webkit
		[self setLogString:@"Unzipping Release"];
		[SSZipArchive unzipFileAtPath:@"/tmp/Webkit.zip" toDestination:@"/tmp/WebkitRelease/"];
		if (![fileMan fileExistsAtPath:@"/tmp/WebkitRelease/"]){
			[self setLogString:@"Failed to Unzip WebKit"];
			[_progress stopAnimation:nil];
			return;
		}
		
		// Copying release to /System/Library/*Frameworks
		[self setLogString:@"Copying Release to /System"];
		NSError *directoryError = nil;
		NSArray *directoryContents = [fileMan contentsOfDirectoryAtPath:@"/tmp/WebkitRelease/" error:&directoryError];
		NSString *WKReleaseDir = [[directoryContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF BEGINSWITH '.')"]] firstObject];
		NSLog(@"Using directory %@", WKReleaseDir);
		if (directoryError) {
			NSLog(@"%@", error.localizedDescription);
			[self setLogString:@"Failed to copy Frameworks"];
			[_progress stopAnimation:nil];
			return;
		}
		[self copyFrameworkFrom:[WKReleaseDir stringByAppendingString:""] to:<#(NSString *)#> nuclear:NO];
		*/
		
		
	}];
	[releasesDownload resume];

}


- (void)copyFrameworkFrom:(NSString *)srcFileURL to:(NSString *)destFileURL nuclear:(BOOL)nuclear
{
	char *args[] = {
		(char *)[srcFileURL UTF8String],
		(char *)[destFileURL UTF8String],
		(char *)(nuclear ? "1" : "0"),
		NULL
	};
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	AuthorizationExecuteWithPrivileges([[_authView authorization] authorizationRef],
									   [[[NSBundle bundleForClass:self] pathForResource:@"FrameworkCopier" ofType:nil] UTF8String],
									   kAuthorizationFlagDefaults,
									   args,
									   nil);
}
- (void) update_dyldSharedCache{
	NSLog(@"Updating Shared Cache");
	char *args[] = {
		"--force",
		NULL
	};
	AuthorizationExecuteWithPrivileges([[_authView authorization] authorizationRef], "/usr/bin/update_dyld_shared_cache", kAuthorizationFlagDefaults, args, NULL);
}
- (void) mainViewDidLoad{
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
- (void) stopLogging{
	[_log setStringValue:@"Done!"];
	[_progress stopAnimation:nil];
	
}
- (void) hideLog{
	[_log setHidden:YES];
	[_log setStringValue:@"You shouldn't see this."];
	[_progress stopAnimation:nil];
	[_progress setHidden:YES];
}

@end
