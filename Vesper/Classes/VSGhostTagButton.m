//
//  VSGhostTagButton.m
//  Vesper
//
//  Created by Brent Simmons on 4/10/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSGhostTagButton.h"
#import "VSTagProxy.h"


typedef struct {
	CGFloat bubbleHeight;
	CGFloat bubbleWidth;
	CGFloat cornerRadius;
} VSGhostTagButtonLayoutBits;


@interface VSGhostTagButton ()

@property (nonatomic, assign) VSGhostTagButtonLayoutBits layoutBits;
@property (nonatomic, assign, readonly) CGFloat titleWidth;
@end


@implementation VSGhostTagButton


#pragma mark - Class Methods

+ (VSGhostTagButtonLayoutBits)layoutBits {
	
	VSGhostTagButtonLayoutBits layoutBits;
	
	layoutBits.bubbleHeight = [app_delegate.theme floatForKey:@"tagBubbleHeight"];
	layoutBits.bubbleWidth = [app_delegate.theme floatForKey:@"tagGhostWidth"];
	layoutBits.cornerRadius = [app_delegate.theme floatForKey:@"tagBubbleCornerRadius"];
	
	return layoutBits;
}


+ (CGSize)sizeThatFits:(CGSize)constrainingSize {
	
	/*Ignores constrainingSize*/
	
	VSGhostTagButtonLayoutBits layoutBits = [self layoutBits];
	
	CGSize size = CGSizeMake(layoutBits.bubbleWidth, layoutBits.bubbleHeight);
	return size;
}


+ (UIFont *)buttonFont {
	return [app_delegate.theme fontForKey:@"tagGhostBubbleFont"];
}


+ (UIColor *)buttonFontColor {
	return [app_delegate.theme colorForKey:@"tagGhostBubbleFontColor"];
}


+ (UIColor *)buttonPressedFontColor {
	return [app_delegate.theme colorForKey:@"tagGhostBubbleFontColor"];
}


+ (CGFloat)buttonHeight {
	return [self layoutBits].bubbleHeight;
}


+ (UIColor *)bubbleColor {
	return [app_delegate.theme colorForKey:@"tagGhostBubbleColor"];
}


+ (UIColor *)bubblePressedColor {
	return [app_delegate.theme colorForKey:@"tagGhostBubblePressedColor"];
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


+ (instancetype)buttonWithAttributedTitle:(NSAttributedString *)attributedTitle attributedTitlePressed:(NSAttributedString *)attributedTitlePressed {
	
	CGRect rButton = CGRectZero;
	rButton.size = [self sizeThatFits:rButton.size];
	
	return [[self alloc] initWithFrame:rButton attributedTitle:attributedTitle attributedTitlePressed:attributedTitlePressed];
}


+ (instancetype)button {
	
	NSString *title = [app_delegate.theme stringForKey:@"tagGhostTitle"];
	
	NSAttributedString *attributedTitle = [self attributedStringWithText:title pressed:NO];
	NSAttributedString *attributedTitlePressed = [self attributedStringWithText:title pressed:YES];
	
	return [self buttonWithAttributedTitle:attributedTitle attributedTitlePressed:attributedTitlePressed];
}


+ (UIImage *)buttonImage:(BOOL)pressed {
	
	UIImage *image = nil;
	
	CGSize size = [self sizeThatFits:CGSizeZero];
	
	UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
	
	UIColor *color = nil;
	if (pressed)
		color = [self bubblePressedColor];
	else
		color = [self bubbleColor];
	[color set];
	
	CGRect r = CGRectZero;
	r.size = size;
	UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:[self layoutBits].cornerRadius];
	[bezierPath fill];
	
	image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame attributedTitle:(NSAttributedString *)attributedTitle attributedTitlePressed:(NSAttributedString *)attributedTitlePressed {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	UIImage *image = [[self class] buttonImage:NO];
	UIImage *imagePressed = [[self class] buttonImage:YES];
	
	CGFloat imageCapLeft = 6.0f;
	CGFloat imageCapRight = 6.0f;
	UIEdgeInsets capInsets = UIEdgeInsetsMake(0.0f, imageCapLeft, 0.0f, imageCapRight);
	image = [image resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
	imagePressed = [imagePressed resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
	
	[self setBackgroundImage:image forState:UIControlStateNormal];
	[self setBackgroundImage:(imagePressed ? imagePressed : image) forState:UIControlStateSelected];
	[self setBackgroundImage:(imagePressed ? imagePressed : image) forState:UIControlStateHighlighted];
	
	self.adjustsImageWhenDisabled = NO;
	self.adjustsImageWhenHighlighted = NO;
	
	[self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateSelected];
	[self setAttributedTitle:attributedTitlePressed forState:UIControlStateHighlighted];
	
	[self addTarget:self action:@selector(ghostTagButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	_titleWidth = QSCeil([attributedTitle size].width);
	
	self.contentMode = UIViewContentModeRedraw;
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	
	return self;
}


#pragma mark UIButton

- (UIButtonType)buttonType {
	return UIButtonTypeCustom;
}


- (CGRect)titleRectForContentRect:(CGRect)contentRect {
	CGRect r = contentRect;
	r.origin.y += [app_delegate.theme floatForKey:@"tagGhostTitleOffsetY"];
	//    r.size.width = contentRect.size.width;
	//    r = CGRectCenteredHorizontallyInRect(r, contentRect);
	return r;
}


#pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)constrainingSize {
	return [[self class] sizeThatFits:constrainingSize];
}


#pragma mark - VSEditableTagView

- (VSTagProxy *)tagProxy {
	return [VSGhostTagProxy ghostTagProxy];
}


#pragma mark - Actions

- (void)ghostTagButtonTapped:(id)sender {
	
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(ghostTagButtonTapped:) withObject:sender];
}

@end

