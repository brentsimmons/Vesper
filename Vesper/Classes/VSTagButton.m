//
//  VSTagButton.m
//  Vesper
//
//  Created by Brent Simmons on 4/10/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTagButton.h"
#import "VSTagProxy.h"
#import "VSTagPopover.h"


typedef struct {
	CGFloat bubbleHeight;
	CGFloat cornerRadius;
	CGFloat textMarginLeft;
	CGFloat textMarginRight;
} VSTagButtonLayoutBits;


@interface VSTagButton ()

@property (nonatomic, assign) VSTagButtonLayoutBits layoutBits;
@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) VSTagProxy *tagProxy;
@property (nonatomic, assign) CGFloat titleWidth;
@end


@implementation VSTagButton


#pragma mark - Class Methods

+ (VSTagButtonLayoutBits)layoutBits {

	VSTagButtonLayoutBits layoutBits;

	layoutBits.bubbleHeight = [app_delegate.theme floatForKey:@"tagBubbleHeight"];
	layoutBits.cornerRadius = [app_delegate.theme floatForKey:@"tagBubbleCornerRadius"];
	layoutBits.textMarginLeft = [app_delegate.theme floatForKey:@"tagBubbleTextMarginLeft"];
	layoutBits.textMarginRight = [app_delegate.theme floatForKey:@"tagBubbleTextMarginRight"];

	return layoutBits;
}


+ (UIFont *)buttonFont {
	return [app_delegate.theme fontForKey:@"tagBubbleFont"];
}


+ (UIColor *)buttonFontColor {
	return [app_delegate.theme colorForKey:@"tagBubbleFontColor"];
}


+ (UIColor *)buttonPressedFontColor {
	return [app_delegate.theme colorForKey:@"tagBubbleFontPressedColor"];
}


+ (UIColor *)bubbleColor {
	return [app_delegate.theme colorForKey:@"tagDetailColor"];
}


+ (UIColor *)bubblePressedColor {
	return [app_delegate.theme colorForKey:@"tagDetailPressedColor"];
}


+ (CGFloat)widthOfAttributedString:(NSAttributedString *)attString {
	CGSize size = [attString size];
#if __LP64__
	CGFloat width = ceil(size.width) + 2.0f;
#else
	CGFloat width = ceilf(size.width) + 2.0f;
#endif
	return width;
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


+ (CGSize)sizeWithAttributedTitle:(NSAttributedString *)attributedTitle {

	VSTagButtonLayoutBits layoutBits = [self layoutBits];
	CGFloat paddingLeft = layoutBits.textMarginLeft;
	CGFloat paddingRight = layoutBits.textMarginRight;

	CGFloat textWidth = [self widthOfAttributedString:attributedTitle];
	CGFloat buttonWidth = paddingLeft + textWidth + paddingRight;

	CGSize buttonSize = CGSizeMake(buttonWidth, layoutBits.bubbleHeight);
	return buttonSize;
}


+ (CGSize)sizeWithTitle:(NSString *)title {

	if (QSStringIsEmpty(title))
		return CGSizeZero;

	NSAttributedString *attributedTitle = [self attributedStringWithText:title pressed:NO];

	return [self sizeWithAttributedTitle:attributedTitle];
}


+ (instancetype)buttonWithAttributedTitle:(NSAttributedString *)attributedTitle attributedTitlePressed:(NSAttributedString *)attributedTitlePressed {

	CGRect rButton = CGRectZero;
	rButton.size = [self sizeWithAttributedTitle:attributedTitle];

	return [[self alloc] initWithFrame:rButton attributedTitle:attributedTitle attributedTitlePressed:attributedTitlePressed];
}


+ (instancetype)buttonWithTitle:(NSString *)title {

	if (QSStringIsEmpty(title))
		return nil;

	NSAttributedString *attributedTitle = [self attributedStringWithText:title pressed:NO];
	NSAttributedString *attributedTitlePressed = [self attributedStringWithText:title pressed:YES];

	return [self buttonWithAttributedTitle:attributedTitle attributedTitlePressed:attributedTitlePressed];
}


+ (instancetype)buttonWithTagProxy:(VSTagProxy *)tagProxy {

	VSTagButton *tagButton = [self buttonWithTitle:tagProxy.name];
	tagButton.tagProxy = tagProxy;
	return tagButton;
}


+ (UIImage *)buttonImage {
	static UIImage *image = nil;
	if (image != nil)
		return image;
	image = [self buttonImage:NO];
	return image;
}


+ (UIImage *)buttonPressedImage {
	static UIImage *image = nil;
	if (image != nil)
		return image;
	image = [self buttonImage:YES];
	return image;
}


+ (UIImage *)buttonImage:(BOOL)pressed {

	UIImage *image = nil;
	VSTagButtonLayoutBits layoutBits = [self layoutBits];

	CGSize size = CGSizeZero;
	size.height = layoutBits.bubbleHeight;
	size.width = 32.0f;

	UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);

	UIColor *color = nil;
	if (pressed)
		color = [self bubblePressedColor];
	else
		color = [self bubbleColor];
	[color set];

	CGRect r = CGRectZero;
	r.size = size;
	UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:layoutBits.cornerRadius];
	[bezierPath fill];

	image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return image;
}


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame attributedTitle:(NSAttributedString *)attributedTitle attributedTitlePressed:(NSAttributedString *)attributedTitlePressed {

	self = [self initWithFrame:frame];
	if (self == nil)
		return nil;

	_titleWidth = [[self class] widthOfAttributedString:attributedTitle];
	_title = [attributedTitle string];
	_tagProxy = [VSTagProxy tagProxyWithName:_title];

	_layoutBits = [[self class] layoutBits];

	UIImage *image = [[self class] buttonImage];
	UIImage *imagePressed = [[self class] buttonPressedImage];

	CGFloat imageCapLeft = 16.0f;
	CGFloat imageCapRight = 15.0f;
	UIEdgeInsets capInsets = UIEdgeInsetsMake(0.0f, imageCapLeft, 0.0f, imageCapRight);
	image = [image resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
	imagePressed = [imagePressed resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];

	[self setBackgroundImage:image forState:UIControlStateNormal];
	[self setBackgroundImage:(imagePressed ? imagePressed : image) forState:UIControlStateSelected];
	[self setBackgroundImage:(imagePressed ? imagePressed : image) forState:UIControlStateHighlighted];

	self.adjustsImageWhenDisabled = NO;
	self.adjustsImageWhenHighlighted = NO;

	self.clearsContextBeforeDrawing = YES;

	[self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateSelected];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateHighlighted];

	self.contentMode = UIViewContentModeRedraw;

	self.titleLabel.lineBreakMode = NSLineBreakByClipping;

	[self addTarget:self action:@selector(tagButtonTapped) forControlEvents:UIControlEventTouchUpInside];

	return self;
}


#pragma mark - UIButton

- (UIButtonType)buttonType {
	return UIButtonTypeCustom;
}


- (CGRect)contentRectForBounds:(CGRect)bounds {

	CGRect r = bounds;
	r.origin.x = r.origin.x + self.layoutBits.textMarginLeft;
	r.origin.y = 2.0f;
	r.size.height = bounds.size.height - 4.0f;
	r.size.width = bounds.size.width - (self.layoutBits.textMarginLeft + self.layoutBits.textMarginRight);

	return r;
}


- (CGRect)titleRectForContentRect:(CGRect)contentRect {

	CGRect r = contentRect;
	r.origin.y += [app_delegate.theme floatForKey:@"tagBubbleTextOffsetY"];

	return r;
}


#pragma mark - Deleting

- (void)hideOrShowPopover:(id)sender {
	[self hideOrShowPopover];
}


#pragma mark - Popover

- (void)hideOrShowPopover {
	[self qs_performSelectorViaResponderChain:@selector(showOrHideTagPopoverFromTagButton:) withObject:self];
}


#pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)size {

	/*Ignores size parameter.*/

	return [[self class] sizeWithTitle:self.title];
}


#pragma mark - Actions

- (void)tagButtonTapped {
	[self hideOrShowPopover:self];
}


@end
