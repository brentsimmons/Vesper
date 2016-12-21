//
//  UIView+RSExtras.m
//  Vesper
//
//  Created by Brent Simmons on 12/6/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "UIView+RSExtras.h"


BOOL RSIsRetinaScreen(void) {
	
	static BOOL isRetina = NO;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		isRetina = [UIScreen mainScreen].scale > 1.1f;
	});
	
	return isRetina;
}


CGFloat RSStatusBarHeight(void) {
	
	return RSStatusBarFrame().size.height;
}


CGFloat RSNavbarPlusStatusBarHeight(void) {
	
	return VSNavbarHeight + VSNormalStatusBarHeight();
}


CGRect RSStatusBarFrame(void) {
	return [UIApplication sharedApplication].statusBarFrame;
}


CGRect RSNormalStatusBarFrame(void) {
	
	CGRect r = RSStatusBarFrame();
	r.size.height = VSNormalStatusBarHeight();
	return r;
}


CGFloat RSContentViewHeight(void) {
	
	CGRect r = [UIScreen mainScreen].bounds;
	CGRect rStatusBar = RSStatusBarFrame();
	CGFloat extraStatusBarHeight = CGRectGetHeight(rStatusBar) - VSNormalStatusBarHeight();
	r.size.height -= extraStatusBarHeight;
	
	return CGRectGetHeight(r);
}


CGRect RSRectForMainView(void) {
	
	CGRect r = RSFullViewRect();
	r.origin.y = RSNavbarPlusStatusBarHeight();
	r.size.height = CGRectGetHeight(r) - CGRectGetMinY(r);
	
	return r;
}


static CGFloat RSScreenWidth(void) {
	return [UIScreen mainScreen].bounds.size.width;
}


CGRect RSNavbarRect(void) {
	
	CGRect r = CGRectZero;
	r.size.width = RSScreenWidth();
	r.size.height = RSNavbarPlusStatusBarHeight();
	
	return r;
}


CGRect RSFullViewRect(void) {
	
	CGRect r = [UIScreen mainScreen].bounds;
	r.size.height = RSContentViewHeight();
	return r;
}


@implementation UIView (RSExtras)

- (void)rs_addConstraintsWithThemeKey:(NSString *)themeKey viewName:(NSString *)viewName view:(UIView *)view {
	
	NSString *horizontalKey = [NSString stringWithFormat:@"%@Horizontal", themeKey];
	NSString *layoutString = [app_delegate.theme stringForKey:horizontalKey];
	NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:layoutString options:0 metrics:nil views:@{viewName : view}];
	[self addConstraints:constraints];
	
	NSString *verticalKey = [NSString stringWithFormat:@"%@Vertical", themeKey];
	layoutString = [app_delegate.theme stringForKey:verticalKey];
	constraints = [NSLayoutConstraint constraintsWithVisualFormat:layoutString options:0 metrics:nil views:@{viewName : view}];
	[self addConstraints:constraints];
}


+ (UIViewAnimationOptions)rs_animationOptionsWithAnimationCurve:(UIViewAnimationCurve)animationCurve {
	
	UIViewAnimationOptions animationOptions = 0;
	
	switch (animationCurve) {
		case UIViewAnimationCurveEaseInOut:
			animationOptions = UIViewAnimationOptionCurveEaseInOut;
			break;
		case UIViewAnimationCurveEaseIn:
			animationOptions = UIViewAnimationOptionCurveEaseIn;
			break;
		case UIViewAnimationCurveEaseOut:
			animationOptions = UIViewAnimationOptionCurveEaseOut;
			break;
		case UIViewAnimationCurveLinear:
			animationOptions = UIViewAnimationOptionCurveLinear;
			break;
		default:
			break;
	}
	
	return animationOptions;
}


- (UIImage *)rs_snapshotImage:(BOOL)clearBackground {
	
	BOOL originalOpaque = self.isOpaque;
	UIColor *originalBackgroundColor = self.backgroundColor;
	
	if (clearBackground) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
	}
	
	UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, [UIScreen mainScreen].scale);
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	if (clearBackground) {
		self.opaque = originalOpaque;
		self.backgroundColor = originalBackgroundColor;
	}
	
	return image;
}


- (UIImageView *)rs_snapshotImageView:(BOOL)clearBackground {
	
	UIImage *image = [self rs_snapshotImage:clearBackground];
	if (image == nil)
		return nil;
	
	return [[UIImageView alloc] initWithImage:image];
}


+ (void)rs_animateWithAnimationSpecifier:(VSAnimationSpecifier *)animationSpecifier animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
	
	[self animateWithDuration:animationSpecifier.duration delay:animationSpecifier.delay options:animationSpecifier.curve animations:animations completion:completion];
}


@end

