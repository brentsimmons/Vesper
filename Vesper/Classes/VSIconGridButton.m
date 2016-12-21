//
//  VSIconGridButton.m
//  Vesper
//
//  Created by Brent Simmons on 5/13/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSIconGridButton.h"
#import "VSMenuItem.h"


typedef struct {
	CGFloat cornerRadius;
	CGFloat textMarginBottom;
	CGFloat iconMarginTop;
	CGFloat buttonTitleOffsetY;
	VSTextCaseTransform textCaseTransform;
} VSIconGridButtonLayoutBits;


static NSString *specifierPlusKey(NSString *specifier, NSString *key) {
	return [NSString stringWithFormat:@"%@.%@", specifier, key];
}

static VSIconGridButtonLayoutBits buttonLayoutBits(VSTheme *theme, NSString *specifier) {
	
	VSIconGridButtonLayoutBits layoutBits;
	
	layoutBits.cornerRadius = [theme floatForKey:specifierPlusKey(specifier, @"buttonCornerRadius")];
	layoutBits.textMarginBottom = [theme floatForKey:specifierPlusKey(specifier, @"buttonTextMarginBottom")];
	layoutBits.iconMarginTop = [theme floatForKey:specifierPlusKey(specifier, @"buttonIconMarginTop")];
	layoutBits.buttonTitleOffsetY = [theme floatForKey:specifierPlusKey(specifier, @"buttonTitleOffsetY")];
	layoutBits.textCaseTransform = [theme textCaseTransformForKey:specifierPlusKey(specifier, @"buttonTitleTransform")];
	
	return layoutBits;
}


@interface VSIconGridButton ()

@property (nonatomic, assign) VSIconGridButtonLayoutBits layoutBits;
@property (nonatomic, strong) UIColor *buttonColor;
@property (nonatomic, strong) UIColor *buttonPressedColor;
@property (nonatomic, strong) UIColor *buttonPressedBackgroundColor;
@property (nonatomic, strong) UIColor *destructiveButtonColor;
@property (nonatomic, strong) UIColor *destructiveButtonPressedColor;
@property (nonatomic, strong) UIColor *destructiveButtonPressedBackgroundColor;
@property (nonatomic, assign) BOOL destructive;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIColor *titleDestructiveColor;
@property (nonatomic, strong) UIColor *titleDestructivePressedColor;
@property (nonatomic, strong) UIColor *titlePressedColor;
@property (nonatomic, strong) NSString *popoverSpecifier;

@end


@implementation VSIconGridButton


- (id)initWithFrame:(CGRect)frame menuItem:(VSMenuItem *)menuItem destructive:(BOOL)destructive popoverSpecifier:(NSString *)popoverSpecifier {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_destructive = destructive;
	_menuItem = menuItem;
	_popoverSpecifier = popoverSpecifier;
	_layoutBits = buttonLayoutBits(app_delegate.theme, popoverSpecifier);
	
	_buttonColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonColor")];
	_buttonPressedColor = VSPressedColor(_buttonColor);
	//    _buttonPressedColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonPressedColor")];
	_buttonPressedBackgroundColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonPressedBackgroundColor")];
	_destructiveButtonColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonDestructiveColor")];
	//    _destructiveButtonPressedColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonDestructiveColorPressed")];
	_destructiveButtonPressedColor = VSPressedColor(_destructiveButtonColor);
	_destructiveButtonPressedBackgroundColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonDestructiveColorPressedBackground")];
	
	_titleFont = [app_delegate.theme fontForKey:specifierPlusKey(popoverSpecifier, @"buttonFont")];
	_titleColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonTextColor")];
	//    _titlePressedColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonTextColorPressed")];
	_titlePressedColor = VSPressedColor(_titleColor);
	_titleDestructiveColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonDestructiveTextColor")];
	//    _titleDestructivePressedColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonDestructiveTextColorPressed")];
	_titleDestructivePressedColor = VSPressedColor(_titleDestructiveColor);
	
	[self updateImages];
	self.contentMode = UIViewContentModeCenter;
	
	[self updateTitle];
	self.titleLabel.contentMode = UIViewContentModeCenter;
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	
	[self addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	self.adjustsImageWhenHighlighted = NO;
	self.adjustsImageWhenDisabled = NO;
	
	self.userInteractionEnabled = YES;
	
	return self;
}


#pragma mark - Actions

- (void)buttonTapped:(id)sender {
	
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(menuButtonTapped:) withObject:self];
}


#pragma mark - Title

- (NSString *)transformedTitle:(NSString *)title {
	
	if (self.layoutBits.textCaseTransform == VSTextCaseTransformNone)
		return title;
	
	else if (self.layoutBits.textCaseTransform == VSTextCaseTransformLower)
		return [title lowercaseString];
	
	return [title uppercaseString];
}


- (NSAttributedString *)attributedTitleStringWithColor:(UIColor *)color {
	
	NSDictionary *attributes = @{NSFontAttributeName : self.titleFont, NSForegroundColorAttributeName : color};
	NSString *title = [self transformedTitle:self.menuItem.title];
	NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:attributes];
	return attString;
}


- (NSAttributedString *)attributedTitle {
	UIColor *color = self.destructive ? self.titleDestructiveColor : self.titleColor;
	return [self attributedTitleStringWithColor:color];
}


- (NSAttributedString *)attributedTitlePressed {
	UIColor *color = self.destructive ? self.titleDestructivePressedColor : self.titlePressedColor;
	return [self attributedTitleStringWithColor:color];
}


- (void)updateTitle {
	
	NSAttributedString *attributedTitle = [self attributedTitle];
	NSAttributedString *attributedTitlePressed = [self attributedTitlePressed];
	
	[self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateSelected];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateHighlighted];
}


#pragma mark - Images

- (void)updateImages {
	
	UIImage *image = self.destructive ? [self destructiveBackgroundImage] : [self backgroundImage];
	UIImage *imagePressed = self.destructive ? [self destructiveBackgroundImagePressed] : [self backgroundImagePressed];
	
	[self setBackgroundImage:image forState:UIControlStateNormal];
	[self setBackgroundImage:imagePressed forState:UIControlStateSelected];
	[self setBackgroundImage:imagePressed forState:UIControlStateHighlighted];
	
	self.adjustsImageWhenDisabled = NO;
	self.adjustsImageWhenHighlighted = NO;
}


- (UIImage *)imageWithColor:(UIColor *)color backgroundColor:(UIColor *)backgroundColor {
	
	CGRect rBounds = self.bounds;
	
	UIGraphicsBeginImageContextWithOptions(rBounds.size, NO, [UIScreen mainScreen].scale);
	
	CGRect rPath = CGRectInset(rBounds, 0.5f, 0.5f);
	
	UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rPath cornerRadius:self.layoutBits.cornerRadius];
	
	[backgroundColor set];
	[bezierPath fill];
	
	UIImage *icon = self.menuItem.image;
	icon = [icon qs_imageTintedWithColor:color];
	
	CGSize imageSize = icon.size;
	CGRect rImage = CGRectZero;
	rImage.origin.y = self.layoutBits.iconMarginTop;
	rImage.size = imageSize;
	
	CGRect rContainer = rBounds;
	rContainer.origin.x = 0.0f;
	rContainer.origin.y = 0.0f;
	
	rImage = CGRectCenteredHorizontallyInRect(rImage, rContainer);
	rImage.size = imageSize;
	[icon drawInRect:rImage];
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}


- (UIImage *)backgroundImage {
	return [self imageWithColor:self.buttonColor backgroundColor:[UIColor clearColor]];
}


- (UIImage *)backgroundImagePressed {
	return [self imageWithColor:self.buttonPressedColor backgroundColor:self.buttonPressedBackgroundColor];
}


- (UIImage *)destructiveBackgroundImage {
	return [self imageWithColor:self.destructiveButtonColor backgroundColor:[UIColor clearColor]];
}


- (UIImage *)destructiveBackgroundImagePressed {
	return [self imageWithColor:self.destructiveButtonPressedColor backgroundColor:self.destructiveButtonPressedBackgroundColor];
}


#pragma mark - UIButton

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
	
	CGSize titleSize = [[self attributedTitle] size];
	
	CGRect r = contentRect;
	r.size.height = QSCeil(titleSize.height);
	r.origin.y = CGRectGetMaxY(contentRect) - (r.size.height + self.layoutBits.textMarginBottom);
	r.origin.y += self.layoutBits.buttonTitleOffsetY;
	return r;
}


@end
