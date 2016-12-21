//
//  VSProgressView.m
//  Vesper
//
//  Created by Brent Simmons on 4/30/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSProgressView.h"
#import "VSProgressCircleView.h"


@interface VSProgressView ()

@property (nonatomic) NSArray *circleViews;
@property (nonatomic, assign) CGFloat maxCircleWidth;
@property (nonatomic, assign) CGFloat minCircleScale;
@property (nonatomic, assign) NSUInteger numberOfCircles;
@property (nonatomic, assign) CGFloat spaceBetweenCircles;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) NSTimeInterval timeToMaxWidth;
@property (nonatomic, assign) NSTimeInterval timeToMinWidth;
@property (nonatomic, assign) NSTimeInterval timeToStaggerCircles;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) NSTimeInterval fadeInDuration;
@property (nonatomic, assign) NSTimeInterval fadeOutDuration;

@end


@implementation VSProgressView


#pragma mark - Init

- (instancetype)init {

	self = [super initWithFrame:CGRectZero];
	if (!self) {
		return nil;
	}

	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	self.alpha = 0.0;

	_maxCircleWidth = [app_delegate.theme floatForKey:@"circleProgress.maxWidth"];
	_minCircleScale = [app_delegate.theme floatForKey:@"circleProgress.minScale"];
	_numberOfCircles = (NSUInteger)[app_delegate.theme integerForKey:@"circleProgress.numberOfCircles"];
	_spaceBetweenCircles = [app_delegate.theme floatForKey:@"circleProgress.spaceBetweenCircles"];
	_timeToMaxWidth = [app_delegate.theme timeIntervalForKey:@"circleProgress.timeToMaxWidth"];
	_timeToMinWidth = [app_delegate.theme timeIntervalForKey:@"circleProgress.timeToMinWidth"];
	_timeToStaggerCircles = [app_delegate.theme timeIntervalForKey:@"circleProgress.timeToStaggerCircles"];
	_fadeInDuration = [app_delegate.theme timeIntervalForKey:@"circleProgress.fadeInDuration"];
	_fadeOutDuration = [app_delegate.theme timeIntervalForKey:@"circleProgress.fadeOutDuration"];

	[self createCircleViews];

	return self;
}


#pragma mark - Circles

- (void)createCircleViews {

	NSMutableArray *circles = [NSMutableArray new];

	NSUInteger i = 0;
	
	for (i = 0; i < self.numberOfCircles; i++) {

		CGRect r = [self frameOfCircleAtIndex:i];
		VSProgressCircleView *oneCircle = [[VSProgressCircleView alloc] initWithFrame:r circleWidth:self.maxCircleWidth];
		[circles addObject:oneCircle];
		[self addSubview:oneCircle];
		oneCircle.transform = [self scaleDownTransform];
	}

	self.circleViews = [circles copy];
}


#pragma mark - Animation

- (CGAffineTransform)scaleDownTransform {

	return CGAffineTransformMakeScale(self.minCircleScale, self.minCircleScale);
}


typedef void (^VSProgressAnimationCompletionCallback)(NSUInteger indexOfCircle);

- (void)animateCircles {

	NSUInteger i = 0;

	__weak VSProgressView *weakself = self;

	for (i = 0; i < self.numberOfCircles; i++) {

		if (!self.isAnimating) {
			return;
		}

		[weakself animateCircleAtIndex:i completionCallback:^(NSUInteger indexOfCircle) {

			if (indexOfCircle == self.numberOfCircles - 1) {

				if (weakself.isAnimating) {
					[self performSelectorOnMainThread:@selector(animateCircles) withObject:nil waitUntilDone:NO];
				}
			}
		}];
	}
}


- (void)animateCircleAtIndex:(NSUInteger)ix completionCallback:(VSProgressAnimationCompletionCallback)callback {

	VSProgressCircleView *circle = self.circleViews[ix];

	__weak VSProgressView *weakself = self;

	[UIView animateWithDuration:self.timeToMaxWidth delay:self.timeToStaggerCircles * ix options:0 animations:^{

		circle.transform = CGAffineTransformIdentity;

	} completion:^(BOOL finished) {

		if (!weakself.isAnimating || !weakself.superview) {
			return;
		}

		[UIView animateWithDuration:weakself.timeToMinWidth delay:0.0 options:0 animations:^{

			circle.transform = [weakself scaleDownTransform];

		} completion:^(BOOL finished2) {

			callback(ix);

		}];
	}];
}

#pragma mark - API

- (void)startAnimating {

	self.isAnimating = YES;

	__weak VSProgressView *weakself = self;
	[UIView animateWithDuration:self.fadeInDuration animations:^{
		weakself.alpha = 1.0;
	}];

	[self animateCircles];
}


- (void)stopAnimating {
	
	self.isAnimating = NO;
}


#pragma mark - Layout

static const CGFloat marginLeft = 4.0;
static const CGFloat marginRight = 4.0;
static const CGFloat marginTop = 4.0;
static const CGFloat marginBottom = 4.0;

- (CGSize)sizeThatFits:(CGSize)constrainingSize {

	/*constrainingSize is ignored*/

	CGFloat height = marginTop + self.maxCircleWidth + marginBottom;
	CGFloat width = marginLeft + (self.numberOfCircles * self.maxCircleWidth) + ((self.numberOfCircles - 1) * self.spaceBetweenCircles) + marginRight;

	return CGSizeMake(width, height);
}


- (CGRect)frameOfCircleAtIndex:(NSUInteger)ix {

	CGPoint centerPoint = [self centerPointForCircleAtIndex:ix];
	CGRect r = CGRectZero;

	r.size.height = self.maxCircleWidth + 2.0f;
	r.size.width = self.maxCircleWidth + 2.0f;

	r.origin.x = centerPoint.x - (self.maxCircleWidth / 2.0f);
	r.origin.y = centerPoint.y - (self.maxCircleWidth / 2.0f);

	return r;
}


- (CGPoint)centerPointForCircleAtIndex:(NSUInteger)ix {

	CGPoint pt = CGPointZero;

	pt.y = CGRectGetHeight(self.bounds) / 2.0f;

	pt.x = marginLeft + ((ix + 1) * self.maxCircleWidth);
	pt.x += (ix * self.spaceBetweenCircles);
	pt.x -= (self.maxCircleWidth / 2.0);

	return pt;
}


- (void)layoutSubviews {

	for (NSUInteger i = 0; i < self.numberOfCircles; i++) {

		VSProgressCircleView *oneCircle = self.circleViews[i];
		CGPoint oneCenterPoint = [self centerPointForCircleAtIndex:i];
		oneCircle.center = oneCenterPoint;
	}
}


@end
