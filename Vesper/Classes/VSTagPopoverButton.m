//
//  VSTagPopoverButton.m
//  Vesper
//
//  Created by Brent Simmons on 5/23/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTagPopoverButton.h"
#import "VSMenuItem.h"


static NSString *specifierPlusKey(NSString *specifier, NSString *key) {
	return [NSString stringWithFormat:@"%@.%@", specifier, key];
}


@interface VSTagPopoverButton ()

@property (nonatomic, strong) UIColor *buttonColor;
@property (nonatomic, strong) UIColor *buttonPressedColor;
@property (nonatomic, strong) UIColor *destructiveButtonColor;
@property (nonatomic, strong) UIColor *destructiveButtonPressedColor;
@property (nonatomic, assign) BOOL destructive;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIColor *titlePressedColor;
@property (nonatomic, strong) NSString *popoverSpecifier;
@property (nonatomic, assign) CGFloat cornerRadius;

@end


@implementation VSTagPopoverButton


- (id)initWithFrame:(CGRect)frame menuItem:(VSMenuItem *)menuItem destructive:(BOOL)destructive popoverSpecifier:(NSString *)popoverSpecifier {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_destructive = destructive;
	_menuItem = menuItem;
	_popoverSpecifier = popoverSpecifier;
	
	//_buttonColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonColor")];
	_buttonColor = [UIColor clearColor];
	_buttonPressedColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonPressedColor")];
	_destructiveButtonColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonDestructiveColor")];
	_destructiveButtonPressedColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonDestructiveColorPressed")];
	
	_titleFont = [app_delegate.theme fontForKey:specifierPlusKey(popoverSpecifier, @"buttonFont")];
	_titleColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonTextColor")];
	_titlePressedColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"buttonTextColorPressed")];
	
	_cornerRadius = [app_delegate.theme floatForKey:specifierPlusKey(popoverSpecifier, @"borderCornerRadius")];
	
	self.contentMode = UIViewContentModeCenter;
	[self updateImages];
	[self updateTitle];
	
	[self addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	return self;
}


#pragma mark - Layout


+ (CGFloat)widthOfButtonWithTitle:(NSString *)title popoverSpecifier:(NSString *)popoverSpecifier {
	
	UIFont *font = [app_delegate.theme fontForKey:specifierPlusKey(popoverSpecifier, @"buttonFont")];
	NSDictionary *attributes = @{NSFontAttributeName : font};
	NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:attributes];
	
	CGFloat paddingLeft = [app_delegate.theme floatForKey:specifierPlusKey(popoverSpecifier, @"buttonTextPaddingLeft")];
	CGFloat paddingRight = [app_delegate.theme floatForKey:specifierPlusKey(popoverSpecifier, @"buttonTextPaddingRight")];
	
	CGFloat widthOfString = [attString size].width;
	
	CGFloat buttonWidth = paddingLeft + widthOfString + paddingRight;
	
	return buttonWidth;
}

#pragma mark - Actions

- (void)buttonTapped:(id)sender {
	
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(menuButtonTapped:) withObject:self];
}


#pragma mark - Title

- (NSAttributedString *)attributedTitleStringWithColor:(UIColor *)color {
	
	NSDictionary *attributes = @{NSFontAttributeName : self.titleFont, NSForegroundColorAttributeName : color};
	NSAttributedString *attString = [[NSAttributedString alloc] initWithString:self.menuItem.title attributes:attributes];
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


- (UIImage *)imageWithColor:(UIColor *)color position:(VSPosition)position {
	
	/*Resizable image*/
	
	CGSize size = CGSizeMake(32.0f, 32.0f);
	CGRect r = CGRectZero;
	r.size = size;
	
	UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
	
	/*Enlarge the rect so we draw rounded corners outside area to capture.*/
	
	static const CGFloat extraPointsToHideRoundedCorners = 10.0f; /*arbitrary*/
	
	switch (position) {
			
		case VSFirst:
			r.size.width += extraPointsToHideRoundedCorners;
			break;
			
		case VSLast:
			r.origin.x -= extraPointsToHideRoundedCorners;
			r.size.width += extraPointsToHideRoundedCorners;
			break;
			
		case VSMiddle:
			r.origin.x -= extraPointsToHideRoundedCorners;
			r.size.width += (extraPointsToHideRoundedCorners * 2);
			break;
			
		case VSOnly:
			break;
			
		default:
			break;
	}
	
	CGRect rPath = CGRectInset(r, 0.5f, 0.5f);
	
	UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rPath cornerRadius:self.cornerRadius];
	bezierPath.lineWidth = 1.0f;
	
	[color set];
	[bezierPath fill];
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	static CGFloat capInset = 10.0f;
	UIEdgeInsets capInsets = UIEdgeInsetsMake(capInset, capInset, capInset, capInset);
	image = [image resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
	
	return image;
}


- (UIImage *)backgroundImage {
	return [self imageWithColor:self.buttonColor position:self.menuItem.position];
}


- (UIImage *)backgroundImagePressed {
	return [self imageWithColor:self.buttonPressedColor position:self.menuItem.position];
}


- (UIImage *)destructiveBackgroundImage {
	return [self imageWithColor:self.destructiveButtonColor position:self.menuItem.position];
}


- (UIImage *)destructiveBackgroundImagePressed {
	return [self imageWithColor:self.destructiveButtonPressedColor position:self.menuItem.position];
}


@end
