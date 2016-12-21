//
//  VSBrowserBackgroundView.m
//  Vesper
//
//  Created by Brent Simmons on 4/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSBrowserBackgroundView.h"
#import "UIView+RSExtras.h"
#import "VSBrowserToolbarView.h"


@implementation VSBrowserBackgroundView

- (BOOL)isOpaque {
	return YES;
}


- (void)layoutSubviews {
	
	CGRect rBounds = self.bounds;
	
	UIView *toolbar = [self qs_firstSubviewOfClass:[VSBrowserToolbarView class]];
	CGRect rToolbar = rBounds;
	rToolbar.size.height = [app_delegate.theme floatForKey:@"browserToolbarHeight"];
	rToolbar.origin.y = CGRectGetMaxY(rBounds) - rToolbar.size.height;
	[toolbar qs_setFrameIfNotEqual:rToolbar];
	
	UIView *webview = [self qs_firstSubviewOfClass:[UIWebView class]];
	CGRect rWebview = rBounds;
	rWebview.origin.x = 0.0f;
	rWebview.origin.y = RSStatusBarHeight();
	rWebview.size.height = rBounds.size.height - CGRectGetMinY(rWebview);
	[webview qs_setFrameIfNotEqual:rWebview];
	
	if ([app_delegate.theme boolForKey:@"toolbarShadowVisible"]) {
		UIImageView *toolbarShadowView = (UIImageView *)[self qs_firstSubviewOfClass:[UIImageView class]];
		CGRect rShadow = CGRectZero;
		CGSize imageSize = toolbarShadowView.image.size;
		rShadow.origin.x = 0.0f;
		rShadow.origin.y = CGRectGetMinY(rToolbar) - imageSize.height;
		rShadow.size.height = imageSize.height;
		rShadow.size.width = rBounds.size.width;
		[toolbarShadowView qs_setFrameIfNotEqual:rShadow];
	}
	
	if (self.toolbarBorderView != nil) {
		
		CGRect rToolbarBorder = rToolbar;
		rToolbarBorder.size.height = [app_delegate.theme floatForKey:@"browserToolbarBorderWidth"];
		rToolbar.origin.y = CGRectGetMinY(rToolbar) - rToolbarBorder.size.height;
		[self.toolbarBorderView qs_setFrameIfNotEqual:rToolbarBorder];
	}
	
	[self.statusBarBackgroundView qs_setFrameIfNotEqual:RSStatusBarFrame()];
}

@end
