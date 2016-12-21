//
//  VSMenuButton.m
//  Vesper
//
//  Created by Brent Simmons on 5/6/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSMenuButton.h"
#import "VSMenuItem.h"




static NSString *specifierPlusKey(NSString *specifier, NSString *key) {
	return [NSString stringWithFormat:@"%@.%@", specifier, key];
}

static VSMenuButtonLayoutBits buttonLayoutBits(VSTheme *theme, NSString *specifier) {
	
	VSMenuButtonLayoutBits layoutBits;
	
	layoutBits.cornerRadius = [theme floatForKey:specifierPlusKey(specifier, @"buttonCornerRadius")];
	layoutBits.borderWidth = [theme floatForKey:specifierPlusKey(specifier, @"buttonBorderWidth")];
	layoutBits.textCaseTransform = [theme textCaseTransformForKey:@"buttonTitleTransform"];
	
	return layoutBits;
}


@interface VSMenuButton ()

@property (nonatomic, strong) UIColor *buttonColor;
@property (nonatomic, strong) UIColor *buttonPressedColor;
@property (nonatomic, strong) UIColor *destructiveButtonColor;
@property (nonatomic, strong) UIColor *destructiveButtonPressedColor;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIColor *titlePressedColor;
@property (nonatomic, strong) NSString *popoverSpecifier;

@end


@implementation VSMenuButton

- (id)initWithFrame:(CGRect)frame menuItem:(VSMenuItem *)menuItem destructive:(BOOL)destructive popoverSpecifier:(NSString *)popoverSpecifier {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_destructive = destructive;
	_menuItem = menuItem;
	_popoverSpecifier = popoverSpecifier;
	_layoutBits = buttonLayoutBits(app_delegate.theme, popoverSpecifier);
	
	_buttonColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonColor")];
	_buttonPressedColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonPressedColor")];
	_destructiveButtonColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonDestructiveColor")];
	_destructiveButtonPressedColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonDestructiveColorPressed")];
	
	_titleFont = [app_delegate.theme fontForKey:specifierPlusKey(popoverSpecifier, @"buttonFont")];
	_titleColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonTextColor")];
	_titlePressedColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonTextColorPressed")];
	
	_borderColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonBorderColor")];
	
	[self updateImages];
	self.contentMode = UIViewContentModeCenter;
	
	[self updateTitle];
	
	[self addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
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
	return [self attributedTitleStringWithColor:self.titleColor];
}


- (NSAttributedString *)attributedTitlePressed {
	return [self attributedTitleStringWithColor:self.titlePressedColor];
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


- (UIImage *)imageWithColor:(UIColor *)color {
	
	CGRect rBounds = self.bounds;
	
	UIGraphicsBeginImageContextWithOptions(rBounds.size, NO, [UIScreen mainScreen].scale);
	
	CGRect rPath = CGRectInset(rBounds, 0.5f, 0.5f);
	
	UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rPath cornerRadius:self.layoutBits.cornerRadius];
	bezierPath.lineWidth = self.layoutBits.borderWidth;
	
	[color set];
	[bezierPath fill];
	
	[self.borderColor set];
	[bezierPath stroke];
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}


- (UIImage *)backgroundImage {
	return [self imageWithColor:self.buttonColor];
}


- (UIImage *)backgroundImagePressed {
	return [self imageWithColor:self.buttonPressedColor];
}


- (UIImage *)destructiveBackgroundImage {
	return [self imageWithColor:self.destructiveButtonColor];
}


- (UIImage *)destructiveBackgroundImagePressed {
	return [self imageWithColor:self.destructiveButtonPressedColor];
}


@end
