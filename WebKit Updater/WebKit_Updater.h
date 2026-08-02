//
//  WebKit_Updater.h
//  WebKit Updater
//
//  do whatever
//

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>

@interface WebKit_Updater : NSPreferencePane

@property (weak) IBOutlet SFAuthorizationView *authView;

@property (weak) IBOutlet NSButton *s7OTAbutton;
@property (weak) IBOutlet NSButton *s7onDiskButton;
@property (weak) IBOutlet NSButton *dlWebKitButton;
@property (strong) IBOutlet NSPopover *helpPopover;
@property (weak) IBOutlet NSTextField *log;
@property (weak) IBOutlet NSProgressIndicator *progress;

- (void)mainViewDidLoad;
- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view;
- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view;

@end
