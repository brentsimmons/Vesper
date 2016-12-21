//
//  VSCheckmarkAccessoryView.m
//  Vesper
//
//  Created by Brent Simmons on 8/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSCheckmarkAccessoryView.h"


@interface VSCheckmarkAccessoryView ()

@property (nonatomic, assign) CGFloat checkmarkOriginY;
@property (nonatomic, assign) CGFloat checkmarkMarginRight;
@property (nonatomic, strong) UIImage *checkmarkImage;
@property (nonatomic, strong) UIImageView *checkmarkImageView;

@end


@implementation VSCheckmarkAccessoryView


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame checkmarkOriginY:(CGFloat)checkmarkOriginY checkmarkMarginRight:(CGFloat)checkmarkMarginRight checkmarkImage:(UIImage *)checkmarkImage {

	self = [self initWithFrame:frame];
	if (self == nil)
		return nil;

	_checkmarkOriginY = checkmarkOriginY;
	_checkmarkMarginRight = checkmarkMarginRight;
	_checkmarkImage = checkmarkImage;

	_checkmarkImageView = [[UIImageView alloc] initWithImage:_checkmarkImage];
	_checkmarkImageView.contentMode = UIViewContentModeCenter;
	[self addSubview:_checkmarkImageView];

	self.backgroundColor = [UIColor clearColor];
	self.opaque = NO;
//	self.backgroundColor = [UIColor redColor];

	[self setNeedsLayout];

	return self;
}


#pragma mark - UIView

- (void)layoutSubviews {

	CGRect r = CGRectZero;
	r.size = self.checkmarkImageView.frame.size;
	r.origin.y = self.checkmarkOriginY;
	r.origin.x = CGRectGetMaxX(self.bounds) - (CGRectGetWidth(r) + self.checkmarkMarginRight);

	[self.checkmarkImageView qs_setFrameIfNotEqual:r];
}


//- (void)drawRect:(CGRect)rect {
//
//	[[UIColor redColor] set];
//	UIRectFill(rect);
//}

@end
