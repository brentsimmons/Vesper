//
//  VSNavbarButton.m
//  Vesper
//
//  Created by Brent Simmons on 12/6/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSNavbarButton.h"


@implementation VSNavbarButton


+ (UIButton *)navbarButtonWithImage:(UIImage *)image selectedImage:(UIImage *)selectedImage highlightedImage:(UIImage *)highlightedImage {
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	
	/*image is pre-tinted*/
	//    UIColor *tintColor = [app_delegate.theme colorForKey:@"navbarButtonColor"];
	//    image = [image qs_imageTintedWithColor:tintColor];
	
	[button setImage:image forState:UIControlStateNormal];
	[button setImage:(selectedImage ? selectedImage : image) forState:UIControlStateSelected];
	[button setImage:(highlightedImage ? highlightedImage : image) forState:UIControlStateHighlighted];
	
	button.adjustsImageWhenDisabled = NO;
	button.adjustsImageWhenHighlighted = NO;
	
	button.contentMode = UIViewContentModeCenter;
	
	return button;
}


+ (UIButton *)toolbarButtonWithImage:(UIImage *)image selectedImage:(UIImage *)selectedImage highlightedImage:(UIImage *)highlightedImage {
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	
	UIColor *tintColor = [app_delegate.theme colorForKey:@"toolbarButtonColor"];
	image = [image qs_imageTintedWithColor:tintColor];
	
	UIColor *pressedTintColor = VSPressedColor(tintColor);
	//    UIColor *pressedTintColor = [app_delegate.theme colorForKey:@"toolbarButtonPressedColor"];
	if (highlightedImage != nil)
		highlightedImage = [highlightedImage qs_imageTintedWithColor:pressedTintColor];
	
	[button setImage:image forState:UIControlStateNormal];
	[button setImage:(selectedImage ? selectedImage : image) forState:UIControlStateSelected];
	[button setImage:(highlightedImage ? highlightedImage : image) forState:UIControlStateHighlighted];
	
	button.adjustsImageWhenDisabled = NO;
	button.adjustsImageWhenHighlighted = NO;
	
	button.contentMode = UIViewContentModeCenter;
	
	return button;
	
}

+ (UIFont *)buttonFont {
	return [app_delegate.theme fontForKey:@"navbarButtonFont"];
}


+ (UIColor *)buttonFontColor {
	return [app_delegate.theme colorForKey:@"navbarButtonFontColor"];
}


+ (UIColor *)buttonPressedFontColor {
	UIColor *color = [self buttonFontColor];
	color = VSPressedColor(color);
	return color;
	//    return [app_delegate.theme colorForKey:@"navbarButtonPressedFontColor"];
}


//+ (NSAttributedString *)attributedStringWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color {
//    return [[NSAttributedString alloc] initWithString:(text ? text : @"") attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: color}];
//}


+ (NSAttributedString *)attributedStringWithText:(NSString *)text pressed:(BOOL)pressed {
	
	NSDictionary *attributes = [self attributedTextAttributes:pressed];
	return [[NSAttributedString alloc] initWithString:text attributes:attributes];
	//    UIFont *font = [self buttonFont];
	//    UIColor *color = pressed ? [self buttonPressedFontColor] : [self buttonFontColor];
	//
	//    return [self attributedStringWithText:text font:font color:color];
}


+ (NSDictionary *)attributedTextAttributes:(BOOL)pressed {
	
	UIFont *font = [self buttonFont];
	UIColor *color = pressed ? [self buttonPressedFontColor] : [self buttonFontColor];
	
	return @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
}


+ (UIColor *)tintColor {
	return [app_delegate.theme colorForKey:@"navbarTextButtonColor"];
}


+ (UIColor *)tintColorPressed {
	UIColor *color = [self tintColor];
	color = VSPressedColor(color);
	return color;
	//    return [app_delegate.theme colorForKey:@"navbarButtonPressedColor"];
}


@end


@implementation VSNavbarTextButton


#pragma mark Class Methods

+ (CGSize)sizeWithAttributedTitle:(NSAttributedString *)attributedTitle {
	
	CGFloat imageCapLeft = [app_delegate.theme floatForKey:@"navbarTextButtonCapLeft"];
	CGFloat imageCapRight = [app_delegate.theme floatForKey:@"navbarTextButtonCapRight"];
	
	CGSize textSize = [attributedTitle size];
	CGFloat maximumButtonWidth = [app_delegate.theme floatForKey:@"navbarTextButtonMaxWidth"];
	CGFloat buttonWidth = MIN(imageCapLeft + textSize.width + 15 + imageCapRight, maximumButtonWidth);
	
	UIImage *image = [self buttonImage];
	CGSize buttonSize = CGSizeMake(buttonWidth, image.size.height);
	
	UIEdgeInsets buttonPadding = [self buttonPadding];
	buttonSize.height += (buttonPadding.top + buttonPadding.bottom);
	buttonSize.width += (buttonPadding.left + buttonPadding.right);
	
	return buttonSize;
}


+ (CGSize)sizeWithTitle:(NSString *)title {
	
	NSAttributedString *attributedTitle = [self attributedStringWithText:title pressed:NO];;
	return [self sizeWithAttributedTitle:attributedTitle];
}


+ (VSNavbarTextButton *)buttonWithAttributedTitle:(NSAttributedString *)attributedTitle attributedTitlePressed:(NSAttributedString *)attributedTitlePressed {
	
	CGRect rButton = CGRectZero;
	rButton.size = [self sizeWithAttributedTitle:attributedTitle];
	
	return [[self alloc] initWithFrame:rButton attributedTitle:attributedTitle attributedTitlePressed:attributedTitlePressed];
}


+ (instancetype)buttonWithTitle:(NSString *)title {
	
	NSAttributedString *attributedTitle = [self attributedStringWithText:title pressed:NO];
	NSAttributedString *attributedTitlePressed = [self attributedStringWithText:title pressed:YES];
	
	return [self buttonWithAttributedTitle:attributedTitle attributedTitlePressed:attributedTitlePressed];
}


+ (UIImage *)buttonImage {
	NSString *imageName = [app_delegate.theme stringForKey:@"navbarTextButtonAsset"];
	return [UIImage imageNamed:imageName];
}


+ (UIImage *)buttonPressedImage {
	return [self buttonImage];
	//    NSString *imageName = [app_delegate.theme stringForKey:@"navbarTextButtonPressedAsset"];
	//    return [UIImage imageNamed:imageName];
}


+ (UIEdgeInsets)buttonPadding {
	return [app_delegate.theme edgeInsetsForKey:@"navbarTextButtonPadding"];
}


+ (UIImage *)backgroundImageWithImage:(UIImage *)image tintColor:(UIColor *)tintColor {
	
	CGFloat imageCapLeft = [app_delegate.theme floatForKey:@"navbarTextButtonCapLeft"];
	CGFloat imageCapRight = [app_delegate.theme floatForKey:@"navbarTextButtonCapRight"];
	UIEdgeInsets capInsets = UIEdgeInsetsMake(0.0f, imageCapLeft, 0.0f, imageCapRight);
	
	image = [image qs_imageTintedWithColor:tintColor];
	image = [image resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
	
	return image;
}


+ (UIImage *)backgroundImageNormal {
	
	return [self backgroundImageWithImage:[self buttonImage] tintColor:[self tintColor]];
}


+ (UIImage *)backgroundImagePressed {
	
	return [self backgroundImageWithImage:[self buttonPressedImage] tintColor:[self tintColorPressed]];
}





#pragma mark Init

- (id)initWithFrame:(CGRect)frame attributedTitle:(NSAttributedString *)attributedTitle attributedTitlePressed:(NSAttributedString *)attributedTitlePressed {
	
	self = [self initWithFrame:frame];
	if (self == nil)
		return nil;
	
	//    CGFloat imageCapLeft = [app_delegate.theme floatForKey:@"navbarTextButtonCapLeft"];
	//    CGFloat imageCapRight = [app_delegate.theme floatForKey:@"navbarTextButtonCapRight"];
	//
	//    UIEdgeInsets capInsets = UIEdgeInsetsMake(0.0f, imageCapLeft, 0.0f, imageCapRight);
	//    UIImage *image = [[self class] buttonImage];
	//    UIImage *imagePressed = [[self class] buttonPressedImage];
	//
	//    UIColor *tintColor = [[self class] tintColor];
	//    image = [image qs_imageTintedWithColor:tintColor];
	//    image = [image resizableImageWithCapInsets:capInsets];
	//
	//    UIColor *tintColorPressed = [[self class] tintColorPressed];
	//    imagePressed = [imagePressed qs_imageTintedWithColor:tintColorPressed];
	//    imagePressed = [imagePressed resizableImageWithCapInsets:capInsets];
	
	UIImage *image = [[self class] backgroundImageNormal];
	UIImage *imagePressed = [[self class] backgroundImagePressed];
	
	[self setBackgroundImage:image forState:UIControlStateNormal];
	[self setBackgroundImage:(imagePressed ? imagePressed : image) forState:UIControlStateSelected];
	[self setBackgroundImage:(imagePressed ? imagePressed : image) forState:UIControlStateHighlighted];
	
	self.adjustsImageWhenDisabled = NO;
	self.adjustsImageWhenHighlighted = NO;
	
	[self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateSelected];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateHighlighted];
	
	self.contentMode = UIViewContentModeCenter;
	
	self.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
	
	return self;
}


#pragma mark UIButton

- (UIButtonType)buttonType {
	return UIButtonTypeCustom;
}


- (CGRect)backgroundRectForBounds:(CGRect)bounds {
	CGRect rBounds = bounds;
	UIEdgeInsets buttonPadding = [[self class] buttonPadding];
	rBounds.origin.x += buttonPadding.left;
	rBounds.size.width -= (buttonPadding.left + buttonPadding.right);
	rBounds.origin.y += buttonPadding.top;
	rBounds.size.height -= (buttonPadding.top + buttonPadding.bottom);
	return rBounds;
}


- (CGRect)contentRectForBounds:(CGRect)bounds {
	return [self backgroundRectForBounds:bounds];
}


@end


@implementation VSNavbarBackButton


#pragma mark Class Methods

+ (CGSize)sizeWithAttributedTitle:(NSAttributedString *)attributedTitle {
	
	
	CGSize textSize = [attributedTitle size];
	CGFloat maximumButtonWidth = [app_delegate.theme floatForKey:@"navbarBackButtonMaxWidth"];
	//    CGFloat buttonWidth = MIN(imageCapLeft + QSCeil(textSize.width) + imageCapRight, maximumButtonWidth);
	CGFloat textPadding = [app_delegate.theme floatForKey:@"navbarBackButtonTextMarginLeft"];
	CGFloat buttonWidth = [self buttonImage].size.width + textPadding + QSCeil(textSize.width);
	buttonWidth = MIN(buttonWidth, maximumButtonWidth);
	
	UIImage *image = [self buttonImage];
	CGSize buttonSize = CGSizeMake(buttonWidth, image.size.height);
	
	UIEdgeInsets buttonPadding = [self buttonPadding];
	buttonSize.height += (buttonPadding.top + buttonPadding.bottom);
	buttonSize.width += (buttonPadding.left + buttonPadding.right);
	
	return buttonSize;
}


+ (UIImage *)buttonImage {
	
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *imageName = [app_delegate.theme stringForKey:@"navbarSidebarButton"];
		image = [UIImage imageNamed:imageName];
	});
	
	return image;
}


//+ (UIImage *)buttonPressedImage {
//    NSString *imageName = [app_delegate.theme stringForKey:@"navbarBackButtonPressedAsset"];
//    return [UIImage imageNamed:imageName];
//}


+ (UIEdgeInsets)buttonPadding {
	return [app_delegate.theme edgeInsetsForKey:@"navbarBackButtonPadding"];
}


+ (UIFont *)buttonFont {
	UIFont *font = [app_delegate.theme fontForKey:@"navbarBackButtonFont"];
	if (VSDefaultsTextWeight() == VSTextWeightLight)
		font = [app_delegate.theme fontForKey:@"navbarBackButtonLightFont"];
	return font;
}


#pragma mark Init

- (id)initWithFrame:(CGRect)frame attributedTitle:(NSAttributedString *)attributedTitle attributedTitlePressed:(NSAttributedString *)attributedTitlePressed {
	
	self = [self initWithFrame:frame];
	if (self == nil)
		return nil;
	
	//    CGFloat imageCapLeft = [app_delegate.theme floatForKey:@"navbarBackButtonCapLeft"];
	//    CGFloat imageCapRight = [app_delegate.theme floatForKey:@"navbarBackButtonCapRight"];
	//
	//    UIEdgeInsets capInsets = UIEdgeInsetsMake(0.0f, imageCapLeft, 0.0f, imageCapRight);
	UIImage *image = [[self class] buttonImage];
	UIImage *imagePressed = [[self class] buttonPressedImage];
	
	UIColor *tintColor = [[self class] tintColor];
	image = [image qs_imageTintedWithColor:tintColor];
	
	UIColor *tintColorPressed = [[self class] tintColorPressed];
	imagePressed = [imagePressed qs_imageTintedWithColor:tintColorPressed];
	
	[self setImage:image forState:UIControlStateNormal];
	[self setImage:(imagePressed ? imagePressed : image) forState:UIControlStateSelected];
	[self setImage:(imagePressed ? imagePressed : image) forState:UIControlStateHighlighted];
	
	self.adjustsImageWhenDisabled = NO;
	self.adjustsImageWhenHighlighted = NO;
	
	[self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateSelected];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateHighlighted];
	
	self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	self.contentMode = UIViewContentModeCenter;
	
	//    self.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 6.0f, 0.0f, 0.0f);
	
	return self;
}


- (CGRect)titleRectForContentRect:(CGRect)contentRect {
	
	CGRect r = contentRect;
	CGRect rImageRect = [self imageRectForContentRect:contentRect];
	
	r.origin.x = CGRectGetMaxX(rImageRect) - 18.0f; /*18.0f is fudge to make left side of text line up with apparent right edge of image.*/
	CGFloat textPadding = [app_delegate.theme floatForKey:@"navbarBackButtonTextMarginLeft"];
	r.origin.x += textPadding;
	r.origin.y += [app_delegate.theme floatForKey:@"navbarBackButtonTextOffsetY"];
	
	r.size.width = CGRectGetWidth(contentRect) - CGRectGetMinX(r);
	
	return r;
}


- (CGRect)imageRectForContentRect:(CGRect)contentRect {
	
	CGRect r = contentRect;
	
	r.size = [[self class] buttonImage].size;
	r.origin.y += 0.5f;
	r.origin.x += 2.0f;
	
	return r;
}


@end


@implementation VSToolbarTextButton

+ (UIColor *)tintColor {
	return [app_delegate.theme colorForKey:@"toolbarButtonColor"];
}


//+ (UIColor *)tintColorPressed {
//    return [app_delegate.theme colorForKey:@"toolbarButtonPressedColor"];
//}


+ (UIFont *)buttonFont {
	return [app_delegate.theme fontForKey:@"toolbarButtonFont"];
}


+ (UIColor *)buttonFontColor {
	return [app_delegate.theme colorForKey:@"toolbarButtonFontColor"];
}


//+ (UIColor *)buttonPressedFontColor {
//    return [app_delegate.theme colorForKey:@"toolbarButtonPressedFontColor"];
//}


@end


@implementation VSSearchBarCancelButton

+ (UIImage *)buttonImage {
	NSString *imageName = [app_delegate.theme stringForKey:@"searchBarCancelButtonAsset"];
	return [UIImage imageNamed:imageName];
}


//+ (UIImage *)buttonPressedImage {
//    NSString *imageName = [app_delegate.theme stringForKey:@"searchBarCancelButtonAssetPressed"];
//    return [UIImage imageNamed:imageName];
//}


+ (UIColor *)tintColor {
	return [app_delegate.theme colorForKey:@"searchBarCancelButtonColor"];
}


//+ (UIColor *)tintColorPressed {
//    return [app_delegate.theme colorForKey:@"searchBarCancelButtonPressedColor"];
//}


+ (UIFont *)buttonFont {
	return [app_delegate.theme fontForKey:@"searchBarCancelButtonFont"];
}


+ (UIColor *)buttonFontColor {
	return [app_delegate.theme colorForKey:@"searchBarCancelButtonFontColor"];
}


//+ (UIColor *)buttonPressedFontColor {
//    return [app_delegate.theme colorForKey:@"searchBarCancelButtonPressedFontColor"];
//}


@end


@implementation VSBrowserTextButton

+ (UIImage *)buttonImage {
	NSString *imageName = [app_delegate.theme stringForKey:@"browserTextButtonAsset"];
	return [UIImage imageNamed:imageName];
}


//+ (UIImage *)buttonPressedImage {
//    NSString *imageName = [app_delegate.theme stringForKey:@"browserTextButtonAssetPressed"];
//    return [UIImage imageNamed:imageName];
//}


+ (UIColor *)tintColor {
	return [app_delegate.theme colorForKey:@"browserTextButtonColor"];
}


//+ (UIColor *)tintColorPressed {
//    return [app_delegate.theme colorForKey:@"browserTextButtonPressedColor"];
//}


+ (UIFont *)buttonFont {
	return [app_delegate.theme fontForKey:@"browserTextButtonFont"];
}


+ (UIColor *)buttonFontColor {
	return [app_delegate.theme colorForKey:@"browserTextButtonFontColor"];
}


//+ (UIColor *)buttonPressedFontColor {
//    return [app_delegate.theme colorForKey:@"browserTextButtonPressedFontColor"];
//}


@end


@implementation VSPhotoTextButton

+ (UIImage *)buttonImage {
	NSString *imageName = [app_delegate.theme stringForKey:@"photoTextButtonAsset"];
	return [UIImage imageNamed:imageName];
}


//+ (UIImage *)buttonPressedImage {
//    NSString *imageName = [app_delegate.theme stringForKey:@"photoTextButtonAssetPressed"];
//    return [UIImage imageNamed:imageName];
//}


+ (UIColor *)tintColor {
	return [app_delegate.theme colorForKey:@"photoTextButtonColor"];
}


//+ (UIColor *)tintColorPressed {
//    return [app_delegate.theme colorForKey:@"photoTextButtonPressedColor"];
//}


+ (UIFont *)buttonFont {
	return [app_delegate.theme fontForKey:@"photoTextButtonFont"];
}


+ (UIColor *)buttonFontColor {
	return [app_delegate.theme colorForKey:@"photoTextButtonFontColor"];
}


//+ (UIColor *)buttonPressedFontColor {
//    return [app_delegate.theme colorForKey:@"photoTextButtonPressedFontColor"];
//}


@end

