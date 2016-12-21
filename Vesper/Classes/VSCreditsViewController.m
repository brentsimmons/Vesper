//
//  VSCreditsViewController.m
//  Vesper
//
//  Created by Brent Simmons on 2/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSCreditsViewController.h"
#import "UIView+RSExtras.h"
#import "CreditsPosterView.h"
#import "CreditsListView.h"


@interface VSCreditsAccessibilityEscapeHatch : UIView
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
+ (instancetype)escapeHatch;
@end

@implementation VSCreditsAccessibilityEscapeHatch

+ (instancetype)escapeHatch
{
	return [[self alloc] initWithFrame:CGRectMake(0, 20, 60, 60)];
}


- (BOOL)isAccessibilityElement
{
	return YES;
}


- (NSString *)accessibilityLabel
{
	return NSLocalizedString(@"List", nil);
}


- (NSString *)accessibilityHint
{
	return NSLocalizedString(@"Double tap to open the sidebar", nil);
}


- (UIAccessibilityTraits)accessibilityTraits
{
	return [super accessibilityTraits] | UIAccessibilityTraitButton;
}


- (BOOL)accessibilityActivate
{
	NSMethodSignature *signature = [self.target methodSignatureForSelector:self.action];
	if (signature)
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setTarget:self.target];
		[invocation setSelector:self.action];
		void *voidSelf = (__bridge void *)self;
		[invocation setArgument:&voidSelf atIndex:2];
		[invocation invoke];
		return YES;
	}
	return NO;
}


@end


@interface VSCreditsViewController ()

@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizerToCloseSidebar;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) BOOL sidebarShowing;
@property (nonatomic) UIToolbar *statusBarBackgroundView;
@property (nonatomic) CreditsPosterView *posterView;
@property (nonatomic) CreditsListView *listView;
@property (nonatomic) UIScrollView *scrollView;

@end


@implementation VSCreditsViewController


- (id)init {
	
	self = [self initWithNibName:nil bundle:nil];
	if (self == nil) {
		return nil;
	}
	
	[self addObserver:self forKeyPath:@"sidebarShowing" options:0 context:NULL];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarDidChangeDisplayState:) name:VSSidebarDidChangeDisplayStateNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"sidebarShowing"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_panGestureRecognizer.delegate = nil;
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"sidebarShowing"])
		[self updateScrollingEnabled];
}


#pragma mark - Notifications

- (void)sidebarDidChangeDisplayState:(NSNotification *)note {
	BOOL sidebarShowing = [[note userInfo][VSSidebarShowingKey] boolValue];
	self.sidebarShowing = sidebarShowing;
	if (!sidebarShowing) {
		if (self.view.superview != nil)
			[self postFocusedViewControllerDidChangeNotification:self];
	}
}


#pragma mark - UIViewController

- (void)loadView {
	
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.view.opaque = YES;
	self.view.backgroundColor = [app_delegate.theme colorForKey:@"credits.backgroundColor"];
	
	self.scrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	CGRect rStatusBar = RSNormalStatusBarFrame();
	self.scrollView.backgroundColor = self.view.backgroundColor;
	self.scrollView.bounces = YES;
	self.scrollView.alwaysBounceVertical = YES;
	self.scrollView.delegate = self;
	self.scrollView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(rStatusBar), 0.0f, 0.0f, 0.0f);
	self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;
	self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.scrollView];
	
	self.posterView = [[CreditsPosterView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[self.scrollView addSubview:self.posterView];
	
	self.listView = [[CreditsListView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[self.scrollView addSubview:self.listView];
	
	
	self.statusBarBackgroundView = [[UIToolbar alloc] initWithFrame:rStatusBar];
	self.statusBarBackgroundView.translucent = YES;
	self.statusBarBackgroundView.opaque = NO;
	if ([app_delegate.theme boolForKey:@"creditsStatusBarDarkBackground"]) {
		self.statusBarBackgroundView.barStyle = UIBarStyleBlack;
	}
	[self.view insertSubview:self.statusBarBackgroundView aboveSubview:self.scrollView];
	self.statusBarBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
	
	/*Gesture recognizers*/
	
	if ([app_delegate.theme boolForKey:@"sidebarOpenPanRequiresEdge"]) {
		
		self.panGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
		((UIScreenEdgePanGestureRecognizer *)self.panGestureRecognizer).edges = UIRectEdgeLeft;
		
		self.panGestureRecognizerToCloseSidebar = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
		self.panGestureRecognizerToCloseSidebar.delegate = self;
		[self.view addGestureRecognizer:self.panGestureRecognizerToCloseSidebar];
	}
	else {
		self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	}
	self.panGestureRecognizer.delegate = self;
	[self.view addGestureRecognizer:self.panGestureRecognizer];
	
	self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSidebar:)];
	[self.view addGestureRecognizer:self.tapGestureRecognizer];
	self.tapGestureRecognizer.delegate = self;
	
	[self.scrollView flashScrollIndicators];
	
	VSCreditsAccessibilityEscapeHatch *escapeHatch = [VSCreditsAccessibilityEscapeHatch escapeHatch];
	escapeHatch.target = self;
	escapeHatch.action = @selector(toggleSidebar:);
	[self.view addSubview:escapeHatch];
}


- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	if (![app_delegate.theme boolForKey:@"creditsStatusBarDarkBackground"])
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}


- (void)viewWillLayoutSubviews {
	
	CGRect r = self.view.frame;
	r.size.height = RSContentViewHeight();
	[self.view qs_setFrameIfNotEqual:r];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	self.posterView.frame = self.view.bounds;
	
	CGRect rListView = self.listView.frame;
	rListView.origin.y = CGRectGetMaxY(self.posterView.frame);
	rListView.size = [self.listView sizeThatFits:rListView.size];
	rListView.size.width = CGRectGetWidth(self.view.bounds);
	self.listView.frame = rListView;
	
	
	CGSize contentSize = CGSizeZero;
	contentSize.width = CGRectGetWidth(self.view.frame);
	contentSize.height = CGRectGetHeight(self.posterView.frame) + CGRectGetHeight(self.listView.frame);
	self.scrollView.contentSize = contentSize;
	
}


#pragma mark - Scrolling

- (BOOL)viewIsAtLeftEdge {
	return self.view.frame.origin.x < 1.0f;
}

- (BOOL)viewIsAtRightEdge {
	return self.view.frame.origin.x >= [app_delegate.theme floatForKey:@"sidebarWidth"];
}


- (void)updateScrollingEnabled {
	self.scrollView.scrollEnabled = !self.sidebarShowing;
	self.scrollView.scrollsToTop = !self.sidebarShowing;
}


#pragma mark - Panning

- (void)openSidebar:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(openSidebar:) withObject:sender];
	self.sidebarShowing = YES;
	[self updateScrollingEnabled];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}


- (void)closeSidebar:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(closeSidebar:) withObject:sender];
	self.sidebarShowing = NO;
	[self postFocusedViewControllerDidChangeNotification:self];
	[self updateScrollingEnabled];
	if (![app_delegate.theme boolForKey:@"creditsStatusBarDarkBackground"])
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}


- (void)toggleSidebar:(id)sender {
	
	CGRect r = self.view.frame;
	if (r.origin.x > 0.1f)
		[self closeSidebar:sender];
	else
		[self openSidebar:sender];
}


- (void)handlePanGestureStateBeganOrChanged:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	CGPoint translation = [panGestureRecognizer translationInView:self.view.superview];
	CGFloat frameX = self.view.frame.origin.x + translation.x;
	if (frameX < 0.0f)
		frameX = 0.0f;
	
	CGRect frame = self.view.frame;
	frame.origin.x = frameX;
	self.view.frame = frame;
	
	CGFloat sidebarWidth = [app_delegate.theme floatForKey:@"sidebarWidth"];
	CGFloat distanceFromLeft = frameX;
	CGFloat percentMoved = distanceFromLeft / sidebarWidth;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSDataViewDidPanToRevealSidebarNotification object:self userInfo:@{VSPercentMovedKey: @(percentMoved)}];
	VSSendRightSideViewFrameDidChangeNotification(self, frame);
	
	[panGestureRecognizer setTranslation:CGPointZero inView:self.view.superview];
	
	[self updateScrollingEnabled];
}


- (void)animateSidebarOpenOrClosed {
	
	CGRect rListView = self.view.frame;
	
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
		
		CGPoint locationInView = [gestureRecognizer locationInView:self.view];
		CGPoint locationInSuperview = [gestureRecognizer locationInView:self.view.superview];
		
		self.view.layer.anchorPoint = CGPointMake(locationInView.x / self.view.bounds.size.width, locationInView.y / self.view.bounds.size.height);
		self.view.center = locationInSuperview;
	}
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	
	if ([self qs_hasChildViewController])
		return NO;
	
	BOOL viewIsAtLeftEdge = [self viewIsAtLeftEdge];
	
	if (gestureRecognizer == self.tapGestureRecognizer) {
		return YES;//!viewIsAtLeftEdge;
	}
	
	if (gestureRecognizer != self.panGestureRecognizer && gestureRecognizer != self.panGestureRecognizerToCloseSidebar)
		return NO;
	
	CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.view];
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


#pragma mark - Web Browser

- (void)openVesperHomePage:(id)sender {
	[self openLinkInBrowser:[app_delegate.theme stringForKey:@"creditSupportURL"]];
}


@end

