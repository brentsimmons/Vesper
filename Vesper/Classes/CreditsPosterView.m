//
//  CreditsPosterView.m
//  Vesper
//
//  Created by Brent Simmons on 7/23/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "CreditsPosterView.h"


@interface CreditsPosterView ()

@property (nonatomic) UIImageView *taglineImageView;
@property (nonatomic) UIImageView *pillImageView;
@property (nonatomic) UIImageView *titleImageView;
@property (nonatomic) UIImageView *creditsImageView;
@property (nonatomic) CGSize pillImageSize;

@end


@implementation CreditsPosterView

- (id)initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self) {
		return nil;
	}

	_taglineImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"credits-remember"]];
	[self addSubview:_taglineImageView];

	_titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"credits-vesper"]];
	[self addSubview:_titleImageView];

	_creditsImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"credits-names"]];
	[self addSubview:_creditsImageView];

	UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0.0f, 50.0f, 0.0f, 0.0f);
	UIImage *pillImage = [UIImage imageNamed:@"credits-bubble"];
	_pillImageSize = pillImage.size;
	pillImage = [pillImage resizableImageWithCapInsets:edgeInsets resizingMode:UIImageResizingModeStretch];
	_pillImageView = [[UIImageView alloc] initWithImage:pillImage];
	[self addSubview:_pillImageView];

	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];

	return self;
}


#pragma mark - Layout

- (CGRect)rectOfTagline {

	static const CGFloat taglineTop = 27;

	CGRect r = CGRectZero;
	r.origin.y = taglineTop;
	r.size = self.taglineImageView.frame.size;

	r = CGRectCenteredHorizontallyInRect(r, self.bounds);
	r = CGRectIntegral(r);
	r.size = self.taglineImageView.image.size;

	return r;
}


- (CGRect)rectOfPill {

	CGFloat y = 0;
	CGFloat x = 0;

	CGRect rBounds = self.bounds;

	if (CGRectGetHeight(rBounds) == 480.0f) {
		y = 190; /*3.5" iPhone*/
		x = 76.0f;
	}

	else if (CGRectGetHeight(rBounds) == 568.0f) {
		y = 250; /*4" iPhone*/
		x = 76.0f;
	}

	else {

		/*Put it a little past the vertical center point.*/

		y = CGRectGetHeight(rBounds) / 2.0f;
		y += 20.0f;
		y -= (self.pillImageSize.height / 2.0f);

		/*Left whitespace is one-fourth width of the screen.*/

		CGFloat oneFourth = CGRectGetWidth(rBounds) / 4.0f;
		x = oneFourth;
	}

	CGFloat height = self.pillImageSize.height;
	CGFloat width = (CGRectGetWidth(rBounds) - x) + 2.0f; /*slop to deal with potential half-pixel on right*/

	CGRect r = CGRectMake(x, y, width, height);
	r = CGRectIntegral(r);
	r.size.height = self.pillImageSize.height;

	return r;
}


- (CGRect)rectOfTitle {

	CGFloat y = 0;
	CGRect rBounds = self.bounds;

	if (CGRectGetHeight(rBounds) == 480.0f) {
		y = 298; /*3.5" iPhone*/
	}

	else if (CGRectGetHeight(rBounds) == 568.0f) {
		y = 384; /*4" iPhone*/
	}

	else {

		/*Center vertically between pill and credits. A little higher.*/

		CGRect rPill = [self rectOfPill];
		CGRect rCredits = [self rectOfCredits];

		CGFloat deltaY = CGRectGetMinY(rCredits) - CGRectGetMaxY(rPill);
		CGFloat centerY = CGRectGetMinY(rCredits) - (deltaY / 2.0f);

		y = centerY - (self.titleImageView.image.size.height / 2.0f);
		y -= 4.0f; /*A little higher.*/
	}


	CGRect r = CGRectZero;
	r.origin.y = y;
	r.size = self.titleImageView.image.size;
	r = CGRectCenteredHorizontallyInRect(r, self.bounds);
	r = CGRectIntegral(r);
	r.size = self.titleImageView.image.size;

	return r;
}


- (CGRect)rectOfCredits {

	static const CGFloat creditsBottom = 40;

	CGSize imageSize = self.creditsImageView.image.size;
	CGRect r = CGRectZero;
	r.size = imageSize;
	r.origin.y = (CGRectGetMaxY(self.bounds) - creditsBottom) - imageSize.height;

	r = CGRectCenteredHorizontallyInRect(r, self.bounds);
	r = CGRectIntegral(r);
	r.size = imageSize;

	return r;
}


#pragma mark - UIView

- (void)layoutSubviews {

	[self.taglineImageView qs_setFrameIfNotEqual:[self rectOfTagline]];
	[self.titleImageView qs_setFrameIfNotEqual:[self rectOfTitle]];
	[self.pillImageView qs_setFrameIfNotEqual:[self rectOfPill]];
	[self.creditsImageView qs_setFrameIfNotEqual:[self rectOfCredits]];
}


@end

