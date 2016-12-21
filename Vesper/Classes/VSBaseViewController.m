//
//  VSBaseViewController.m
//  Vesper
//
//  Created by Brent Simmons on 2/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSBaseViewController.h"
#import "VSTimelineCell.h"
#import "VSBrowserViewController.h"


@interface VSBaseViewController ()

@property (nonatomic, strong, readwrite) VSSmokescreenView *smokescreenView;
@end


@implementation VSBaseViewController


#pragma mark Init

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self == nil)
		return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusedViewControllerDidChange:) name:VSFocusedViewControllerDidChangeNotification object:nil];
	
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Child View Controllers

- (void)pushViewController:(UIViewController *)viewController {
	[self addViewControllerAndItsView:viewController];
}


- (void)popViewController:(UIViewController *)viewController {
	[self removeViewControllerAndItsView:viewController];
}


- (void)addViewControllerAndItsView:(UIViewController *)viewController {
	[viewController willMoveToParentViewController:self];
	
	[self addChildViewController:viewController];
	viewController.view.frame = self.view.frame;
	[self.view addSubview:viewController.view];
	
	[viewController didMoveToParentViewController:self];
}


- (void)removeViewControllerAndItsView:(UIViewController *)viewController {
	
	[viewController willMoveToParentViewController:nil];
	
	[viewController removeFromParentViewController];
	[viewController.view removeFromSuperview];
	
	[viewController didMoveToParentViewController:nil];
}


- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated duration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion {
	
	/*Does a simple fade-in animation.*/
	
	[self pushViewController:viewController];
	
	if (!animated) {
		if (completion != nil)
			completion(YES);
		return;
	}
	
	viewController.view.alpha = 0.0f;
	[UIView animateWithDuration:duration animations:^{
		viewController.view.alpha = 1.0f;
	} completion:completion];
}


- (void)popViewController:(UIViewController *)viewController animated:(BOOL)animated duration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion {
	
	if (!animated) {
		[self popViewController:viewController];
		if (completion != nil)
			completion(YES);
		return;
	}
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	[UIView animateWithDuration:duration animations:^{
		viewController.view.alpha = 0.0f;
	} completion:^(BOOL finished) {
		[self popViewController:viewController];
		if (completion != nil)
			completion(finished);
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
	
}


NSString *VSFocusedViewControllerDidChangeNotification = @"VSFocusedViewControllerDidChangeNotification";
NSString *VSFocusedViewControllerKey = @"VSFocusedViewController";

- (void)postFocusedViewControllerDidChangeNotification:(UIViewController *)focusedViewController {
	
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	if (focusedViewController != nil)
		userInfo[VSFocusedViewControllerKey] = focusedViewController;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSFocusedViewControllerDidChangeNotification object:self userInfo:userInfo];
}


- (void)focusedViewControllerDidChange:(NSNotification *)note {
	
	UIViewController *focusedViewController = [note userInfo][VSFocusedViewControllerKey];
	
	self.isFocusedViewController = (focusedViewController == self);
	
	if ([self.view respondsToSelector:@selector(setScrollsToTop:)])
		((UIScrollView *)(self.view)).scrollsToTop = self.isFocusedViewController;
	
}


#pragma mark - Smokescreen View

- (UIView *)addSmokescreenViewOfClass:(Class)viewClass {
	
	if (self.smokescreenView == nil) {
		UIColor *backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
		self.smokescreenView = [[viewClass alloc] initWithFrame:self.view.frame backgroundColor:backgroundColor];
		[self.smokescreenView setNeedsLayout];
		[self.smokescreenView layoutIfNeeded];
		[self.view addSubview:self.smokescreenView];
		[self.view bringSubviewToFront:self.smokescreenView];
	}
	
	return self.smokescreenView;
}


- (void)removeSmokescreenView {
	
	if (self.smokescreenView == nil)
		return;
	[self.smokescreenView removeFromSuperview];
	self.smokescreenView = nil;
}


- (void)incrementSmokeScreenViewUseCount {
	[self.smokescreenView incrementUseCount];
}

- (void)decrementSmokeScreenViewUseCount {
	[self.smokescreenView decrementUseCount];
	if (self.smokescreenView.useCount < 1)
		[self removeSmokescreenView];
}


#pragma mark - Web Browser

- (void)showBrowserViewForURLString:(NSString *)urlString {
	
	NSParameterAssert(urlString != nil);
	
	NSURL *url = [NSURL URLWithString:urlString];
	if (url == nil)
		return;
	
	if (![VSBrowserViewController canOpenURL:url])
		return;
	
	[self.view endEditing:NO];
	
#if USE_SAFARI_VIEW_CONTROLLER
	[app_delegate openURL:url];
#else
	[[NSNotificationCenter defaultCenter] postNotificationName:VSBrowserViewDidOpenNotification object:self];
	
	[VSTimelineCell emptyCaches];
	VSBrowserViewController *browserViewController = [[VSBrowserViewController alloc] initWithURL:url];
	self.browserViewController = browserViewController;
	
	CGFloat animationDuration = [app_delegate.theme floatForKey:@"browserOpenAnimationDuration"];
	[self pushViewController:browserViewController animated:YES duration:animationDuration completion:^(BOOL finished) {
		[browserViewController beginLoading];
	}];
	[self postFocusedViewControllerDidChangeNotification:browserViewController];
#endif
}


static NSString *stringWithHTTPPrefix(NSString *s) {
	
	if ([s hasPrefix:QSPrefixHTTP] || [s hasPrefix:QSPrefixHTTPS]) {
		return s;
	}
	
	NSURL *URL = [NSURL URLWithString:s];
	if (URL != nil && !QSStringIsEmpty([URL scheme])) {
		return s;
	}
	
	return [NSString stringWithFormat:@"http://%@", s];
}


- (void)openLinkInBrowser:(NSString *)urlString {
	
	[self showBrowserViewForURLString:stringWithHTTPPrefix(urlString)];
}


- (UIViewController *)focusedViewControllerAfterPop:(UIViewController *)poppedViewController {
	
	if (![self qs_hasChildViewController]) {
		return self;
	}
	
	NSUInteger ct = [self.childViewControllers count] - 1;
	NSInteger i = 0;
	for (i = (NSInteger)ct; i >= 0; i--) {
		UIViewController *oneViewController = self.childViewControllers[(NSUInteger)i];
		if (oneViewController != poppedViewController)
			return oneViewController;
	}
	
	return self;
}


- (void)closeBrowser:(UIViewController *)browserViewController {
	
	CGFloat animationDuration = [app_delegate.theme floatForKey:@"browserCloseAnimationDuration"];
	[self popViewController:browserViewController animated:YES duration:animationDuration completion:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:VSBrowserViewDidCloseNotification object:self];
	
	[self postFocusedViewControllerDidChangeNotification:[self focusedViewControllerAfterPop:browserViewController]];
}


- (void)browserDone:(id)sender {
	if (self.browserViewController == nil) {
		[[self nextResponder] qs_performSelectorViaResponderChain:@selector(browserDone:) withObject:sender];
		return;
	}
	
	[self closeBrowser:self.browserViewController];
	self.browserViewController = nil;
}


#pragma mark - Status Bar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//	return UIStatusBarStyleLightContent;
//}


@end

