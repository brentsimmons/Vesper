//
//  VSTagSuggestionButton.m
//  Vesper
//
//  Created by Brent Simmons on 4/10/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTagSuggestionButton.h"


@implementation VSTagSuggestionButton


#pragma mark - Class Methods

+ (UIFont *)buttonFont {
	return [app_delegate.theme fontForKey:@"autoCompleteFont"];
}


+ (UIColor *)buttonFontColor {
	return [app_delegate.theme colorForKey:@"autoCompleteFontColor"];
}


+ (UIColor *)buttonPressedFontColor {
	return [app_delegate.theme colorForKey:@"autoCompletePressedFontColor"];
}


+ (CGFloat)buttonPaddingLeft {
	return [app_delegate.theme floatForKey:@"autoCompleteButtonPaddingLeft"];
}


+ (CGFloat)buttonPaddingRight {
	return [app_delegate.theme floatForKey:@"autoCompleteButtonPaddingRight"];
}


+ (CGFloat)buttonHeight {
	return [app_delegate.theme floatForKey:@"autoCompleteBubbleHeight"];
}


+ (NSAttributedString *)attributedStringWithText:(NSString *)text pressed:(BOOL)pressed {
	
	NSDictionary *attributes = [self attributedTextAttributes:pressed];
	return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}


+ (NSDictionary *)attributedTextAttributes:(BOOL)pressed {
	
	UIFont *font = [self buttonFont];
	UIColor *color = pressed ? [self buttonPressedFontColor] : [self buttonFontColor];
	
	return @{NSFontAttributeName: font, NSForegroundColorAttributeName: color, NSKernAttributeName : [NSNull null]};
}


static const CGFloat kMinimumWidth = 30.0f;

+ (CGSize)sizeWithAttributedTitle:(NSAttributedString *)attributedTitle {
	
	CGFloat paddingLeft = [self buttonPaddingLeft];
	CGFloat paddingRight = [self buttonPaddingRight];
	
	CGSize textSize = [attributedTitle size];
#if __LP64__
	CGFloat buttonWidth = paddingLeft + ceil(textSize.width) + paddingRight;
#else
	CGFloat buttonWidth = paddingLeft + ceilf(textSize.width) + paddingRight;
#endif
	buttonWidth = MAX(kMinimumWidth, buttonWidth);
	
	CGSize buttonSize = CGSizeMake(buttonWidth, [self buttonHeight]);
	return buttonSize;
}


+ (CGSize)sizeWithTitle:(NSString *)title {
	
	NSAttributedString *attributedTitle = [self attributedStringWithText:title pressed:NO];
	return [self sizeWithAttributedTitle:attributedTitle];
}


+ (instancetype)buttonWithAttributedTitle:(NSAttributedString *)attributedTitle attributedTitlePressed:(NSAttributedString *)attributedTitlePressed {
	
	CGRect rButton = CGRectZero;
	rButton.size = [self sizeWithAttributedTitle:attributedTitle];
	
	return [[self alloc] initWithFrame:rButton attributedTitle:attributedTitle attributedTitlePressed:attributedTitlePressed];
}


+ (instancetype)buttonWithTitle:(NSString *)title {
	
	NSAttributedString *attributedTitle = [self attributedStringWithText:title pressed:NO];
	NSAttributedString *attributedTitlePressed = [self attributedStringWithText:title pressed:YES];
	
	return [self buttonWithAttributedTitle:attributedTitle attributedTitlePressed:attributedTitlePressed];
}


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame attributedTitle:(NSAttributedString *)attributedTitle attributedTitlePressed:(NSAttributedString *)attributedTitlePressed {
	
	self = [self initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_tagName = [attributedTitle string];
	
	self.adjustsImageWhenDisabled = NO;
	self.adjustsImageWhenHighlighted = NO;
	
	[self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateSelected];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateHighlighted];
	
	self.contentMode = UIViewContentModeCenter;
	
	//    self.titleEdgeInsets = UIEdgeInsetsMake(1.5f, 0.0f, 0.0f, 0.0f);
	
	return self;
}


#pragma mark - UIButton

- (UIButtonType)buttonType {
	return UIButtonTypeCustom;
}


@end
