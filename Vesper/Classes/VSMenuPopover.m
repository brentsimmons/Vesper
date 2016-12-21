//
//  VSMenuPopover.m
//  Vesper
//
//  Created by Brent Simmons on 5/6/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSMenuPopover.h"
#import "VSMenuButton.h"
#import "VSMenuItem.h"
#import "VSPopoverBackgroundView.h"



NSString *VSPopoverDidDismissNotification = @"VSPopoverDidDismissNotification";
NSString *VSPopoverKey = @"VSPopoverDidDismissNotification";


static NSString *specifierPlusKey(NSString *specifier, NSString *key) {
	return [NSString stringWithFormat:@"%@.%@", specifier, key];
}


static VSMenuPopoverLayoutBits menuPopoverLayoutBits(VSTheme *theme, NSString *specifier) {
	
	VSMenuPopoverLayoutBits layoutBits;
	
	layoutBits.padding = [theme edgeInsetsForKey:specifierPlusKey(specifier, @"padding")];
	layoutBits.chevronSize = [theme sizeForKey:specifierPlusKey(specifier, @"chevron")];
	layoutBits.borderCornerRadius = [theme floatForKey:specifierPlusKey(specifier, @"borderCornerRadius")];
	layoutBits.borderWidth = [theme floatForKey:specifierPlusKey(specifier, @"borderWidth")];
	layoutBits.backgroundAlpha = [theme floatForKey:specifierPlusKey(specifier, @"backgroundAlpha")];
	layoutBits.marginLeft = [theme floatForKey:specifierPlusKey(specifier, @"marginLeft")];
	layoutBits.marginRight = [theme floatForKey:specifierPlusKey(specifier, @"marginRight")];
	layoutBits.buttonHeight = [theme floatForKey:specifierPlusKey(specifier, @"buttonHeight")];
	layoutBits.buttonWidth = [theme floatForKey:specifierPlusKey(specifier, @"buttonWidth")];
	layoutBits.interButtonSpace = [theme floatForKey:specifierPlusKey(specifier, @"interButtonSpace")];
	if (!RSIsRetinaScreen())
		layoutBits.interButtonSpace = QSCeil(layoutBits.interButtonSpace);
	layoutBits.fadeInDuration = [theme floatForKey:specifierPlusKey(specifier, @"fadeInDuration")];
	layoutBits.fadeOutDuration = [theme floatForKey:specifierPlusKey(specifier, @"fadeOutDuration")];
	layoutBits.dividerWidth = [theme floatForKey:specifierPlusKey(specifier, @"dividerWidth")];
	
	return layoutBits;
}


@interface VSMenuPopover () <VSPopoverBackgroundViewDelegate>


@end


@implementation VSMenuPopover


#pragma mark - Init

- (instancetype)initWithPopoverSpecifier:(NSString *)popoverSpecifier {
	
	self = [self initWithFrame:CGRectZero];
	if (self == nil)
		return nil;
	
	_hasArrow = YES;
	_layoutBits = menuPopoverLayoutBits(app_delegate.theme, popoverSpecifier);
	_menuItems = [NSMutableArray new];
	_arrowOnTop = YES;
	_borderColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"borderColor")];
	_destructiveButtonIndex = NSNotFound;
	_popoverSpecifier = popoverSpecifier;
	
	UIColor *fillColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"backgroundColor")];
	_fillColor = [fillColor colorWithAlphaComponent:_layoutBits.backgroundAlpha];
	
	self.backgroundColor = [UIColor clearColor];
	self.accessibilityViewIsModal = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uiEventDidHappen:) name:VSUIEventHappenedNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Notifications

- (void)uiEventDidHappen:(NSNotification *)note {
	[self dismiss:nil];
}


#pragma mark - VSPopoverBackgroundViewDelegate

- (void)didTapPopoverBackgroundView:(VSPopoverBackgroundView *)popoverBackgroundView {
	[self dismiss:nil];
}


#pragma mark - Actions

- (void)menuButtonTapped:(VSMenuButton *)menuButton {
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	
	[menuButton.menuItem.target performSelector:menuButton.menuItem.action withObject:self];
	
#pragma clang diagnostic pop
	
	[self dismiss:nil];
}


#pragma mark - Menu Items

- (void)addItemWithTitle:(NSString *)title image:(UIImage *)image target:(id)target action:(SEL)action {
	
	VSMenuItem *menuItem = [VSMenuItem new];
	menuItem.title = title;
	menuItem.target = target;
	menuItem.action = action;
	menuItem.image = image;
	
	[self.menuItems addObject:menuItem];
}


#pragma mark - Show

- (void)removeButtons {
	[self.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[self.buttons removeAllObjects];
}


- (CGRect)rectForButtonAtIndex:(NSUInteger)ix {
	
	VSMenuPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGRect r = CGRectZero;
	r.origin.x = layoutBits.marginLeft + layoutBits.padding.left;
	r.size.width = self.bounds.size.width - (r.origin.x + layoutBits.padding.right + layoutBits.marginRight);
	
	r.origin.y = layoutBits.padding.top;
	if (self.arrowOnTop)
		r.origin.y += layoutBits.chevronSize.height;
	r.origin.y += layoutBits.buttonHeight * ix;
	r.origin.y += layoutBits.interButtonSpace * ix;
	
	r.size.height = layoutBits.buttonHeight;
	
	r.origin.y += 1.0f; /*fudge*/
	
	return r;
}


- (void)layoutButtons {
	
	[self removeButtons];
	
	NSUInteger ix = 0;
	
	for (VSMenuItem *oneMenuItem in self.menuItems) {
		
		VSMenuButton *oneButton = [[VSMenuButton alloc] initWithFrame:[self rectForButtonAtIndex:ix] menuItem:oneMenuItem destructive:(ix == self.destructiveButtonIndex) popoverSpecifier:self.popoverSpecifier];
		[self addSubview:oneButton];
		[self.buttons addObject:oneButton];
		ix++;
	}
	
}


- (void)addBackgroundView:(CGRect)backgroundViewRect view:(UIView *)view {
	self.backgroundView = [[VSPopoverBackgroundView alloc] initWithFrame:backgroundViewRect popoverSpecifier:self.popoverSpecifier delegate:self];
	[view addSubview:self.backgroundView];
	
}

- (void)showFromPoint:(CGPoint)point inView:(UIView *)view backgroundViewRect:(CGRect)backgroundViewRect {
	
	if (self.showing)
		return;
	
	self.showing = YES;
	[self addBackgroundView:backgroundViewRect view:view];
 
	[view addSubview:self];
	
	self.chevronPoint = point;
	
	CGRect r = CGRectZero;
	r.size = [self sizeThatFits:CGSizeZero];
	
	if (self.arrowOnTop)
		r.origin.y = point.y;
	else
		r.origin.y = point.y - r.size.height;
	
	self.frame = r;
	
	[self layoutButtons];
	[self addShadow];
	[self fadeIn];
}


#pragma mark - Dismiss

- (void)dismiss:(VSPopoverDidDismissCallback)completion {
	
	if (!self.showing) {
		if (completion != nil)
			completion(self);
		return;
	}
	
	self.showing = NO;
	[self fadeOutAndDismiss:completion];
}


#pragma mark - UIView

- (CGFloat)height {
	
	VSMenuPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGFloat height = layoutBits.borderWidth + layoutBits.padding.top + layoutBits.padding.bottom + layoutBits.borderWidth + layoutBits.chevronSize.height;
	
	for (VSMenuItem *oneMenuItem in self.menuItems) {
		height += layoutBits.buttonHeight;
		if (oneMenuItem != [self.menuItems lastObject])
			height += layoutBits.interButtonSpace;
	}
	
	return height;
}


- (CGSize)sizeThatFits:(CGSize)constrainingSize {
	
#pragma unused(constrainingSize)
	
	CGSize size = CGSizeZero;
	
	CGFloat width = self.width;
	if (width < 1.0f) {
		if (self.superview != nil)
			width = self.superview.bounds.size.width;
	}
	
	size.width = width;
	size.height = self.height;
	return size;
}


#pragma mark - Drawing


- (CGRect)bubbleRect {
	
	VSMenuPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGRect rBubble = self.bounds;
	rBubble.size.height -= layoutBits.chevronSize.height;
	rBubble.origin.x += layoutBits.padding.left;
	rBubble.size.width -= (layoutBits.padding.left + layoutBits.padding.right);
	
	if (self.arrowOnTop)
		rBubble.origin.y += layoutBits.chevronSize.height;
	
	rBubble = CGRectInset(rBubble, layoutBits.borderCornerRadius, layoutBits.borderCornerRadius);
	
	//	if ([UIScreen mainScreen].scale < 1.1f) {
	//		rBubble.origin.x += 0.5f;
	//		rBubble.size.width -= 1.0f;
	//		rBubble.origin.y += 0.5f;
	//		rBubble.size.height -= 1.0f;
	//	}
	
	return rBubble;
}


#define degreesToRadians(x) ((x) * (CGFloat)M_PI / 180.0f)

- (UIBezierPath *)popoverPath {
	
	VSMenuPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGRect rBubble = [self bubbleRect];
	
	UIBezierPath *path = [UIBezierPath bezierPath];
	path.lineWidth = layoutBits.borderWidth;
	
	[path addArcWithCenter:rBubble.origin radius:layoutBits.borderCornerRadius startAngle:degreesToRadians(180.0f) endAngle:degreesToRadians(270.0f) clockwise:YES];
	
	if (self.arrowOnTop && self.hasArrow) {
		
		CGPoint pt = self.chevronPoint;
		pt.x -= self.frame.origin.x;
		
		CGPoint arrowLeft = pt;
		arrowLeft.x = arrowLeft.x - (layoutBits.chevronSize.width / 2.0f);
		arrowLeft.y = CGRectGetMinY(rBubble) - layoutBits.borderCornerRadius;
		
		CGPoint arrowMiddle = arrowLeft;
		arrowMiddle.x = pt.x;
		arrowMiddle.y = arrowLeft.y - layoutBits.chevronSize.height;
		
		CGPoint arrowRight = arrowLeft;
		arrowRight.x = arrowRight.x + layoutBits.chevronSize.width;
		
		[path addLineToPoint:arrowLeft];
		[path addLineToPoint:arrowMiddle];
		[path addLineToPoint:arrowRight];
	}
	
	[path addArcWithCenter:CGPointMake(CGRectGetMaxX(rBubble), CGRectGetMinY(rBubble)) radius:layoutBits.borderCornerRadius startAngle:degreesToRadians(270.0f) endAngle:degreesToRadians(360.0f) clockwise:YES];
	
	[path addArcWithCenter:CGPointMake(CGRectGetMaxX(rBubble), CGRectGetMaxY(rBubble)) radius:layoutBits.borderCornerRadius startAngle:degreesToRadians(0.0f) endAngle:degreesToRadians(90.0f) clockwise:YES];
	
	if (!self.arrowOnTop && self.hasArrow) {
		
		CGPoint pt = self.chevronPoint;
		pt.x -= self.frame.origin.x;
		
		CGPoint arrowRight = pt;
		
		arrowRight.x = arrowRight.x + (layoutBits.chevronSize.width / 2.0f);
		arrowRight.y = CGRectGetMaxY(rBubble) + layoutBits.borderCornerRadius;
		
		CGPoint arrowMiddle = arrowRight;
		arrowMiddle.x = pt.x;
		arrowMiddle.y = arrowRight.y + layoutBits.chevronSize.height;
		
		CGPoint arrowLeft = arrowRight;
		arrowLeft.x = arrowLeft.x - layoutBits.chevronSize.width;
		
		[path addLineToPoint:arrowRight];
		[path addLineToPoint:arrowMiddle];
		[path addLineToPoint:arrowLeft];
	}
	
	[path addArcWithCenter:CGPointMake(CGRectGetMinX(rBubble), CGRectGetMaxY(rBubble)) radius:layoutBits.borderCornerRadius startAngle:degreesToRadians(90.0f) endAngle:degreesToRadians(180.0f) clockwise:YES];
	
	[path closePath];
	
	return path;
}


- (BOOL)isOpaque {
	return NO;
}


- (void)drawRect:(CGRect)rect {
	
	[super drawRect:rect];
	UIBezierPath *path = [self popoverPath];
	
	[self.fillColor set];
	[path fill];
	[self.borderColor set];
	[path stroke];
}


#pragma mark - Animations

- (void)fadeIn {
	
	self.alpha = 0.0f;
	self.backgroundView.alpha = 0.0f;
	
	[UIView animateWithDuration:self.layoutBits.fadeInDuration animations:^{
		self.alpha = 1.0f;
		[self.backgroundView restoreInitialAlpha];
	} completion:^(BOOL finished) {
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self);
	}];
}


- (void)fadeOutAndDismiss:(VSPopoverDidDismissCallback)completion {
	
	[UIView animateWithDuration:self.layoutBits.fadeOutDuration animations:^{
		self.alpha = 0.0f;
		self.backgroundView.alpha = 0.0f;
	} completion:^(BOOL finished) {
		
		[self.backgroundView removeFromSuperview];
		self.backgroundView = nil;
		[self removeFromSuperview];
		
		if (completion != nil)
			completion(self);
		[[NSNotificationCenter defaultCenter] postNotificationName:VSPopoverDidDismissNotification object:self userInfo:nil];
	}];
	
}

#pragma mark -

- (BOOL)accessibilityPerformEscape
{
	[self didTapPopoverBackgroundView:self.backgroundView];
	return YES;
}


#pragma mark - Shadow

- (void)addShadow {
	
	UIColor *shadowColor = [app_delegate.theme colorForKey:specifierPlusKey(self.popoverSpecifier, @"shadowColor")];
	CGFloat shadowOpacity = [app_delegate.theme floatForKey:specifierPlusKey(self.popoverSpecifier, @"shadowOpacity")];
	CGFloat shadowOffsetY = [app_delegate.theme floatForKey:specifierPlusKey(self.popoverSpecifier, @"shadowOffsetY")];
	CGFloat shadowRadius = [app_delegate.theme floatForKey:specifierPlusKey(self.popoverSpecifier, @"shadowBlurRadius")];
	
	self.layer.shadowColor = shadowColor.CGColor;
	self.layer.shadowOpacity = (float)shadowOpacity;
	self.layer.shadowOffset = CGSizeMake(0.0f, shadowOffsetY);
	self.layer.shadowRadius = shadowRadius;
}


@end


