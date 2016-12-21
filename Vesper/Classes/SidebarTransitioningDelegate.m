//
//  SidebarTransitioningDelegate.m
//  Vesper
//
//  Created by Brent Simmons on 8/8/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "SidebarTransitioningDelegate.h"
#import "SidebarPresentationController.h"
#import "SidebarAnimationController.h"


@implementation SidebarTransitioningDelegate


#pragma mark - UIViewControllerTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {

	return [[SidebarPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}


- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {

	SidebarAnimationController *animationController = [SidebarAnimationController new];
	animationController.presenting = YES;

	return animationController;
}


- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {

	SidebarAnimationController *animationController = [SidebarAnimationController new];
	animationController.presenting = NO;

	return animationController;
}

//- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id <UIViewControllerAnimatedTransitioning>)animator;
//
//- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator;


@end
