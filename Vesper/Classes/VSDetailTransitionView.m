//
//  VSDetailTransitionView.m
//  Vesper
//
//  Created by Brent Simmons on 4/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSDetailTransitionView.h"
#import "VSDetailTransitionNavbarView.h"


@interface VSDetailTransitionView ()

@property (nonatomic, strong, readwrite) VSNavbarView *navbar;
@property (nonatomic, strong, readwrite) UIView *tableContainerView;
@end


@implementation VSDetailTransitionView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor {
	
	self = [super initWithFrame:frame backgroundColor:backgroundColor];
	if (self == nil)
		return nil;
	
	[self setupNavbar];
	
	CGRect r = CGRectMake(0.0f, RSNavbarPlusStatusBarHeight(), frame.size.width, frame.size.height - RSNavbarPlusStatusBarHeight());
	_tableContainerView = [[UIView alloc] initWithFrame:r];
	_tableContainerView.backgroundColor = backgroundColor;
	_tableContainerView.contentMode = UIViewContentModeTop;
	[self addSubview:_tableContainerView];
	[self bringSubviewToFront:self.navbar];
	
	return self;
}


#pragma mark - Navbar

- (void)setupNavbar {
	
	self.navbar = [[VSDetailTransitionNavbarView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, RSNavbarPlusStatusBarHeight())];
	[self addSubview:self.navbar];
	[self.navbar setNeedsLayout];
	[self.navbar layoutIfNeeded];
	
}


#pragma mark - UIView

- (void)addSubview:(UIView *)view {
	
	[super addSubview:view];
	[self bringSubviewToFront:self.navbar];
}


@end
