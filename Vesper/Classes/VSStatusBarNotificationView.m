//
//  VSStatusBarNotificationView.m
//  Vesper
//
//  Created by Brent Simmons on 5/3/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSStatusBarNotificationView.h"


@interface VSStatusBarNotificationView ()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *label;

@end


@implementation VSStatusBarNotificationView


#pragma mark - Init

- (instancetype)initWithIconName:(NSString *)iconName text:(NSString *)s {

	self = [super initWithFrame:CGRectZero];
	if (!self) {
		return nil;
	}

	UIImage *image = [UIImage imageNamed:iconName];
	image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	_imageView = [[UIImageView alloc] initWithImage:image];
	_imageView.tintColor = [app_delegate.theme colorForKey:@"statusBarNotification.iconColor"];
	[self addSubview:_imageView];

	_label = [[UILabel alloc] initWithFrame:CGRectZero];
	_label.opaque = NO;
	_label.backgroundColor = [UIColor clearColor];
	_label.numberOfLines = 1;
	_label.text = s;

	UIFont *font = [app_delegate.theme fontForKey:@"statusBarNotification.font"];
	if (VSDefaultsUsingLightText()) {
		font = [app_delegate.theme fontForKey:@"statusBarNotification.fontLight"];
	}

	UIColor *color = [app_delegate.theme colorForKey:@"statusBarNotification.textColor"];
	NSAttributedString *attString = [NSAttributedString qs_attributedStringWithText:s font:font color:color kerning:YES];
	_label.attributedText = attString;

	[self addSubview:_label];

	[_label sizeToFit];

	self.backgroundColor = [app_delegate.theme colorForKey:@"statusBarNotification.backgroundColor"];

	return self;
}


#pragma mark - Layout

- (void)layoutSubviews {

	CGRect rBounds = self.bounds;
	CGRect rLabel = self.label.frame;
	CGRect rImage = self.imageView.frame;

	CGSize imageSize = rImage.size;
	CGSize labelSize = rLabel.size;

	rLabel = CGRectCenteredVerticallyInRect(rLabel, rBounds);
	rImage = CGRectCenteredVerticallyInRect(rImage, rBounds);

	CGFloat spacing = [app_delegate.theme floatForKey:@"statusBarNotification.iconMarginLeft"];
	CGFloat totalWidth = CGRectGetWidth(rImage) + spacing + CGRectGetWidth(rLabel);

	rImage.origin.x = (CGRectGetWidth(rBounds) - totalWidth) / 2.0f;
	rImage = CGRectIntegral(rImage);
	rImage.size = imageSize;

	rLabel.origin.x = CGRectGetMaxX(rImage) + spacing;
	rLabel = CGRectIntegral(rLabel);
	rLabel.size = labelSize;

	[self.imageView qs_setFrameIfNotEqual:rImage];
	[self.label qs_setFrameIfNotEqual:rLabel];
}


@end
