//
//  VSBrowserViewController.m
//  Vesper
//
//  Created by Brent Simmons on 2/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSBrowserViewController.h"
#import "VSBrowserBackgroundView.h"
#import "VSBrowserToolbarView.h"
#import "VSActivityPopover.h"


@interface VSBrowserViewController ()

@property (nonatomic, strong) VSBrowserBackgroundView *view;
@property (nonatomic, strong) NSURL *initialURL;
@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) VSBrowserToolbarView *toolbar;
@property (nonatomic, strong) VSBrowserPullToRefreshView *pullToRefreshView;
@property (nonatomic, strong) NSTimer *updateBrowserIsLoadingTimer;
@property (nonatomic, strong) NSURL *currentURL;
@property (nonatomic, strong) NSString *titleForPopoverCommands;
@property (nonatomic, strong) NSString *urlStringForPopoverCommands;
@property (nonatomic, strong) VSActivityPopover *activityPopover;
@property (nonatomic, strong) UIView *statusBarBackgroundView;
@property (nonatomic, strong) UIView *statusBarBorderView;
@property (nonatomic, assign) BOOL animatingContentInset;

@end




@implementation VSBrowserViewController

@dynamic view;

#pragma mark - Class Methods

+ (BOOL)canOpenURL:(NSURL *)url {
	
	NSString *scheme = [[url scheme] lowercaseString];
	return [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
}


#pragma mark Init

- (id)initWithURL:(NSURL *)initialURL {
	
	NSParameterAssert(initialURL != nil);
	
	self = [self initWithNibName:nil bundle:nil];
	if (self == nil)
		return nil;
	
	_initialURL = initialURL;
	[self addObserver:self forKeyPath:@"isFocusedViewController" options:0 context:nil];
	
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	_webview.scrollView.delegate = nil;
	_webview.delegate = nil;
	[self removeObserver:self forKeyPath:@"isFocusedViewController"];
	[_updateBrowserIsLoadingTimer qs_invalidateIfValid];
	_updateBrowserIsLoadingTimer = nil;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"isFocusedViewController"] && object == self)
		self.webview.scrollView.scrollsToTop = self.isFocusedViewController;
}


#pragma mark UIViewController

- (void)loadView {
	
	self.view = [[VSBrowserBackgroundView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.view.backgroundColor = [app_delegate.theme colorForKey:@"browserBackgroundColor"];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	self.view.accessibilityViewIsModal = YES;
	
	self.statusBarBackgroundView = [[UIView alloc] initWithFrame:RSStatusBarFrame()];
	self.statusBarBackgroundView.backgroundColor = [app_delegate.theme colorForKey:@"browserStatusBackgroundColor"];
	self.statusBarBackgroundView.opaque = YES;
	self.view.statusBarBackgroundView = self.statusBarBackgroundView;
	[self.view addSubview:self.statusBarBackgroundView];
	
	CGRect rBorder = CGRectMake(0.0f, CGRectGetHeight(RSStatusBarFrame()), CGRectGetWidth(self.view.bounds), 0.5f);
	if (!RSIsRetinaScreen()) {
		rBorder.size.height = 1.0f;
	}
	self.statusBarBorderView = [[UIView alloc] initWithFrame:rBorder];
	self.statusBarBorderView.backgroundColor = [app_delegate.theme colorForKey:@"browserStatusBorderColor"];
	self.statusBarBorderView.autoresizingMask = UIViewAutoresizingNone;
	[self.view addSubview:self.statusBarBorderView];
	
	CGRect rWebview = self.view.bounds;
	rWebview.origin.y = VSNormalStatusBarHeight();
	rWebview.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetMinY(rWebview);
	
	self.webview = [[UIWebView alloc] initWithFrame:rWebview];
	self.webview.scalesPageToFit = YES;
	self.webview.dataDetectorTypes =  UIDataDetectorTypePhoneNumber | UIDataDetectorTypeLink;
	self.webview.delegate = self;
	[self.view addSubview:self.webview];
	
	for (UIView *oneSubview in self.webview.scrollView.subviews) { /*Hide shadows*/
		if ([oneSubview isKindOfClass:[UIImageView class]])
			oneSubview.hidden = YES;
	}
	self.webview.scrollView.backgroundColor = self.view.backgroundColor;
	
	CGFloat toolbarBorderWidth = [app_delegate.theme floatForKey:@"browserToolbarBorderWidth"];
	CGFloat toolbarHeight = [app_delegate.theme floatForKey:@"browserToolbarHeight"];
	if (toolbarBorderWidth > 0.1f)
		toolbarHeight += toolbarBorderWidth;
	CGRect rToolbar = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, toolbarHeight);
	self.toolbar = [[VSBrowserToolbarView alloc] initWithFrame:rToolbar];
	//    self.toolbar.backgroundColor = [app_delegate.theme colorForKey:@"browserToolbarBackgroundColor"];
	[self.view addSubview:self.toolbar];
	
	//	CGFloat toolbarBorderWidth = [app_delegate.theme floatForKey:@"browserToolbarBorderWidth"];
	//	if (toolbarBorderWidth > 0.1f) {
	//
	//		UIView *toolbarBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, toolbarBorderWidth)];
	//		toolbarBorder.opaque = YES;
	//		toolbarBorder.backgroundColor = [app_delegate.theme colorForKey:@"browserToolbarBorderColor"];
	//		self.view.toolbarBorderView = toolbarBorder;
	//		[self.view addSubview:toolbarBorder];
	//	}
	
	if ([app_delegate.theme boolForKey:@"toolbarShadowVisible"]) {
		UIImage *toolbarShadowImage = [app_delegate.theme imageForKey:@"toolbarShadowAsset"];
		UIImageView *toolbarShadowView = [[UIImageView alloc] initWithImage:toolbarShadowImage];
		[self.view insertSubview:toolbarShadowView aboveSubview:self.webview];
	}
	
	CGFloat pullToRefreshHeight = [app_delegate.theme floatForKey:@"browserPullToRefresh.viewHeight"];
	self.pullToRefreshView = [[VSBrowserPullToRefreshView alloc] initWithFrame:CGRectMake(0.0f, -(pullToRefreshHeight) + 0.0f, self.view.frame.size.width, pullToRefreshHeight)];
	self.pullToRefreshView.height = pullToRefreshHeight;
	self.pullToRefreshView.delegate = self;
	[self.webview.scrollView addSubview:self.pullToRefreshView];
	[self.pullToRefreshView setNeedsDisplay];
	
	[self.view setNeedsLayout];
	
	self.pullToRefreshView.url = self.initialURL;
	
	self.webview.scrollView.delegate = self;
	
	self.webview.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0f/*RSStatusBarHeight() + 1.0f*/, 0.0f, VSNavbarHeight, 0.0f);
	self.webview.scrollView.contentInset = UIEdgeInsetsMake(0.0f/*RSStatusBarHeight() + 1.0f*/, 0.0f, VSNavbarHeight, 0.0f);
	
	[self.view bringSubviewToFront:self.statusBarBackgroundView];
	[self.view bringSubviewToFront:self.statusBarBorderView];
	
	[self updateUI];
	
	//	self.toolbar.hidden = YES;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
}


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
}


#pragma mark API

- (void)beginLoading {
	NSURLRequest *request = [NSURLRequest requestWithURL:self.initialURL];
	[self.webview loadRequest:request];
	if (self.pullToRefreshView.pullToRefreshState != VSPullToRefreshLoading)
		self.pullToRefreshView.pullToRefreshState = VSPullToRefreshLoading;
}


#pragma mark Notifications

//- (void)focusedViewControllerDidChange:(NSNotification *)note {
//
////    UIViewController *viewController = [note userInfo][VSFocusedViewControllerKey];
////    BOOL sidebarIsFocused = (self == viewController);
////    self.webview.scrollsToTop = sidebarIsFocused;
//}


#pragma mark - Actions


- (void)browserBack:(id)sender {
	if (self.webview.canGoBack)
		[self.webview goBack];
	[self updateUI];
}


- (void)browserForward:(id)sender {
	if (self.webview.canGoForward)
		[self.webview goForward];
	[self updateUI];
}


- (void)browserActivity:(id)sender {
	[self updateUI];
}


- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)openMailComposer:(id)sender {
	
	if ([self.urlStringForPopoverCommands length] < 1)
		return;
	
	MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
	mailComposeViewController.mailComposeDelegate = self;
	
	if ([self.titleForPopoverCommands length] > 0)
		[mailComposeViewController setSubject:self.titleForPopoverCommands];
	
	[mailComposeViewController setMessageBody:self.urlStringForPopoverCommands isHTML:NO];
	
	[self presentViewController:mailComposeViewController animated:YES completion:nil];
}


- (void)openSMSComposer:(id)sender {
	
	if ([self.urlStringForPopoverCommands length] < 1)
		return;
	
	MFMessageComposeViewController *textComposeViewController = [[MFMessageComposeViewController alloc] init];
	textComposeViewController.messageComposeDelegate = self;
	
	NSString *messageText = self.urlStringForPopoverCommands;
	if ([self.titleForPopoverCommands length] > 0)
		messageText = [NSString stringWithFormat:@"%@: %@", self.titleForPopoverCommands, self.urlStringForPopoverCommands];
	
	textComposeViewController.body = messageText;
	
	[self presentViewController:textComposeViewController animated:YES completion:nil];
}


- (void)copyURL:(id)sender {
	if ([self.urlStringForPopoverCommands length] < 1)
		return;
	[UIPasteboard generalPasteboard].string = self.urlStringForPopoverCommands;
}


- (void)openInSafari:(id)sender {
	
	if ([self.urlStringForPopoverCommands length] < 1)
		return;
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.urlStringForPopoverCommands]];
	
	[self qs_performSelectorViaResponderChain:@selector(browserDone:) withObject:sender];
}


- (void)activityButtonTapped:(id)sender {
	
	if (self.activityPopover.showing) {
		[self.activityPopover dismiss:nil];
		self.activityPopover = nil;
		return;
	}
	
	NSString *urlString = [self.webview stringByEvaluatingJavaScriptFromString:@"window.location.href"];
	if ([urlString isEqualToString:@"about:blank"])
		urlString = nil;
	if ([urlString length] < 1)
		urlString = [self.currentURL absoluteString];
	if ([urlString length] < 1)
		urlString = [self.initialURL absoluteString];
	if ([urlString length] < 1)
		return;
	
	self.urlStringForPopoverCommands = urlString;
	self.titleForPopoverCommands = [self.webview stringByEvaluatingJavaScriptFromString:@"document.title"];
	
	self.activityPopover = [[VSActivityPopover alloc] initWithPopoverSpecifier:@"browserPopover"];
	
	[self.activityPopover addItemWithTitle:NSLocalizedString(@"Safari", @"Safari") image:[UIImage imageNamed:@"activity-safari"] target:self action:@selector(openInSafari:)];
	
	if ([MFMessageComposeViewController canSendText])
		[self.activityPopover addItemWithTitle:NSLocalizedString(@"Message", @"Message") image:[UIImage imageNamed:@"activity-messages"] target:self action:@selector(openSMSComposer:)];
	
	if ([MFMailComposeViewController canSendMail])
		[self.activityPopover addItemWithTitle:NSLocalizedString(@"Mail", @"Mail") image:[UIImage imageNamed:@"activity-mail"] target:self action:@selector(openMailComposer:)];
	
	[self.activityPopover addItemWithTitle:NSLocalizedString(@"Copy", @"Copy") image:[UIImage imageNamed:@"activity-copy"] target:self action:@selector(copyURL:)];
	
	[self.activityPopover showInView:self.view fromBehindBar:self.toolbar animationDirection:VSUp];
}


- (void)browserDone:(id)sender {
	
	[self.webview stopLoading];
	self.webview.scrollView.delegate = nil;
	self.webview.delegate = nil;
	
	[self.updateBrowserIsLoadingTimer qs_invalidateIfValid];
	self.updateBrowserIsLoadingTimer = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[super browserDone:sender];
}


#pragma mark - UI

- (void)updateStatusBarActivityIndicator:(BOOL)loading {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = loading;
}


- (void)setPullToRefreshViewLoading:(BOOL)loading {
	
	if (loading && self.pullToRefreshView.pullToRefreshState == VSPullToRefreshLoading)
		return;
	
	if (!loading && self.pullToRefreshView.pullToRefreshState == VSPullToRefreshNormal)
		return;
	
	if (loading) {
		if (self.pullToRefreshView.pullToRefreshState != VSPullToRefreshLoading)
			self.pullToRefreshView.pullToRefreshState = VSPullToRefreshLoading;
	}
	
	else { /*not loading*/
		if (self.pullToRefreshView.pullToRefreshState == VSPullToRefreshLoading)
			self.pullToRefreshView.pullToRefreshState = VSPullToRefreshNormal;
	}
	
}


- (void)timedUpdateBrowserIsLoading:(id)sender {
	
	[self.updateBrowserIsLoadingTimer qs_invalidateIfValid];
	self.updateBrowserIsLoadingTimer = nil;
	
	[self setPullToRefreshViewLoading:self.webview.isLoading];
}


- (void)coalescedUpdateBrowserIsLoading:(BOOL)loading {
	
	if (loading == NO && self.pullToRefreshView.pullToRefreshState == VSPullToRefreshNormal)
		return;
	
	if (loading) {
		[self setPullToRefreshViewLoading:loading];
		return;
	}
	
	[self.updateBrowserIsLoadingTimer qs_invalidateIfValid];
	self.updateBrowserIsLoadingTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(timedUpdateBrowserIsLoading:) userInfo:nil repeats:NO];
}


- (void)updateUI {
	
	CGFloat disabledOpacity = 0.5f;
	
	BOOL canGoBack = self.webview.canGoBack;
	BOOL canGoForward = self.webview.canGoForward;
	
	self.toolbar.backButton.alpha = canGoBack ? 1.0f : disabledOpacity;
	self.toolbar.backButton.enabled = canGoBack;
	self.toolbar.forwardButton.alpha = canGoForward ? 1.0f : disabledOpacity;
	self.toolbar.forwardButton.enabled = canGoForward;
	
	BOOL isLoading = self.webview.isLoading;
	//    if (self.pullToRefreshView.refreshInProgress != isLoading)
	//        self.pullToRefreshView.refreshInProgress = isLoading;
	//    if (!isLoading)
	//        [self.pullToRefreshView refreshScrollViewDataSourceDidFinishLoading:self.webview.scrollView];
	
	[self coalescedUpdateBrowserIsLoading:isLoading];
	[self adjustPullToRefreshFrame];
	
	[self updateStatusBarActivityIndicator:isLoading];
	
	if (!self.animatingContentInset) {
		if (self.webview.scrollView.contentOffset.y < -0.01f)
			self.statusBarBorderView.hidden = YES;
		else
			self.statusBarBorderView.hidden = NO;
	}
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	
	//    [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
	self.pullToRefreshView.url = [request qs_loadingURL];
	[self updateStatusBarActivityIndicator:YES];
	return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webView {
	[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
	[self updateStatusBarActivityIndicator:YES];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	self.pullToRefreshView.url = [webView.request qs_loadingURL];
	[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
	self.currentURL = webView.request.mainDocumentURL;
	[self updateStatusBarActivityIndicator:NO];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
	[self updateStatusBarActivityIndicator:NO];
}


#pragma mark - VSPullToRefreshDelegate

- (void)refreshViewDidTriggerRefresh:(VSBrowserPullToRefreshView *)view {
	[self.webview reload];
	[self updateUI];
	[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
}


- (BOOL)refreshViewDataSourceIsLoading:(VSBrowserPullToRefreshView *)view {
	return self.webview.isLoading;
}


- (void)refreshView:(VSBrowserPullToRefreshView *)view willAnimateToContentInset:(UIEdgeInsets)contentInset {
	self.animatingContentInset = YES;
}


- (void)refreshView:(VSBrowserPullToRefreshView *)view didAnimateToContentInset:(UIEdgeInsets)contentInset {
	self.animatingContentInset = NO;
	[self updateUI];
}


#pragma mark - Layout

- (void)adjustPullToRefreshFrame {
	
	/*For sites that don't quite fit right horizontally on the phone, we have to adjust the frame of the pull to refresh view so that it appears static on the x axis. (Because you can pull the site to the left and right.)*/
	
	CGRect rPullToRefreshView = self.pullToRefreshView.frame;
	rPullToRefreshView.origin.x = self.webview.scrollView.bounds.origin.x;
	[self.pullToRefreshView qs_setFrameIfNotEqual:rPullToRefreshView];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
	//	NSLog(@"scrollViewDidScroll: %f", scrollView.contentOffset.y);
	[self updateUI];
	[self.pullToRefreshView refreshScrollViewDidScroll:scrollView];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[self.pullToRefreshView refreshScrollViewDidEndDragging:scrollView];
	[self adjustPullToRefreshFrame];
}


@end


