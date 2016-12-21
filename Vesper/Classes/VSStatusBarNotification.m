//
//  VSStatusBarNotification.m
//  Vesper
//
//  Created by Brent Simmons on 5/3/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSStatusBarNotification.h"


@class VSStatusBarNotificationViewController;

@interface VSStatusBarNotification ()

@property (nonatomic) UIView *customView;
@property (nonatomic) UIWindow *notificationWindow;
@property (nonatomic) VSStatusBarNotificationViewController *viewController;

@end


@interface VSStatusBarNotificationViewController : UIViewController

- (instancetype)initWithView:(UIView *)view;
- (void)animateInNotificationView;
- (void)animateOutNotificationView:(QSVoidCompletionBlock)completion;

@end


@implementation VSStatusBarNotification


#pragma mark - Init

- (instancetype)initWithView:(UIView *)view {

	self = [super init];
	if (!self) {
		return nil;
	}

	_customView = view;
	_viewController = [[VSStatusBarNotificationViewController alloc] initWithView:view];

	_notificationWindow = [[UIWindow alloc] initWithFrame:[UIApplication sharedApplication].statusBarFrame];
	_notificationWindow.backgroundColor = [UIColor clearColor];
	_notificationWindow.opaque = NO;
	_notificationWindow.userInteractionEnabled = YES;
	_notificationWindow.windowLevel = UIWindowLevelStatusBar;
	_notificationWindow.rootViewController = self.viewController;
	_notificationWindow.hidden = YES;

	return self;
}


#pragma mark - API

- (void)show {

	self.notificationWindow.hidden = NO;
	self.notificationWindow.frame = [UIApplication sharedApplication].statusBarFrame;
	[self.viewController animateInNotificationView];
}


- (void)hide {

	[self.viewController animateOutNotificationView:^{

		self.notificationWindow.hidden = YES;
	}];
}


@end


@interface VSStatusBarNotificationViewController ()

@property (nonatomic) UIView *customView;

@end


@implementation VSStatusBarNotificationViewController

#pragma mark - Init

- (instancetype)initWithView:(UIView *)view {

	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}

	_customView = view;

	return self;
}


#pragma mark - UIViewController

- (void)loadView {

	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	self.view.opaque = NO;
	self.view.backgroundColor = [UIColor clearColor];

	[self.view addSubview:self.customView];

	self.customView.frame = [self rectOfCustomView];
}


#pragma mark - Layout

- (CGRect)rectOfCustomView {

	CGRect r = [UIApplication sharedApplication].statusBarFrame;
	r.origin = CGPointZero;
	return r;
}


#pragma mark - Animation

- (void)animateInNotificationView {

	CGRect r = [self rectOfCustomView];
	CGRect rStart = r;
	rStart.origin.y -= CGRectGetHeight(r);

	self.customView.frame = rStart;

	NSTimeInterval duration = [app_delegate.theme timeIntervalForKey:@"statusBarNotification.animateInDuration"];
	[UIView animateWithDuration:duration delay:0.0 options:0 animations:^{

		self.customView.frame = r;

	} completion:^(BOOL finished) {
		;
	}];
}


- (void)animateOutNotificationView:(QSVoidCompletionBlock)completion {

	CGRect r = [self rectOfCustomView];
	CGRect rEnd = r;
	rEnd.origin.y -= CGRectGetHeight(r);

	NSTimeInterval duration = [app_delegate.theme timeIntervalForKey:@"statusBarNotification.animateInDuration"];
	[UIView animateWithDuration:duration delay:0.0 options:0 animations:^{

		self.customView.frame = rEnd;

	} completion:^(BOOL finished) {

		QSCallCompletionBlock(completion);
	}];
}


@end

