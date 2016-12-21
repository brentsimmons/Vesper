//
//  VSBasicWebViewController.m
//  Vesper
//
//  Created by Brent Simmons on 4/23/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSBasicWebViewController.h"
#import "VSProgressView.h"


@interface VSBasicWebViewController () <UIWebViewDelegate>

@property (nonatomic) UIWebView *webview;
@property (nonatomic) NSURL *URL;
@property (nonatomic) NSString *fallbackResourceName;
@property (nonatomic) BOOL didShowInitialError;
@property (nonatomic) VSProgressView *progressView;

@end

@implementation VSBasicWebViewController


#pragma mark - Init

- (instancetype)initWithURL:(NSURL *)URL fallbackResourceName:(NSString *)fallbackResourceName title:(NSString *)title {

	self = [self initWithNibName:@"BasicWebView" bundle:nil];
	if (!self) {
		return nil;
	}

	_URL = URL;
	_fallbackResourceName = fallbackResourceName;

	self.title = title;

	return self;
}


#pragma mark - API

- (void)setHasCloseButton:(BOOL)hasCloseButton {

	_hasCloseButton = hasCloseButton;

	if (hasCloseButton) {
		UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Close") style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
		self.navigationItem.leftBarButtonItem = cancelButtonItem;
	}

	else {
		self.navigationItem.leftBarButtonItem = nil;
	}
}


#pragma mark - Actions

- (void)cancel:(id)sender {

	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIViewController

- (void)loadView {

	CGRect appFrame = [UIScreen mainScreen].applicationFrame;
	appFrame.origin = CGPointZero;

	self.view = [[UIView alloc] initWithFrame:appFrame];
	self.webview = [[UIWebView alloc] initWithFrame:appFrame];
	self.webview.delegate = self;
	[self.view addSubview:self.webview];

	self.navigationItem.backBarButtonItem.tintColor = [app_delegate.theme colorForKey:@"navbarButtonColor"];

	_progressView = [VSProgressView new];
	[self.view insertSubview:_progressView aboveSubview:self.webview];
}


- (void)viewDidLoad {

	[super viewDidLoad];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:self.URL];
	[self.webview loadRequest:request];
	[self showProgressView];
}


- (void)viewDidLayoutSubviews {

	CGRect r = self.view.bounds;
	r.origin = CGPointZero;
	[self.webview qs_setFrameIfNotEqual:r];

	CGRect rProgress = CGRectZero;
	rProgress.origin.x = 0.0f;
	rProgress.size = [self.progressView sizeThatFits:CGSizeMake(rProgress.size.width, CGFLOAT_MAX)];
	self.progressView.frame = rProgress;
	self.progressView.center = self.webview.center;
}


#pragma mark - Progress View

- (void)showProgressView {

	self.progressView.hidden = NO;
	[self.progressView startAnimating];
}


- (void)removeProgressView {

	[self.progressView stopAnimating];

	[UIView animateWithDuration:0.25 animations:^{
		self.progressView.alpha = 0.0f;
	} completion:^(BOOL finished) {
		self.progressView.hidden = YES;
		[self.progressView removeFromSuperview];
		self.progressView = nil;
	}];
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {

	self.didShowInitialError = YES; /*Loaded first page. Not doing errors for subsequent frames.*/

	[self removeProgressView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {

	[self removeProgressView];

	if (self.didShowInitialError) {
		return;
	}

	self.didShowInitialError = YES;

	NSString *f = [[NSBundle mainBundle] pathForResource:@"WebViewError" ofType:@"html"];
	NSString *s = [[NSString alloc] initWithContentsOfFile:f encoding:NSUTF8StringEncoding error:nil];
	s = QSStringReplaceAll(s, @"[[errorMessage]]", [error localizedDescription]);

	[self.webview loadHTMLString:s baseURL:[NSURL URLWithString:@"about:blank"]];
}

@end
