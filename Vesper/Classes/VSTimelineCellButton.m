//
//  VSTimelineCellButton.m
//  Vesper
//
//  Created by Brent Simmons on 8/11/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTimelineCellButton.h"


@interface VSTimelineCellButton ()

@property (nonatomic, assign) CGFloat textMarginTop;
@property (nonatomic, assign) CGSize titleSize;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) CGSize imageAndTitleSize;

@end


@implementation VSTimelineCellButton


#pragma mark - Class Methods

+ (UIImage *)backgroundImage:(NSString *)themeSpecifier {
	
	CGRect r = CGRectMake(0.0f, 0.0f, 128.0f, 128.0f);
	
	UIGraphicsBeginImageContextWithOptions(r.size, YES, [UIScreen mainScreen].scale);
	
	UIColor *color = [app_delegate.theme colorForKey:VSThemeSpecifierPlusKey(themeSpecifier, @"backgroundColor")];
	[color set];
	UIRectFill(r);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIEdgeInsets capInsets = UIEdgeInsetsMake(0.0f, 0.0, 0.0f, 0.0f);
	image = [image resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeTile];
	
	return image;
}


+ (UIImage *)image:(NSString *)themeSpecifier {
	
	UIColor *tintColor = [app_delegate.theme colorForKey:VSThemeSpecifierPlusKey(themeSpecifier, @"imageColor")];
	NSString *imageName = [app_delegate.theme stringForKey:VSThemeSpecifierPlusKey(themeSpecifier, @"asset")];
	
	UIImage *image = [UIImage imageNamed:imageName];
	image = [image qs_imageTintedWithColor:tintColor];
	
	return image;
}


+ (NSAttributedString *)attributedTitle:(NSString *)title themeSpecifier:(NSString *)themeSpecifier {
	
	UIFont *font = [app_delegate.theme fontForKey:VSThemeSpecifierPlusKey(themeSpecifier, @"font")];
	UIColor *textColor = [app_delegate.theme colorForKey:VSThemeSpecifierPlusKey(themeSpecifier, @"textColor")];
	
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : textColor, NSKernAttributeName : [NSNull null]}];
	
	return attributedString;
}


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame themeSpecifier:(NSString *)themeSpecifier title:(NSString *)title {
	
	self = [self initWithFrame:frame];
	if (self == nil)
		return nil;
	
	UIImage *backgroundImage = [[self class] backgroundImage:themeSpecifier];
	[self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
	[self setBackgroundImage:backgroundImage forState:UIControlStateSelected];
	[self setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
	
	UIImage *image = [[self class] image:themeSpecifier];
	[self setImage:image forState:UIControlStateNormal];
	[self setImage:image forState:UIControlStateSelected];
	[self setImage:image forState:UIControlStateHighlighted];
	
	self.adjustsImageWhenDisabled = NO;
	self.adjustsImageWhenHighlighted = NO;
	
	NSAttributedString *attributedTitle = [[self class] attributedTitle:title themeSpecifier:themeSpecifier];
	[self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
	[self setAttributedTitle:attributedTitle forState:UIControlStateSelected];
	[self setAttributedTitle:attributedTitle forState:UIControlStateHighlighted];
	
	_titleSize = [attributedTitle size];
	_imageSize = image.size;
	_textMarginTop = [app_delegate.theme floatForKey:VSThemeSpecifierPlusKey(themeSpecifier, @"textMarginTop")];
	
	_imageAndTitleSize = CGSizeZero;
	_imageAndTitleSize.height = _imageSize.height + _textMarginTop + _titleSize.height;
	_imageAndTitleSize.width = MAX(_imageSize.width, _titleSize.width);
	
	self.contentMode = UIViewContentModeCenter;
	
	return self;
}


#pragma mark - UIButton

- (UIButtonType)buttonType {
	return UIButtonTypeCustom;
}


- (CGRect)contentRectForBounds:(CGRect)bounds {
	
	CGRect rContent = CGRectZero;
	rContent.size = self.imageAndTitleSize;
	
	rContent = CGRectCenteredInRect(rContent, bounds);
	rContent.size = self.imageAndTitleSize;
	
	return rContent;
}


- (CGRect)titleRectForContentRect:(CGRect)contentRect {
	
	CGRect rTitle = CGRectZero;
	rTitle.size = self.titleSize;
	
	rTitle = CGRectCenteredHorizontallyInRect(rTitle, contentRect);
	rTitle.size = self.titleSize;
	
	rTitle.origin.y = CGRectGetMaxY(contentRect) - CGRectGetHeight(rTitle);
	return rTitle;
}


- (CGRect)imageRectForContentRect:(CGRect)contentRect {
	
	CGRect rImage = CGRectZero;
	rImage.size = self.imageSize;
	
	rImage = CGRectCenteredHorizontallyInRect(rImage, contentRect);
	rImage.size = self.imageSize;
	
	rImage.origin.y = CGRectGetMinY(contentRect);
	return rImage;
}


@end
