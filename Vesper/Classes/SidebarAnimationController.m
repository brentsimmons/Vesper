//
//  SidebarAnimationController.m
//  Vesper
//
//  Created by Brent Simmons on 8/8/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "SidebarAnimationController.h"


@implementation SidebarAnimationController


#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {

	return [app_delegate.theme timeIntervalForKey:@"sidebar.animationDuration"];
}


- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {

	if ([[app_delegate.theme stringForKey:@"sidebar.animationStyle"] isEqualToString:@"fade"]) {

		[self animateFadeTransition:(id<UIViewControllerContextTransitioning>)transitionContext];
		return;
	}

	UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

	UIViewController *sidebarViewController = nil;
	UIView *sidebarView = nil;

	if (self.presenting) {

		sidebarViewController = toVC;
		sidebarView = sidebarViewController.view;
		[transitionContext.containerView addSubview:sidebarView];
	}
	else {

		sidebarViewController = fromVC;
		sidebarView = sidebarViewController.view;
	}

	sidebarView.frame = [transitionContext finalFrameForViewController:sidebarViewController];

	CGAffineTransform presentedTransform = CGAffineTransformIdentity;
	CGAffineTransform dismissedTransform = CGAffineTransformMakeTranslation(-CGRectGetWidth(sidebarView.frame), 0.0);

	sidebarView.transform = self.presenting ? dismissedTransform : presentedTransform;

	CGFloat damping = [app_delegate.theme floatForKey:@"sidebar.animationSpringDampingRatio"];
	CGFloat velocity = [app_delegate.theme floatForKey:@"sidebar.animationSpringVelocity"];
	[UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:damping initialSpringVelocity:velocity options:UIViewAnimationOptionBeginFromCurrentState animations:^{

		if ([[app_delegate.theme stringForKey:@"sidebar.animationStyle"] isEqualToString:@"fade"]) {
			sidebarView.alpha = self.presenting ? 1.0f : 0.0f;
		}
		else {
			sidebarView.transform = self.presenting ? presentedTransform : dismissedTransform;
		}

	} completion:^(BOOL finished) {

		if (!self.presenting) {
			[sidebarView removeFromSuperview];
		}

		sidebarView.transform = CGAffineTransformIdentity;
		[transitionContext completeTransition:YES];
	}];
}


- (void)animateFadeTransition:(id<UIViewControllerContextTransitioning>)transitionContext {

	UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

	UIViewController *sidebarViewController = nil;
	UIView *sidebarView = nil;

	if (self.presenting) {

		sidebarViewController = toVC;
		sidebarView = sidebarViewController.view;
		[transitionContext.containerView addSubview:sidebarView];
	}
	else {

		sidebarViewController = fromVC;
		sidebarView = sidebarViewController.view;
	}

	sidebarView.frame = [transitionContext finalFrameForViewController:sidebarViewController];

	if (self.presenting) {
		sidebarView.alpha = 0.0f;
	}
	else {
		sidebarView.alpha = 1.0f;
	}

	[UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{

		sidebarView.alpha = self.presenting ? 1.0f : 0.0f;
		
	} completion:^(BOOL finished) {

		if (!self.presenting) {
			[sidebarView removeFromSuperview];
		}

		sidebarView.transform = CGAffineTransformIdentity;
		[transitionContext completeTransition:YES];

	}];
}


@end
