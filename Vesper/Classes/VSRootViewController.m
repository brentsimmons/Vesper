//
//  VSRootViewController.m
//  Vesper
//
//  Created by Brent Simmons on 11/18/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSRootViewController.h"
#import "VSSidebarViewController.h"
#import "VSTimelineViewController.h"
#import "VSTag.h"
#import "VSSidebarView.h"


@interface VSRootViewController ()

@property (nonatomic, strong) VSSidebarViewController *sidebarViewController;
@property (nonatomic, assign) BOOL sidebarShowing;
@property (nonatomic, strong, readwrite) VSBaseViewController *dataViewController; /*the non-sidebar view controller*/
@property (nonatomic, assign) BOOL shouldShowStatusBar;

@end


@implementation VSRootViewController


#pragma mark Init

- (id)init {
	
	self = [self initWithNibName:nil bundle:nil];
	if (self == nil)
		return nil;
	
	_shouldShowStatusBar = YES;
	[self addObserver:self forKeyPath:@"sidebarShowing" options:0 context:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideSidebarWithoutAnimation:) name:VSShouldCloseSidebarNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleShouldShowStatusBar:) name:VSAppShouldShowStatusBarNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleShouldHideStatusBar:) name:VSAppShouldHideStatusBarNotification object:nil];
	
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"sidebarShowing"];
}


#pragma mark KVO


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"sidebarShowing"] && object == self) {
		NSDictionary *userInfo = @{VSSidebarShowingKey: @(self.sidebarShowing)};
		[[NSNotificationCenter defaultCenter] postNotificationName:VSSidebarDidChangeDisplayStateNotification object:self userInfo:userInfo];
		self.sidebarViewController.view.accessibilityElementsHidden = !self.sidebarShowing;
	}
}


#pragma mark UIViewController

- (void)loadView {
	
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.view.backgroundColor = [UIColor blackColor];
	self.view.opaque = YES;
	
	self.sidebarViewController = [VSSidebarViewController new];
	self.sidebarViewController.rootViewManager = self;
	[self addViewControllerAndItsView:self.sidebarViewController];
	
	[self.sidebarViewController showInitialViewController];
	
	[self postFocusedViewControllerDidChangeNotification:self.dataViewController];
}


- (void)viewWillLayoutSubviews {
	
	/*View should fill the screen -- except for when extended status bar is showing. It should leave room at top for extendedStatusBarHeight - normalStatusBarHeight.*/
	
	CGRect rScreen = [UIScreen mainScreen].bounds;
	CGRect rStatusBar = RSStatusBarFrame();
	CGFloat extraStatusBarHeight = CGRectGetHeight(rStatusBar) - VSNormalStatusBarHeight();
	
	CGRect rView = self.view.frame;
	rView.origin.y = extraStatusBarHeight;
	rView.size.height = CGRectGetHeight(rScreen) - CGRectGetMinY(rView);
	
	[self.view qs_setFrameIfNotEqual:rView];
}


- (void)viewDidLayoutSubviews {
	
	/*View for first subview should have same height as root view.*/
	
	UIView *view = self.dataViewController.view;
	
	CGRect r = view.frame;
	r.origin.y = 0.0f;
	r.size.height = CGRectGetHeight(self.view.frame);
	r.size.width  = CGRectGetWidth(self.view.frame);
	
	[view qs_setFrameIfNotEqual:r];
	
	//	CGRect rSidebar = view.frame;
	//	[self.sidebarViewController.view qs_setFrameIfNotEqual:rSidebar];
}


- (BOOL)prefersStatusBarHidden {
	
	return !self.shouldShowStatusBar;
}


#pragma mark - Notifications

- (void)handleShouldShowStatusBar:(NSNotification *)note {
	self.shouldShowStatusBar = YES;
	[self setNeedsStatusBarAppearanceUpdate];
}


- (void)handleShouldHideStatusBar:(NSNotification *)note {
	self.shouldShowStatusBar = NO;
	[self setNeedsStatusBarAppearanceUpdate];
}


#pragma mark - Utilities

- (void)addShadowToViewController:(UIViewController *)viewController {
	
	CALayer *layer = viewController.view.layer;
	
	layer.backgroundColor = viewController.view.backgroundColor.CGColor;
	layer.shadowOffset = CGSizeMake(0, 0);
	
	layer.shadowRadius = [app_delegate.theme floatForKey:@"sidebarShadowBlurRadius"];
	layer.shadowColor = [app_delegate.theme colorForKey:@"sidebarShadowColor"].CGColor;
	layer.shadowOpacity = (float)[app_delegate.theme floatForKey:@"sidebarShadowOpacity"];
	
	layer.frame = viewController.view.frame;
	
	CGPathRef path = [UIBezierPath bezierPathWithRect:CGRectMake(0.0f, -20.0f, 12.0f, 680.0f)].CGPath;
	layer.shadowPath = path;
}


#pragma mark - VSRootViewManager

- (void)showViewController:(UIViewController *)viewController {
	
	/*This swaps in the view controller that is not the sidebar view controller. List view, credits, whatever.*/
	
	if (viewController != self.dataViewController) {
		
		UIViewController *viewControllerToRemove = self.dataViewController;
		
		[self addChildViewController:viewController];
		
		CGRect r = viewControllerToRemove.view.frame;
		r.size.height = RSContentViewHeight();
		r.size.width = CGRectGetWidth(self.view.bounds);
		viewController.view.frame = r;
		[self addShadowToViewController:viewController];
		
		if (viewControllerToRemove) {
			[self transitionFromViewController:viewControllerToRemove toViewController:viewController duration:0.0f options:0 animations:nil completion:^(BOOL finished) {
				[viewControllerToRemove removeFromParentViewController];
			}];
		}
		
		else {
			[self.view addSubview:viewController.view];
			[viewController didMoveToParentViewController:self];
			viewController.view.frame = r;
		}
		
		self.dataViewController = (VSBaseViewController *)viewController;
	}
	
	if (self.sidebarShowing) {
		[self hideSidebar];
	}
}


- (CGFloat)sidebarAnimationDuration {
	return [app_delegate.theme floatForKey:@"sidebarAnimationDuration"];
}


- (CGFloat)sidebarWidth {
	
	CGFloat sidebarWidth = [app_delegate.theme floatForKey:@"sidebarWidth"];
	if (sidebarWidth < 1.0f)
		return 256.0f;
	return sidebarWidth;
}


- (UIViewAnimationOptions)sidebarAnimationCurve {
	
	NSString *curveString = [app_delegate.theme stringForKey:@"sidebarAnimationCurve"];
	if ([curveString length] < 1)
		return UIViewAnimationOptionCurveEaseInOut;
	
	curveString = [curveString lowercaseString];
	if ([curveString isEqualToString:@"easeinout"])
		return UIViewAnimationOptionCurveEaseInOut;
	else if ([curveString isEqualToString:@"easeout"])
		return UIViewAnimationOptionCurveEaseOut;
	else if ([curveString isEqualToString:@"easein"])
		return UIViewAnimationOptionCurveEaseIn;
	else if ([curveString isEqualToString:@"linear"])
		return UIViewAnimationOptionCurveLinear;
	
	return UIViewAnimationOptionCurveEaseInOut;
}


- (void)showSidebar {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	[UIView animateWithDuration:[self sidebarAnimationDuration] delay:0 options:[self sidebarAnimationCurve] animations:^{
		
		CGRect rListView = self.dataViewController.view.frame;
		rListView.origin.x = [self sidebarWidth];
		
		[self.dataViewController.view setFrame:rListView];
		
		[self.sidebarViewController.sidebarView moveToSidebarOpenPosition];
		self.sidebarShowing = YES;
		
	} completion:^(BOOL finished) {
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		self.sidebarShowing = YES;
	}];
}


- (void)hideSidebar {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[UIView animateWithDuration:[self sidebarAnimationDuration] delay:0 options:[self sidebarAnimationCurve] animations:^{
		
		CGRect rListView = self.dataViewController.view.frame;
		rListView.origin.x = 0.0f;
		
		[self.dataViewController.view setFrame:rListView];
		[self.sidebarViewController.sidebarView moveToSidebarClosedPosition];
		self.sidebarShowing = NO;
		
	} completion:^(BOOL finished) {
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		self.sidebarShowing = NO;
	}];
	
}


- (void)hideSidebarWithoutAnimation:(id)sender {
	
	CGRect rListView = self.dataViewController.view.frame;
	rListView.origin.x = 0.0f;
	
	[self.dataViewController.view qs_setFrameIfNotEqual:rListView];
	if (!self.sidebarShowing)
		self.sidebarShowing = NO;
}


#pragma mark Actions

- (void)toggleSidebar:(id)sender {
	if (self.sidebarShowing)
		[self hideSidebar];
	else
		[self showSidebar];
}


- (void)openSidebar:(id)sender {
	
	//    if (!self.sidebarShowing)
	[self showSidebar];
}


- (void)closeSidebar:(id)sender {
	
	//    if (self.sidebarShowing)
	[self hideSidebar];
}


@end
