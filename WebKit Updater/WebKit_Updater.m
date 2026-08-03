//
//  WebKit_Updater.m
//  WebKit Updater
//
//  do whatever.
//

#import "WebKit_Updater.h"

@implementation WebKit_Updater
- (IBAction)bugReport:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/Wowfunhappy/WebKit/issues/new"]];
}
- (IBAction)showHelpPopover:(id)sender {
		[_helpPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
}
- (IBAction)downloadWebkit:(id)sender {
	NSLog(@"we are downloading!");
	NSURLSession *session = [NSURLSession sharedSession];
	NSFileManager *fileMan = [NSFileManager defaultManager];
	NSURLSessionDataTask *releasesDownload = [session dataTaskWithURL:[NSURL URLWithString:@"https://api.github.com/repos/Wowfunhappy/WebKit/releases"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		[self setViewsUsable:NO authview:YES];
		
		// Fetch releases JSON from Github
		[self setLogString:@"Fetching releases JSON."];
		if (error){
			[self stopLogging:@"Fetching Releases JSON Failed" error:error];
			return;
		}
		// Serialize JSON (could fail because of a malformed return
		NSError *jsonSerializationError = nil;
		NSArray *releasesArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
		if (jsonSerializationError){
			[self stopLogging:@"JSON Serialization Failed" error:jsonSerializationError];
			return;
		}
		// Actually Download WebKit
		NSString *webkitDownloadURL;
		webkitDownloadURL = [[[[releasesArray objectAtIndex:0] valueForKey:@"assets"] objectAtIndex:0] valueForKey:@"browser_download_url"];
		NSLog(@"Downloading asset from github with URL: %@", webkitDownloadURL);
		[self setLogString:@"Found .zip, downloading"];
		NSData *webkitRelease = [NSData dataWithContentsOfURL:[NSURL URLWithString:webkitDownloadURL]];
		if (!webkitRelease){
			[self stopLogging:@"Release Failed to Download"];
			return;
		}
		[webkitRelease writeToFile:@"/tmp/Webkit.zip" atomically:YES];
		
		// Unzip Webkit
		[self setLogString:@"Unzipping Release"];
		[SSZipArchive unzipFileAtPath:@"/tmp/Webkit.zip" toDestination:@"/tmp/WebkitRelease/"];
		if (![fileMan fileExistsAtPath:@"/tmp/WebkitRelease/"]){
			[self stopLogging:@"Unzipping Release Failed!"];
			return;
		}
		
		// Copying release to /System/Library/*Frameworks
		[self setLogString:@"Copying Release to /System"];
		NSError *directoryError = nil;
		NSArray *directoryContents = [fileMan contentsOfDirectoryAtPath:@"/tmp/WebkitRelease/" error:&directoryError];
		NSString *WKReleaseDir = [@"/tmp/WebkitRelease/" stringByAppendingString:[[directoryContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF BEGINSWITH '.')"]] firstObject]];
		NSLog(@"Using directory %@", WKReleaseDir);
		if (directoryError) {
			[self stopLogging:@"Webkit is not present!" error:directoryContents];
			return;
		}
		
		[self copyFrameworkFrom:[WKReleaseDir stringByAppendingString:@"/WebKit.framework"] to:@"/System/Library/Frameworks/WebKit.framework" nuclear:YES];
		[self copyFrameworkFrom:[WKReleaseDir stringByAppendingString:@"/JavaScriptCore.framework"] to:@"/System/Library/Frameworks/JavaScriptCore.framework" nuclear:YES];
		[self copyFrameworkFrom:[WKReleaseDir stringByAppendingString:@"/WebKit2.framework"] to:@"/System/Library/PrivateFrameworks/WebKit2.framework" nuclear:YES];
		
		// Cleanup code
		NSError *deletionError = nil;
		[self setLogString:@"Clearing DYLD Cache & Cleaning Up"];
		[fileMan removeItemAtPath:@"/tmp/WebkitRelease" error:&deletionError];
		[fileMan removeItemAtPath:@"/tmp/Webkit.zip" error:&deletionError];
		if (deletionError) {
			NSLog(@"%@", deletionError.localizedDescription);
			[self setLogString:@"Cleanup Failed"];
			[_progress stopAnimation:nil];
		}
		if (!([fileMan fileExistsAtPath:@"/System/Library/Frameworks/WebKit.framework"] && [fileMan fileExistsAtPath:@"/System/Library/Frameworks/JavaScriptCore.framework"] && [fileMan fileExistsAtPath:@"/System/Library/PrivateFrameworks/WebKit2.framework"])){
			[self stopLogging:@"You'd better have made a backup."];
			return;
		}
			
		[self stopLogging:@"We're done!"];
		[self setViewsUsable:YES authview:YES];
	}];
	[releasesDownload resume];

}


- (void)copyFrameworkFrom:(NSString *)srcFileURL to:(NSString *)destFileURL nuclear:(BOOL)nuclear{
	NSLog(@"Calling: %@ %@ %@ %@", [[NSBundle bundleForClass:[self class]] pathForResource:@"FrameworkCopier" ofType:nil], srcFileURL, destFileURL, (nuclear ? @"1" : @"0"));
	char *args[] = {
		(char *)[srcFileURL UTF8String],
		(char *)[destFileURL UTF8String],
		(char *)(nuclear ? "1" : "0"),
		NULL
	};
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	AuthorizationExecuteWithPrivileges([[_authView authorization] authorizationRef],
									   [[[NSBundle bundleForClass:[self class]] pathForResource:@"FrameworkCopier" ofType:nil] UTF8String],
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
	[_authView setEnabled:YES];
	_helpPopover.behavior = NSPopoverBehaviorTransient;
	_helpPopover.contentViewController = [[NSViewController alloc] initWithNibName:@"popover" bundle:[NSBundle bundleForClass:[self class]]];
}
- (void) authorizationViewDidAuthorize:(SFAuthorizationView *)view{
	NSLog(@"i can doo what you want me to dooo");
	[self setViewsUsable:YES authview:YES];
	
}
- (void) authorizationViewDidDeauthorize:(SFAuthorizationView *)view{
	NSLog(@"i cannot do what you want me to doooo");
	[self setViewsUsable:NO authview:NO];
}
- (void) setViewsUsable:(bool)state authview:(bool)authview{
	[_s7onDiskButton setEnabled:state];
	[_s7OTAbutton setEnabled:state];
	[_dlWebKitButton setEnabled:state];
	if (authview)
		[_authView setEnabled:state];
}
- (void) setLogString:(NSString *)string{
	[_log setStringValue:string];
	[_log setHidden:NO];
	[_progress setHidden:NO];
	[_progress startAnimation:nil];
}
- (void) stopLogging:(NSString *)string error:(NSError *)error{
	[_log setStringValue:string];
	[_progress stopAnimation:nil];
	[self setViewsUsable:YES authview:YES];
	NSLog(@"%@", error.localizedDescription);
}
- (void) stopLogging:(NSString *)string{
	[_log setStringValue:string];
	[_progress stopAnimation:nil];
	[self setViewsUsable:YES authview:YES];
}
- (void) hideLog{
	[_log setHidden:YES];
	[_log setStringValue:@"You shouldn't see this."];
	[_progress stopAnimation:nil];
	[_progress setHidden:YES];
}

@end
