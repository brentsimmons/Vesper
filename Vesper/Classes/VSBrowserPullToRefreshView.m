//
//  VSBrowserPullToRefreshView.m
//  Vesper
//
//  Created by Brent Simmons on 5/19/13.
//  Copyright 2013 Q Branch, LLC. All rights reserved.
//

#import "VSBrowserPullToRefreshView.h"


@interface VSBrowserPullToRefreshView ()

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIImage *arrowImage;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIImage *refreshImage;
@property (nonatomic, strong) UIImageView *refreshImageView;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *textTriggerColor;
@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic, strong) UIColor *refreshTriggerColor;
@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, strong) UIImageView *spinnerView;
@property (nonatomic, assign) BOOL didInitialLoadingIndication;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) UIView *borderView;
@end


@implementation VSBrowserPullToRefreshView


static UIEdgeInsets VSBrowserEdgeInsetsWithTopOffset(CGFloat top) {
	return UIEdgeInsetsMake(top + 0.0f, 0.0f, VSNavbarHeight, 0.0f);
}


static UIEdgeInsets VSBrowserNormalEdgeInsets(void) {
	return VSBrowserEdgeInsetsWithTopOffset(0.0f);
}


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	self.clipsToBounds = NO;
	_height = frame.size.height;
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.backgroundColor = [UIColor clearColor];//[app_delegate.theme colorForKey:@"browserPullToRefresh.backgroundColor"];
	
	_textColor = [app_delegate.theme colorForKey:@"browserPullToRefresh.fontColor"];
	_textTriggerColor = [app_delegate.theme colorForKey:@"browserPullToRefresh.triggerFontColor"];
	_arrowColor = [app_delegate.theme colorForKey:@"browserPullToRefresh.arrowColor"];
	_refreshTriggerColor = [app_delegate.theme colorForKey:@"browserPullToRefresh.refreshTriggerColor"];
	_textFont = [app_delegate.theme fontForKey:@"browserPullToRefresh.font"];
	
	_arrowImage = [UIImage qs_imageNamed:@"webview-downarrow" tintedWithColor:_arrowColor];
	_refreshImage = [UIImage qs_imageNamed:@"refresh" tintedWithColor:_refreshTriggerColor];
	
	_statusLabel = [[UILabel alloc] initWithFrame:[[self class] rectOfStatusLabel]];
	_statusLabel.autoresizingMask = UIViewAutoresizingNone;
	_statusLabel.font = _textFont;
	_statusLabel.textColor = _textColor;
	_statusLabel.backgroundColor = [UIColor clearColor];
	_statusLabel.textAlignment = NSTextAlignmentLeft;
	_statusLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
	[self addSubview:_statusLabel];
	
	_arrowImageView = [[UIImageView alloc] initWithImage:_arrowImage];
	_arrowImageView.frame = [[self class] rectOfArrow];
	_arrowImageView.contentMode = UIViewContentModeCenter;
	[self addSubview:_arrowImageView];
	
	_refreshImageView = [[UIImageView alloc] initWithImage:_refreshImage];
	_refreshImageView.frame = [[self class] rectOfRefreshView];
	_refreshImageView.contentMode = UIViewContentModeCenter;
	[self addSubview:_refreshImageView];
	_refreshImageView.hidden = YES;
	
	_spinnerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spin0"]];
	_spinnerView.animationImages = [[self class] spinnerImages];
	_spinnerView.animationDuration = [app_delegate.theme floatForKey:@"browserPullToRefresh.spinnerAnimationDuration"];
	_spinnerView.frame = [[self class] rectOfSpinnerView];
	
	_spinnerView.hidden = YES;
	[self addSubview:_spinnerView];
	
	self.pullToRefreshState = VSPullToRefreshNormal;
	
	CGFloat borderViewHeight = 1.0f;
	CGFloat borderViewOriginY = CGRectGetHeight(frame) - 1.0f;
	if (RSIsRetinaScreen()) {
		borderViewHeight = 0.5f;
		borderViewOriginY = CGRectGetHeight(frame) - 0.5f;
	}
	
	CGRect rBorder = CGRectMake(0.0f, borderViewOriginY, CGRectGetWidth(frame), borderViewHeight);
	_borderView = [[UIView alloc] initWithFrame:rBorder];
	_borderView.backgroundColor = [app_delegate.theme colorForKey:@"browserStatusBorderColor"];
	//	_borderView.backgroundColor = [UIColor redColor];
	[self addSubview:_borderView];
	[self bringSubviewToFront:_borderView];
	
	[self addObserver:self forKeyPath:@"url" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"pullToRefreshState" options:0 context:NULL];
	
	[self updateStatusLabel];
	[self layoutBorder];
	
	return self;
	
}


#pragma mark - Dealloc

- (void)dealloc {
	_delegate = nil;
	[self removeObserver:self forKeyPath:@"url"];
	[self removeObserver:self forKeyPath:@"pullToRefreshState"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"url"])
		[self updateStatusLabel];
	
	else if ([keyPath isEqualToString:@"pullToRefreshState"]) {
		[self updateStatusLabel];
		[self updateArrowAndSpinner];
	}
	
}


#pragma mark - Arrow

- (UIScrollView *)scrollView {
	return (UIScrollView *)(self.superview);
}


- (void)animateToContentInset:(UIEdgeInsets)contentInset {
	
	NSTimeInterval contentInsetAnimationDuration = 0.25;
	
	[self.delegate refreshView:self willAnimateToContentInset:contentInset];
	
	[UIView animateWithDuration:contentInsetAnimationDuration animations:^{
		self.scrollView.contentInset = contentInset;
		self.scrollView.scrollIndicatorInsets = contentInset;
	} completion:^(BOOL finished) {
		
		[self.delegate refreshView:self didAnimateToContentInset:contentInset];
	}];
}


- (void)updateArrowAndSpinner {
	
	CGFloat animationDuration = [app_delegate.theme floatForKey:@"browserPullToRefresh.refreshFadeDuration"];
	
	switch (self.pullToRefreshState) {
			
		case VSPullToRefreshNormal: {
			
			self.arrowImageView.hidden = NO;
			self.arrowImageView.alpha = 0.0f;
			self.spinnerView.hidden = YES;
			
			[UIView animateWithDuration:animationDuration animations:^{
				self.arrowImageView.alpha = 1.0f;
				self.refreshImageView.alpha = 0.0f;
			} completion:^(BOOL finished) {
				self.refreshImageView.hidden = YES;
				self.refreshImageView.alpha = 1.0f;
			}];
			
			[self animateToContentInset:VSBrowserNormalEdgeInsets()];
			[self.spinnerView stopAnimating];
		}
			break;
			
		case VSPullToRefreshPulling: {
			
			self.refreshImageView.alpha = 0.0f;
			self.refreshImageView.hidden = NO;
			self.spinnerView.hidden = YES;
			
			[UIView animateWithDuration:animationDuration animations:^{
				self.arrowImageView.alpha = 0.0f;
				self.refreshImageView.alpha = 1.0f;
			} completion:^(BOOL finished) {
				self.arrowImageView.hidden = YES;
				self.arrowImageView.alpha = 1.0f;
			}];
			
			[self.spinnerView stopAnimating];
		}
			break;
			
		case VSPullToRefreshLoading: {
			
			self.arrowImageView.hidden = YES;
			self.refreshImageView.hidden = YES;
			self.spinnerView.hidden = NO;
			if (!self.spinnerView.isAnimating)
				[self.spinnerView startAnimating];
			
			[self animateToContentInset:VSBrowserEdgeInsetsWithTopOffset(self.height)];
		}
			break;
			
		default:
			break;
	}
}


#pragma mark - Status Label

static NSString *stringByStrippingTrailingSlash(NSString *s) {
	
	if ([s hasSuffix:@"/"]) {
		return [s substringToIndex:[s length] - 1];
	}
	return s;
}


- (NSString *)urlStringForDisplay {
	
	NSString *urlString = [self.url qs_absoluteStringWithHTTPOrHTTPSPrefixRemoved];
	urlString = stringByStrippingTrailingSlash(urlString);
	return urlString;
}


- (void)updateStatusLabel {
	
	NSString *urlString = nil;
	if (self.url != nil)
		urlString = [self urlStringForDisplay];
	if (urlString == nil)
		urlString = @"";
	
	NSString *statusText = nil;
	
	if (self.pullToRefreshState == VSPullToRefreshLoading) {
		NSString *loadingText = NSLocalizedString(@"Loading", @"Loading");
		statusText = [loadingText stringByAppendingString:@" "];
		statusText = [statusText stringByAppendingString:urlString];
	}
	else
		statusText = urlString;
	
	self.statusLabel.text = statusText;
	
	if (self.pullToRefreshState == VSPullToRefreshPulling)
		self.statusLabel.textColor = self.textTriggerColor;
	else
		self.statusLabel.textColor = self.textColor;
}


#pragma mark - Spinner

+ (NSArray *)spinnerImages {
	
	NSMutableArray *spinnerImages = [NSMutableArray new];
	NSUInteger i = 0;
	static const NSUInteger kNumberOfSpinnerImages = 12;
	
	for (i = 0; i < kNumberOfSpinnerImages; i++) {
		NSString *oneImageName = [NSString stringWithFormat:@"spin%ld", (long)i];
		UIImage *oneImage = [UIImage imageNamed:oneImageName];
		[spinnerImages addObject:oneImage];
	}
	
	return [spinnerImages copy];
}


#pragma mark - Layout

+ (CGRect)rectOfStatusLabel {
	
	CGRect r = CGRectZero;
	r.origin = [app_delegate.theme pointForKey:@"browserPullToRefresh.textOrigin"];
	r.size.width = [app_delegate.theme floatForKey:@"browserPullToRefresh.textWidth"];
	r.size.height = [app_delegate.theme floatForKey:@"browserPullToRefresh.fontSize"] + 4.0f;
	
	return r;
}


+ (CGRect)rectWithKey:(NSString *)key imageName:(NSString *)imageName {
	
	CGRect r = CGRectZero;
	r.origin = [app_delegate.theme pointForKey:key];
	UIImage *image = [UIImage imageNamed:imageName];
	r.size = image.size;
	
	return r;
}


+ (CGRect)rectOfArrow {
	return [self rectWithKey:@"browserPullToRefresh.arrowOrigin" imageName:@"webview-downarrow"];
}


+ (CGRect)rectOfSpinnerView {
	return [self rectWithKey:@"browserPullToRefresh.spinnerOrigin" imageName:@"spin0"];
}


+ (CGRect)rectOfRefreshView {
	return [self rectWithKey:@"browserPullToRefresh.refreshOrigin" imageName:@"refresh"];
}



#pragma mark - API

- (void)refreshScrollViewDidScroll:(UIScrollView *)scrollView {
	
	[self layoutSubviews];
	
	if (self.pullToRefreshState == VSPullToRefreshLoading) {
		
		CGFloat offset = MAX(scrollView.contentOffset.y * -1, 0);
		offset = MIN(offset, self.height);
		scrollView.contentInset = VSBrowserEdgeInsetsWithTopOffset(offset);
		scrollView.scrollIndicatorInsets = scrollView.contentInset;
	}
	
	else if (scrollView.isDragging) {
		
		BOOL loading = [self.delegate refreshViewDataSourceIsLoading:self];
		
		if (self.pullToRefreshState == VSPullToRefreshPulling && scrollView.contentOffset.y > -(self.height) && scrollView.contentOffset.y < 0.0f && !loading)
			self.pullToRefreshState = VSPullToRefreshNormal;
		else if (self.pullToRefreshState == VSPullToRefreshNormal && scrollView.contentOffset.y < -(self.height) && !loading)
			self.pullToRefreshState = VSPullToRefreshPulling;
		
		if (scrollView.contentInset.top != 0) {
			scrollView.contentInset = VSBrowserNormalEdgeInsets();
			scrollView.scrollIndicatorInsets = scrollView.contentInset;
		}
	}
	
	[self layoutSubviews];
}


- (void)refreshScrollViewDidEndDragging:(UIScrollView *)scrollView {
	
	[self layoutSubviews];
	BOOL loading = [self.delegate refreshViewDataSourceIsLoading:self];
	
	if (scrollView.contentOffset.y <= - (self.height) && !loading) {
		
		[self.delegate refreshViewDidTriggerRefresh:self];
		if (self.pullToRefreshState != VSPullToRefreshLoading)
			self.pullToRefreshState = VSPullToRefreshLoading;
	}
	[self layoutSubviews];
}


#pragma mark - Border


- (void)layoutBorder {
	
	CGFloat borderViewHeight = 1.0f;
	CGFloat borderViewOriginY = CGRectGetHeight(self.bounds) - borderViewHeight;// + 5.0f;
	if (RSIsRetinaScreen()) {
		borderViewHeight = 0.5f;
		borderViewOriginY = CGRectGetHeight(self.bounds) - 0.5f;
	}
	
	CGRect rBorder = CGRectMake(0.0f, borderViewOriginY, CGRectGetWidth(self.bounds), borderViewHeight);
	
	if (!CGRectEqualToRect(rBorder, self.borderView.frame)) {
		[self.borderView qs_setFrameIfNotEqual:rBorder];
		[self.borderView setNeedsDisplay];
	}
	
	//	CGPoint contentOffset = self.scrollView.contentOffset;
	//	UIEdgeInsets contentInset = self.scrollView.contentInset;
	
	//	if (contentOffset.y > 0.01f)
	//		rBorder.origin.y += contentOffset.y;
	
	//	NSLog(@"contentOffset: %f contentInset: %f", contentOffset.y, contentInset.top);
	//	NSLog(@"rBorder %f", rBorder.origin.y);
	
	[self.scrollView bringSubviewToFront:self];
	
	//
	//	contentOffset.y += self.scrollView.contentInset.top;
	//	rBorder.origin.y += contentOffset.y;
	//
	//	dispatch_async(dispatch_get_main_queue(), ^{
	//		[self.borderView qs_setFrameIfNotEqual:rBorder];
	//		[self.borderView setNeedsDisplay];
	//	});
}


#pragma mark - UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	[self layoutBorder];
	
}


- (BOOL)isOpaque {
	return NO;
}


@end
