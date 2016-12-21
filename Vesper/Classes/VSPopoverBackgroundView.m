//
//  VSPopoverBackgroundView.m
//  Vesper
//
//  Created by Brent Simmons on 5/14/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSPopoverBackgroundView.h"


static NSString *specifierPlusKey(NSString *specifier, NSString *key) {
	return [NSString stringWithFormat:@"%@.%@", specifier, key];
}


@interface VSPopoverBackgroundView ()

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, assign) CGFloat backgroundAlpha;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, weak) id<VSPopoverBackgroundViewDelegate> delegate;
@end


@implementation VSPopoverBackgroundView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame popoverSpecifier:(NSString *)popoverSpecifier delegate:(id<VSPopoverBackgroundViewDelegate>)delegate {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_delegate = delegate;
	_backgroundAlpha = [app_delegate.theme floatForKey:specifierPlusKey(popoverSpecifier, @"backgroundViewAlpha")];
	_backgroundColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"backgroundViewColor")];
	
	self.alpha = _backgroundAlpha;
	self.backgroundColor = _backgroundColor;
	
	_tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popoverBackgroundTap:)];
	[self addGestureRecognizer:_tapGestureRecognizer];
	
	return self;
}


#pragma mark - Actions

- (void)popoverBackgroundTap:(UITapGestureRecognizer *)gestureRecognizer {
	[self.delegate didTapPopoverBackgroundView:self];
}


- (void)restoreInitialAlpha {
	self.alpha = self.backgroundAlpha;
}


- (void)drawRect:(CGRect)rect {
	
	/*For some reason just setting the backgroundColor didn't actually do the trick. Very odd.*/
	
	[self.backgroundColor set];
	UIRectFill(rect);
}

@end
