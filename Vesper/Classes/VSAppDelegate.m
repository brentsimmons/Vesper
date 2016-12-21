//
//  VSAppDelegate.m
//  Vesper
//
//  Created by Brent Simmons on 11/18/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

@import SafariServices;
//#import <HockeySDK/HockeySDK.h>
#import "VSAppDelegate.h"
#import "VSRootViewController.h"
#import "VSThemeLoader.h"
#import "VSTimelineViewController.h"
#import "VSTypographySettings.h"
#import "VSDataController.h"
#import "VSStatusBarNotification.h"
#import "VSStatusBarNotificationView.h"
#import "VSSyncSignInViewController.h"
#import "VSUI.h"
#import "VSDateManager.h"
#import "VSSyncUI.h"
#import "VSSyncContainerViewController.h"


@interface VSAppDelegate () <SFSafariViewControllerDelegate>

@property (nonatomic, assign) BOOL browserIsOpen;
@property (nonatomic, assign, readwrite) BOOL sidebarShowing;
@property (nonatomic) UIViewController *rootRightSideViewController; /*timeline or credits; may have other views on top by z axis*/
@property (nonatomic, assign) BOOL firstRun;
@property (nonatomic) NSDate *firstRunDate;
@property (nonatomic, readwrite) VSTypographySettings *typographySettings;
@property (nonatomic, readwrite) VSTheme *theme;
@property (nonatomic, readwrite) UIViewController *rootViewController;
@property (nonatomic, assign) NSUInteger numberOfNetworkConnections;
@property (nonatomic, assign) BOOL didMigrateOldData;
@property (nonatomic) VSStatusBarNotification *statusBarNotification;
@property (nonatomic, strong) SFSafariViewController *safariViewController;
@property (nonatomic) UIStatusBarStyle savedStatusBarStyle;

@end

@implementation VSAppDelegate

@synthesize window = _window;
@synthesize theme = _theme;
@synthesize typographySettings = _typographySettings;
@synthesize rootViewController = _rootViewController;


static NSString *firstRunDateKey = @"firstRun";


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
#if !TARGET_IPHONE_SIMULATOR
	
	////	[[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"7eff810d9466dd01144e285d0f686a71"];
	//	[[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"992219ff4b01c24041b90adf87c05020"];
	//	[[BITHockeyManager sharedHockeyManager] startManager];
	//	[[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
	
#endif
	
	NSDictionary *defaults = @{VSDefaultsUseSmallCapsKey : @NO, VSDefaultsFontLevelKey : @1, VSDefaultsTextWeightKey : @(VSTextWeightRegular)};
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	
	self.theme = [VSThemeLoader new].defaultTheme;
	self.typographySettings = [[VSTypographySettings alloc] initWithTheme:self.theme];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
	if ([self.theme boolForKey:@"statusBarHidden"])
		application.statusBarHidden = YES;
	
	self.firstRun = ([[NSUserDefaults standardUserDefaults] objectForKey:firstRunDateKey] == nil);
	if (self.firstRun)
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:firstRunDateKey];
	self.firstRunDate = [[NSUserDefaults standardUserDefaults] objectForKey:firstRunDateKey];
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	self.window.backgroundColor = [UIColor blackColor];
	self.window.opaque = YES;
	
	self.window.rootViewController = [VSRootViewController new];
	self.rootViewController = self.window.rootViewController;
	[self.window makeKeyAndVisible];
	[self updateAppearance];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(browserDidOpen:) name:VSBrowserViewDidOpenNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(browserDidClose:) name:VSBrowserViewDidCloseNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarDidChangeDisplayState:) name:VSSidebarDidChangeDisplayStateNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typographySettingsDidChange:) name:VSTypographySettingsDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(httpCallDidBegin:) name:VSHTTPCallDidBeginNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(httpCallDidEnd:) name:VSHTTPCallDidEndNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDidFailWithAuthenticationError:) name:VSLoginAuthenticationErrorNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDidSucceed:) name:VSLoginAuthenticationSuccessfulNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncUIDidAppear:) name:VSSyncUIShowingNotification object:nil];
	
	[self.window.rootViewController addObserver:self forKeyPath:@"dataViewController" options:NSKeyValueObservingOptionInitial context:NULL];
	[self.window.rootViewController addObserver:self forKeyPath:@"numberOfNetworkConnections" options:NSKeyValueObservingOptionInitial context:NULL];
	
	if ([self.theme boolForKey:@"statusBarNotification.testByShowingAtStartup"]) {
		[self performSelector:@selector(showAuthenticationError) withObject:nil afterDelay:2.0];
	}
	
	return YES;
}


- (void)emptyBrowserCacheIfPossible {
	if (!self.browserIsOpen)
		[[NSURLCache sharedURLCache] removeAllCachedResponses];
}


- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[self emptyBrowserCacheIfPossible];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	[self emptyBrowserCacheIfPossible];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"dataViewController"])
		self.rootRightSideViewController = ((VSRootViewController *)(self.window.rootViewController)).dataViewController;
	else if ([keyPath isEqualToString:@"numberOfNetworkConnections"])
		[self updateNetworkActivityIndicator];
}


#pragma mark - Notifications

- (void)browserDidOpen:(NSNotification *)note {
	self.browserIsOpen = YES;
}


- (void)browserDidClose:(NSNotification *)note {
	self.browserIsOpen = NO;
}


- (void)sidebarDidChangeDisplayState:(NSNotification *)note {
	BOOL sidebarShowing = [[note userInfo][VSSidebarShowingKey] boolValue];
	self.sidebarShowing = sidebarShowing;
}


- (void)typographySettingsDidChange:(NSNotification *)note {
	[self updateAppearance];
}


- (void)httpCallDidBegin:(NSNotification *)note {
	self.numberOfNetworkConnections = self.numberOfNetworkConnections - 1;
}


- (void)httpCallDidEnd:(NSNotification *)note {
	self.numberOfNetworkConnections = self.numberOfNetworkConnections + 1;
}


- (void)loginDidFailWithAuthenticationError:(NSNotification *)note {
	[self showAuthenticationError];
}


- (void)loginDidSucceed:(NSNotification *)note {
	[self closeAuthenticationError];
}


- (void)syncUIDidAppear:(NSNotification *)note {
	[self dismissStatusBarNotification];
}


#pragma mark - Status Bar Notifications

- (void)showStatusBarNotification:(UIView *)view {
	
	[self dismissStatusBarNotification];
	
	self.statusBarNotification = [[VSStatusBarNotification alloc] initWithView:view];
	[self.statusBarNotification show];
}


- (void)dismissStatusBarNotification {
	
	[self.statusBarNotification hide];
	self.statusBarNotification = nil;
}


- (BOOL)syncUIIsDisplayed {
	
	UIViewController *viewController = self.rootRightSideViewController;
	if ([viewController class] == [VSSyncContainerViewController class]) {
		return YES;
	}
	
	if ([viewController class] == [UINavigationController class]) {
		UINavigationController *navigationController = (UINavigationController *)viewController;
		UIViewController *rootViewController = [navigationController.viewControllers firstObject];
		if ([rootViewController isKindOfClass:[VSSyncContainerViewController class]]) {
			return YES;
		}
	}
	
	return NO;
}


- (void)showAuthenticationError {
	
	if (self.statusBarNotification) {
		return;
	}
	if ([self syncUIIsDisplayed]) {
		return;
	}
	
	NSString *iconName = [app_delegate.theme stringForKey:@"statusBarNotification.authenticationErrorIcon"];
	NSString *s = NSLocalizedString(@"Sync authentication error", nil);
	
	VSStatusBarNotificationView *view = [[VSStatusBarNotificationView alloc] initWithIconName:iconName text:s];
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(statusBarNotificationTapped:)];
	[view addGestureRecognizer:tapGestureRecognizer];
	
	[self showStatusBarNotification:view];
}


- (void)closeAuthenticationError {
	
	[self dismissStatusBarNotification];
}

- (void)statusBarNotificationTapped:(id)sender {
	
	[self dismissStatusBarNotification];
	[self presentSignInViewController];
}


- (void)presentSignInViewController {
	
	[self presentModalViewController:[VSSyncSignInViewController new]];
}


- (void)presentModalViewController:(UIViewController *)viewController {
	
	UINavigationController *navigationController = [VSUI navigationControllerWithViewController:viewController];
	navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	
	[self.window.rootViewController presentViewController:navigationController animated:YES completion:^{
		
		;
	}];
}


#pragma mark - Network Activity Indicator

- (void)updateNetworkActivityIndicator {
	
	NSAssert([NSThread isMainThread], nil);
	
	BOOL shouldRunSpinner = (self.numberOfNetworkConnections > 0);
	[UIApplication sharedApplication].networkActivityIndicatorVisible = shouldRunSpinner;
}


#pragma mark - Appearance

- (void)updateAppearance {
	
	//	UIColor *titleColor = [app_delegate.theme colorForKey:@"navbarTitleColor"];
	//
	//	UIFont *font = [app_delegate.theme fontForKey:@"navbarTitleFont"];
	//	if (VSDefaultsTextWeight() == VSTextWeightLight)
	//		font = [app_delegate.theme fontForKey:@"navbarTitleLightFont"];
	
	/*Do this every time because typography settings may have changed since last time.
	 Also: this is the only place in the app where there's a UINavigationBar.
	 If that changes, this will have to move.*/
	
	
	//	[UINavigationBar appearance].titleTextAttributes = @{NSForegroundColorAttributeName : titleColor, NSFontAttributeName: font};
	//	[UINavigationBar appearance].barTintColor = [self.theme colorForKey:@"navbarBackgroundColor"];
	//
	//	[UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil].barTintColor = [UIColor whiteColor];
	
	//	UIFont *textButtonFont = [app_delegate.theme fontForKey:@"navbarBackButtonFont"];
	//	if (VSDefaultsTextWeight() == VSTextWeightLight) {
	//		textButtonFont = [app_delegate.theme fontForKey:@"navbarBackButtonLightFont"];
	//	}
	//
	//	NSDictionary *barButtonAppearance = @{NSForegroundColorAttributeName: [app_delegate.theme colorForKey:@"navbarTextButtonColor"], NSFontAttributeName : textButtonFont};
	//	[[UIBarButtonItem appearance] setTitleTextAttributes:barButtonAppearance forState:UIControlStateNormal];
	//	[[UIBarButtonItem appearance] setTintColor:[app_delegate.theme colorForKey:@"navbarTextButtonColor"]];
	//
	//	UIImage *backButtonImage = [UIImage imageNamed:@"chevron"];
	//	CGSize imageSize = backButtonImage.size;
	//	backButtonImage = [backButtonImage resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, imageSize.height, 0.0, 0.0)];
	//	backButtonImage = [backButtonImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	//	[[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
	//
	//	CGFloat titleOffsetHorizontal = [app_delegate.theme floatForKey:@"realNavbarBackButtonTextOffsetX"];
	//	CGFloat titleOffsetVertical = [app_delegate.theme floatForKey:@"realNavbarBackButtonTextOffsetY"];
	//	[[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(titleOffsetHorizontal, titleOffsetVertical) forBarMetrics:UIBarMetricsDefault];
	
	/*Switch*/
	
	[UISwitch appearance].onTintColor = [app_delegate.theme colorForKey:@"switchOnTintColor"];
}


#pragma mark - Safari View Controller

- (void)openURL:(NSURL *)url {
	
	self.savedStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
	
	// Works best with Safari view controller.
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	
	self.browserIsOpen = YES;
	
	self.safariViewController = [[SFSafariViewController alloc] initWithURL:url entersReaderIfAvailable:NO];
	self.safariViewController.delegate = self;
	[self.rootViewController presentViewController:self.safariViewController animated:YES completion:nil];
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
	
	self.browserIsOpen = NO;
	self.safariViewController = nil;
	[[UIApplication sharedApplication] setStatusBarStyle:self.savedStatusBarStyle animated:YES];
}

@end
