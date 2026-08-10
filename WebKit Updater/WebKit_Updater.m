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
		NSTask *unzipTask = [[NSTask alloc] init];
		[unzipTask setLaunchPath:@"/usr/bin/unzip"];
		[unzipTask setArguments:@[@"-o", @"/tmp/Webkit.zip", @"-d", @"/tmp/WebkitRelease"]];
		[unzipTask launch];
		[unzipTask waitUntilExit];
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
			[self stopLogging:@"Webkit is not present!" error:directoryError];
			return;
		}
		
		[self sudoCopy:[WKReleaseDir stringByAppendingString:@"/WebKit.framework"] to:@"/System/Library/Frameworks/WebKit.framework" nuclear:YES];
		[self sudoCopy:[WKReleaseDir stringByAppendingString:@"/JavaScriptCore.framework"] to:@"/System/Library/Frameworks/JavaScriptCore.framework" nuclear:YES];
		[self sudoCopy:[WKReleaseDir stringByAppendingString:@"/WebKit2.framework"] to:@"/System/Library/PrivateFrameworks/WebKit2.framework" nuclear:YES];
		
		
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
			[self stopLogging:@"Try running again."];
			return;
		}
		[self update_dyldSharedCache];
		[self stopLogging:@"We're done!"];
		[self setViewsUsable:YES authview:YES];
		 
		
		
	}];
	[releasesDownload resume];

}
- (IBAction)restoreSafariOnDisk:(id)sender {
	[self setViewsUsable:NO authview:YES];
	
	// Locating recovery
	[self setLogString:@"Locating Recovery"];
	NSTask *diskutilTask = [[NSTask alloc] init];
	diskutilTask.launchPath = @"/usr/sbin/diskutil";
	diskutilTask.arguments = @[@"list"];
	
	NSTask *grepTask = [[NSTask alloc] init];
	grepTask.launchPath = @"/usr/bin/grep";
	grepTask.arguments = @[@"Recovery"];
	
	NSTask *awkTask = [[NSTask alloc] init];
	awkTask.launchPath = @"/usr/bin/awk";
	awkTask.arguments = @[@"{print $7}"];
	
	NSPipe *pipe1 = [NSPipe pipe];
	NSPipe *pipe2 = [NSPipe pipe];
	NSPipe *outputPipe = [NSPipe pipe];
	
	diskutilTask.standardOutput = pipe1;
	grepTask.standardInput = pipe1;
	grepTask.standardOutput = pipe2;
	awkTask.standardInput = pipe2;
	awkTask.standardOutput = outputPipe;
	
	[diskutilTask launch];
	[grepTask launch];
	[awkTask launch];
	
	[diskutilTask waitUntilExit];
	[grepTask waitUntilExit];
	[awkTask waitUntilExit];
	
	NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
	NSString *result = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[self setLogString:@"Mounting Recovery"];
	NSError *mountError;
	[[NSFileManager defaultManager] createDirectoryAtPath:@"/tmp/Recovery" withIntermediateDirectories:YES attributes:nil error:&mountError];
	NSLog(@"%@", result);
	// Mount Recovery
	char *args[] = {
		"-t",
		"hfs",
		"-o",
		"nobrowse",
		strdup([[@"/dev/" stringByAppendingString:result] UTF8String]),
		"/tmp/Recovery",
		NULL
	};
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	AuthorizationExecuteWithPrivileges([[_authView authorization] authorizationRef], "/sbin/mount", kAuthorizationFlagDefaults, args, NULL);
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/Recovery/System"]){
		[self stopLogging:@"Mounting Recovery Failed!"];
		return;
	}
	
	// mounting basesystem
	
	[self setLogString:@"Mounting Base System"];
	NSTask *recoveryTask = [[NSTask alloc] init];
	[recoveryTask setLaunchPath:@"/usr/bin/hdiutil"];
	[recoveryTask setArguments:@[@"attach", @"-nobrowse", @"/private/tmp/Recovery/com.apple.recovery.boot/BaseSystem.dmg"]];
	[recoveryTask launch];
	[recoveryTask waitUntilExit];
	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Volumes/OS X Base System"]) {
		[self stopLogging:@"Mounting Base System Failed!"];
		return;
	}
	
	// copying safari 7
	[self setLogString:@"Copying Safari 7"];
	[self sudoCopy:@"/Volumes/OS X Base System/Applications/Safari.app" to:@"/Applications/Safari.app" nuclear:true];
	[self sudoCopy:@"/Volumes/OS X Base System/System/Library/PrivateFrameworks/Safari.framework" to:@"/System/Library/PrivateFrameworks/Safari.framework" nuclear:true];
	NSString *version = [[[NSDictionary alloc] initWithContentsOfFile:@"/Applications/Safari.app/Contents/Info.plist"] valueForKey:@"CFBundleShortVersionString"];
	float versionNumber = [version floatValue];
	NSLog(@"%f", versionNumber);
	if (versionNumber > 7) {
		[self stopLogging:@"Safari couldn't be copied!"];
	}
	
	// nuke stagedframeworks
	[self setLogString:@"Nuking Safari's StagedFrameworks"];
	char *nukeArgs[] = {
		"-r",
		"/System/Library/StagedFrameworks/Safari",
		NULL
	};
	AuthorizationExecuteWithPrivileges([[_authView authorization] authorizationRef], "/bin/rm", kAuthorizationFlagDefaults, nukeArgs, NULL);

	// forget 9
	[self setLogString:@"Forgetting Safari 9"];
	char *forgetArgs[] = {
		"--forget",
		"com.apple.pkg.Safari9.1.3Mavericks",
		NULL
	};
	AuthorizationExecuteWithPrivileges([[_authView authorization] authorizationRef], "/usr/sbin/pkgutil", kAuthorizationFlagDefaults, forgetArgs, NULL);
	
	// cleanup
	[self setLogString:@"Cleaning Up"];
	
	NSTask *unmountTask = [[NSTask alloc] init];
	[unmountTask setLaunchPath:@"/usr/bin/hdiutil"];
	[unmountTask setArguments:@[@"detach", @"/private/tmp/Recovery/com.apple.recovery.boot/BaseSystem.dmg"]];
	[unmountTask launch];
	[unmountTask waitUntilExit];
	
	char *umountArgs[] = {
		"-f",
		"/tmp/Recovery",
		NULL
	};
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	AuthorizationExecuteWithPrivileges([[_authView authorization] authorizationRef], "/sbin/umount", kAuthorizationFlagDefaults, umountArgs, NULL);
	[[NSFileManager defaultManager] removeItemAtPath:@"Recovery" error:nil]; // nonfatal
	[self stopLogging:@"Done!"];
	
}
/*- (IBAction)restoreSafariOTA:(id)sender {
	
}*/
- (void) sudoCopy:(NSString *)srcFileURL to:(NSString *)destFileURL nuclear:(BOOL)nuclear{
	[[NSFileManager defaultManager]createFileAtPath:@"/tmp/fwcopier.lock" contents:nil attributes:nil];

	NSLog(@"Calling: %@ %@ %@ %@", [[NSBundle bundleForClass:[self class]] pathForResource:@"FrameworkCopier" ofType:nil], srcFileURL, destFileURL, (nuclear ? @"1" : @"0"));
	char *args[] = {
		(char *)[srcFileURL UTF8String],
		(char *)[destFileURL UTF8String],
		(char *)(nuclear ? "1" : "0"),
		NULL
	};
	
	// screw SMJobBless
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	AuthorizationExecuteWithPrivileges([[_authView authorization] authorizationRef],
									   [[[NSBundle bundleForClass:[self class]] pathForResource:@"FrameworkCopier" ofType:nil] UTF8String],
									   kAuthorizationFlagDefaults,
									   args,
									   nil);
	while([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/fwcopier.lock"]){
		[NSThread sleepForTimeInterval:.1];
	}
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
