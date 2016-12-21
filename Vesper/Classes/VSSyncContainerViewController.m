//
//  VSSyncContainerViewController.m
//  Vesper
//
//  Created by Brent Simmons on 2/7/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSyncContainerViewController.h"
#import "VSBaseViewController.h"
#import "VSBasicWebViewController.h"
#import "VSLinkButton.h"
#import "VSSyncUI.h"
#import "VSSyncNoAccountViewController.h"
#import "VSSyncSettingsViewController.h"
#import "VSSyncSignInViewController.h"
#import "VSUI.h"


@interface VSSyncContainerViewController () <UIGestureRecognizerDelegate>

@property (nonatomic) UIViewController *currentViewController;
@property (nonatomic) UIViewController *noAccountViewController;
@property (nonatomic) UIViewController *settingsViewController;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizerToCloseSidebar;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, assign) BOOL sidebarShowing;
@property (nonatomic, assign) BOOL userHasAccount;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UIButton *privacyPolicyButton;
@property (nonatomic) BOOL initialViewDidAppear;

@end


@implementation VSSyncContainerViewController


#pragma mark - Init

- (instancetype)init {
	
	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}
	
	self.title = NSLocalizedString(@"Sync", @"Sync");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountExists:) name:VSAccountExistsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDoesNotExist:) name:VSAccountDoesNotExistNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarDidChangeDisplayState:) name:VSSidebarDidChangeDisplayStateNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_panGestureRecognizer.delegate = nil;
	_panGestureRecognizerToCloseSidebar.delegate = nil;
	_tapGestureRecognizer.delegate = nil;
}


#pragma mark - UIViewController

- (void)loadView {
	
	self.noAccountViewController = [VSSyncNoAccountViewController new];
	
	self.view = [VSSyncUI view];
	
	self.containerView = [VSSyncUI view];
	[self.view addSubview:self.containerView];
	self.containerView.backgroundColor = [UIColor greenColor];
	
	//	self.privacyPolicyButton = [VSSyncUI addPrivacyPolicyButtonToView:self.view];
	//	[self.privacyPolicyButton addTarget:self action:@selector(showPrivacyPolicy:) forControlEvents:UIControlEventTouchUpInside];
	
	UIImage *backButtonImage = [app_delegate.theme imageForKey:@"navbarSidebarButton"];
	backButtonImage = [backButtonImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
	backButton.tintColor = [app_delegate.theme colorForKey:@"navbarTextButtonColor"];
	[backButton setImage:backButtonImage forState:UIControlStateNormal];
	backButton.adjustsImageWhenHighlighted = NO;
	UIEdgeInsets insets = UIEdgeInsetsMake(0, -8, 0, 0);
	backButton.contentEdgeInsets = insets;
	[backButton sizeToFit];
	[backButton addTarget:self action:@selector(toggleSidebar:) forControlEvents:UIControlEventTouchUpInside];
	CGRect rContainer = backButton.frame;
	//	rContainer.size.width += 40.0f;
	UIView *containingView = [[UIView alloc] initWithFrame:rContainer];
	//	containingView.backgroundColor = [UIColor redColor];
	[containingView addSubview:backButton];
	
	UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:containingView];
	
	//	UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithImage:backButtonImage landscapeImagePhone:backButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(toggleSidebar:)];
	//	backButtonItem.tintColor = [app_delegate.theme colorForKey:@"navbarTextButtonColor"];
	self.navigationItem.leftBarButtonItem = backButtonItem;
	
	self.panGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	((UIScreenEdgePanGestureRecognizer *)self.panGestureRecognizer).edges = UIRectEdgeLeft;
	self.panGestureRecognizer.delegate = self;
	[self.view addGestureRecognizer:self.panGestureRecognizer];
	
	self.panGestureRecognizerToCloseSidebar = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	self.panGestureRecognizerToCloseSidebar.delegate = self;
	[self.view addGestureRecognizer:self.panGestureRecognizerToCloseSidebar];
	
	self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSidebar:)];
	[self.view addGestureRecognizer:self.tapGestureRecognizer];
	self.tapGestureRecognizer.delegate = self;
	
	self.navigationItem.backBarButtonItem.tintColor = [app_delegate.theme colorForKey:@"navbarButtonColor"];
}


- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	[self ensureCorrectViewControllerIsShowing];
	[VSSyncUI sendSyncUIShowingNotification];
	
}


- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	if (!self.initialViewDidAppear && [VSAccount account].hasUsernameAndPassword && [VSAccount account].loginDidFailWithAuthenticationError) {
		
		/*If there's a sync authentication error, show sign in view controller right away.
		 Well, after a brief delay because the sidebar is animating.*/
		
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		
		[self performSelector:@selector(showSignInViewController) withObject:nil afterDelay:0.3];
	}
	
	self.initialViewDidAppear = YES;
}



- (void)viewDidLayoutSubviews {
	
	CGRect rContainer = self.view.bounds;
	rContainer.origin = CGPointZero;
	//	rContainer.size.height = 350.0;
	[self.containerView qs_setFrameIfNotEqual:rContainer];
	
	if ([self.containerView.subviews count] > 0) {
		
		UIView *subview = self.containerView.subviews[0];
		CGRect rView = rContainer;
		rView.origin = CGPointZero;
		[subview qs_setFrameIfNotEqual:rView];
	}
	
	//	[VSSyncUI layoutPrivacyPolicyButton:self.privacyPolicyButton view:self.view];
}


#pragma mark - Sign In View Controller

- (void)showSignInViewController {
	
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	
	UIViewController *viewController = [VSSyncSignInViewController new];
	UINavigationController *navigationController = [VSUI navigationControllerWithViewController:viewController];
	navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	
	[self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - Panning

- (void)openSidebar:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(openSidebar:) withObject:sender];
	self.sidebarShowing = YES;
}


- (void)postFocusedViewControllerDidChangeNotification:(UIViewController *)focusedViewController {
	
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	if (focusedViewController != nil)
		userInfo[VSFocusedViewControllerKey] = focusedViewController;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSFocusedViewControllerDidChangeNotification object:self userInfo:userInfo];
}


- (void)closeSidebar:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(closeSidebar:) withObject:sender];
	self.sidebarShowing = NO;
	[self postFocusedViewControllerDidChangeNotification:self];
}


- (void)toggleSidebar:(id)sender {
	
	CGRect r = self.navigationController.view.frame;
	if (r.origin.x > 0.1f)
		[self closeSidebar:sender];
	else
		[self openSidebar:sender];
}


- (void)handlePanGestureStateBeganOrChanged:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	CGPoint translation = [panGestureRecognizer translationInView:self.navigationController.view.superview];
	CGFloat frameX = self.navigationController.view.frame.origin.x + translation.x;
	if (frameX < 0.0f)
		frameX = 0.0f;
	
	CGRect frame = self.navigationController.view.frame;
	frame.origin.x = frameX;
	self.navigationController.view.frame = frame;
	
	CGFloat sidebarWidth = [app_delegate.theme floatForKey:@"sidebarWidth"];
	CGFloat distanceFromLeft = frameX;
	CGFloat percentMoved = distanceFromLeft / sidebarWidth;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSDataViewDidPanToRevealSidebarNotification object:self userInfo:@{VSPercentMovedKey: @(percentMoved)}];
	VSSendRightSideViewFrameDidChangeNotification(self, frame);
	
	[panGestureRecognizer setTranslation:CGPointZero inView:self.navigationController.view.superview];
}


- (void)animateSidebarOpenOrClosed {
	
	CGRect rListView = self.navigationController.view.frame;
	
	CGFloat dragThreshold = [app_delegate.theme floatForKey:@"sidebarOpenThreshold"];
	if (self.sidebarShowing)
		dragThreshold = [app_delegate.theme floatForKey:@"sidebarCloseThreshold"];
	
	if (rListView.origin.x < dragThreshold)
		[self closeSidebar:self];
	else
		[self openSidebar:self];
}


- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	[self adjustAnchorPointForGestureRecognizer:panGestureRecognizer];
	
	UIGestureRecognizerState gestureRecognizerState = panGestureRecognizer.state;
	
	switch (gestureRecognizerState) {
			
		case UIGestureRecognizerStateBegan:
		case UIGestureRecognizerStateChanged:
			[self handlePanGestureStateBeganOrChanged:panGestureRecognizer];
			break;
			
		case UIGestureRecognizerStateEnded:
			[self animateSidebarOpenOrClosed];
			break;
			
		default:
			break;
	}
}


- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
	
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		
		CGPoint locationInView = [gestureRecognizer locationInView:self.navigationController.view];
		CGPoint locationInSuperview = [gestureRecognizer locationInView:self.navigationController.view.superview];
		
		self.navigationController.view.layer.anchorPoint = CGPointMake(locationInView.x / self.navigationController.view.bounds.size.width, locationInView.y / self.navigationController.view.bounds.size.height);
		self.navigationController.view.center = locationInSuperview;
	}
}


- (BOOL)viewIsAtLeftEdge {
	return self.navigationController.view.frame.origin.x < 1.0f;
}


- (BOOL)viewIsAtRightEdge {
	return self.navigationController.view.frame.origin.x >= [app_delegate.theme floatForKey:@"sidebarWidth"];
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	
	
	BOOL viewIsAtLeftEdge = [self viewIsAtLeftEdge];
	
	if (gestureRecognizer == self.tapGestureRecognizer && !viewIsAtLeftEdge) {
		return YES;
	}
	
	if (gestureRecognizer != self.panGestureRecognizer && gestureRecognizer != self.panGestureRecognizerToCloseSidebar)
		return NO;
	
	CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.navigationController.view];
	if (fabs(translation.y) > fabs(translation.x))
		return NO;
	
	if (gestureRecognizer == self.panGestureRecognizer) {
		if (viewIsAtLeftEdge && translation.x < 0.0f) /*Sidebar closed*/
			return NO;
		
		if (viewIsAtLeftEdge && translation.x >= 0.0f)
			return YES;
		
		if (viewIsAtLeftEdge && translation.x > 0.0f) /*Sidebar open*/
			return NO;
	}
	
	else if (gestureRecognizer == self.panGestureRecognizerToCloseSidebar) {
		
		if (viewIsAtLeftEdge)
			return NO;
		if (translation.x > 0.0f)
			return NO;
	}
	
	return YES;
}



#pragma mark - Actions

- (void)backButtonPressed:(id)sender {
	
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(openSidebar:) withObject:sender];
}


- (void)showPrivacyPolicy:(id)sender {
	
	[self.navigationController pushViewController:[VSSyncUI privacyPolicyViewController] animated:YES];
}


#pragma mark - Notifications

- (void)accountDoesNotExist:(NSNotification *)note {
	
	[self ensureCorrectViewControllerIsShowing];
}


- (void)accountExists:(NSNotification *)note {
	
	[self ensureCorrectViewControllerIsShowing];
}


- (void)sidebarDidChangeDisplayState:(NSNotification *)note {
	
	BOOL sidebarShowing = [[note userInfo][VSSidebarShowingKey] boolValue];
	self.sidebarShowing = sidebarShowing;
}


#pragma mark - Accessors

- (UIViewController *)settingsViewController {
	
	if (_settingsViewController == nil) {
		_settingsViewController = [VSSyncSettingsViewController new];
	}
	
	return _settingsViewController;
}


#pragma mark - View Controller Switching

- (void)ensureCorrectViewControllerIsShowing {
	
	if (VSSyncIsShutdown()) {
		[self switchToNoAccountViewController];
		return;
	}
	
	if ([[VSAccount account] hasUsernameAndPassword]) {
		[self switchToSyncSettingsViewController];
	}
	else {
		[self switchToNoAccountViewController];
	}
}


- (void)switchToSyncSettingsViewController {
	
	[self swapToViewController:self.settingsViewController];
}


- (void)switchToNoAccountViewController {
	
	[self swapToViewController:self.noAccountViewController];
}


- (void)swapToViewController:(UIViewController *)viewController {
	
	if (viewController == self.currentViewController) {
		return;
	}
	
	[self.view setNeedsLayout];
	
	[self addChildViewController:viewController];
	
	if (!self.currentViewController) {
		
		[self.containerView addSubview:viewController.view];
		[viewController didMoveToParentViewController:self];
		self.currentViewController = viewController;
		return;
	}
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[UIView transitionFromView:self.currentViewController.view toView:viewController.view duration:0.2 options:0 completion:^(BOOL finished) {
		
		[viewController didMoveToParentViewController:self];
		self.currentViewController = viewController;
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
}


@end
