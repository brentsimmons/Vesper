//
//  VSProgressCircleView.m
//  Vesper
//
//  Created by Brent Simmons on 4/30/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSProgressCircleView.h"


@interface VSProgressCircleView ()

@property (nonatomic) UIColor *color;
@property (nonatomic, assign) CGFloat circleWidth;
@property (nonatomic, assign) CGRect circleRect;
@property (nonatomic) UIBezierPath *bezierPath;

@end


@implementation VSProgressCircleView


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame circleWidth:(CGFloat)circleWidth {

	self = [super initWithFrame:frame];
	if (!self) {
		return nil;
	}

	self.contentMode = UIViewContentModeScaleAspectFit;
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];

	_circleWidth = circleWidth;
	_color = [app_delegate.theme colorForKey:@"circleProgress.color"];

	_circleRect = CGRectMake(0.0, 0.0, circleWidth, circleWidth);
	_circleRect.origin.x = (CGRectGetWidth(frame) - circleWidth) / 2.0f;
	_circleRect.origin.y = (CGRectGetHeight(frame) - circleWidth) / 2.0f;

	return self;
}


#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {

	UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:self.circleRect];
	[self.color set];
	[path fill];
}


@end
