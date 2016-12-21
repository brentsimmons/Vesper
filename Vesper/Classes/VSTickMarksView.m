//
//  VSTickMarksView.m
//  Vesper
//
//  Created by Brent Simmons on 8/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTickMarksView.h"


@interface VSTickMarksView ()

@property (nonatomic, weak) UISlider *slider;
@property (nonatomic, assign) NSUInteger numberOfTickMarks;
@property (nonatomic, assign) CGFloat tickMarkWidth;
@property (nonatomic, assign) CGFloat tickMarkInsetFudge;
@property (nonatomic, strong) UIColor *tickMarkColor;
@property (nonatomic, strong) NSArray *tickMarkOrigins;
@property (nonatomic, strong) UIColor *sliderTrackColor;
@property (nonatomic, assign) CGPoint sliderTrackOrigin;
@property (nonatomic, assign) CGSize sliderTrackSize;

@end


@implementation VSTickMarksView


#pragma mark - Init

- (instancetype)initWithSlider:(UISlider *)slider {

	CGRect r = CGRectZero;
	r.size = slider.frame.size;

	self = [self initWithFrame:r];
	if (self == nil)
		return nil;

	_slider = slider;
	_tickMarkWidth = [app_delegate.theme floatForKey:@"typographyScreen.sliderTickMarkWidth"];
	_tickMarkColor = [app_delegate.theme colorForKey:@"typographyScreen.sliderTickMarkColor"];
	_tickMarkInsetFudge = [app_delegate.theme floatForKey:@"typographyScreen.sliderTickMarkInsetFudge"];
	_sliderTrackColor = [app_delegate.theme colorForKey:@"typographyScreen.sliderTrackColor"];
	_sliderTrackOrigin = [app_delegate.theme pointForKey:@"typographyScreen.sliderTrackOrigin"];
	_sliderTrackSize = [app_delegate.theme sizeForKey:@"typographyScreen.sliderTrack"];

	self.contentMode = UIViewContentModeRedraw;
	
	[self refresh];
	
	return self;
}


#pragma mark - UIView


- (CGFloat)originXOfTickMarkAtIndex:(NSUInteger)ix {

	NSNumber *originX = self.tickMarkOrigins[ix];
	return [originX floatValue];
	CGRect rBounds = self.bounds;
	CGFloat width = CGRectGetWidth(rBounds);
	width -= (self.tickMarkInsetFudge * 2.0f);
	CGFloat interval = CGRectGetWidth(rBounds) / (self.numberOfTickMarks - 1);
#if __LP64__
	return floor(interval * ix) + self.tickMarkInsetFudge;
#else
	return floorf(interval * ix) + self.tickMarkInsetFudge;
#endif
}


- (CGRect)rectOfTickMarkAtIndex:(NSUInteger)ix {

	CGRect r = CGRectZero;
	CGRect rBounds = self.bounds;

	r.origin.x = [self originXOfTickMarkAtIndex:ix];
	r.origin.y = 0.0f;

	r.size.height = CGRectGetHeight(rBounds);
	r.size.width = self.tickMarkWidth;

	r.origin.x -= (CGRectGetWidth(r) / 2.0f);
#if __LP64__
	r.origin.x = floor(CGRectGetMinX(r));
#else
	r.origin.x = floorf(CGRectGetMinX(r));
#endif

	return r;
}


- (void)drawTickMarkAtIndex:(NSUInteger)ix {

	CGRect rTickMark = [self rectOfTickMarkAtIndex:ix];

	[self.tickMarkColor set];
	UIRectFill(rTickMark);
}


- (CGRect)rectOfTrack {

	CGRect r = CGRectZero;
	r.origin = self.sliderTrackOrigin;
	r.size = self.sliderTrackSize;

	return r;
}


- (void)drawRect:(CGRect)rect {

	NSUInteger i = 0;
	for (i = 0; i < self.numberOfTickMarks; i++) {
		[self drawTickMarkAtIndex:i];
	}

	CGRect rTrack = [self rectOfTrack];
	[self.sliderTrackColor set];
	UIRectFill(rTrack);
}


- (BOOL)isOpaque {
	return NO;
}


- (void)refresh {
	self.numberOfTickMarks = (NSUInteger)VSDefaultsFontLevelMaximum() + 1;
	self.tickMarkOrigins = (NSArray *)[app_delegate.theme objectForKey:[NSString stringWithFormat:@"typographyScreen.sliderTickMarkOrigins.%ld", (long)self.numberOfTickMarks - 1]];
	[self setNeedsDisplay];
}


@end
