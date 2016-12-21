//
//  VSActivityPopover.m
//  Vesper
//
//  Created by Brent Simmons on 8/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSActivityPopover.h"
#import "VSPopoverBackgroundView.h"
#import "VSIconGridButton.h"
#import "VSMenuPopover.h"
#import "VSMenuItem.h"
#import "VSMenuButton.h"


typedef struct {
	UIEdgeInsets padding;
	BOOL borderTop;
	BOOL borderBottom;
	CGFloat borderWidth;
	CGFloat buttonWidth;
	CGFloat buttonHeight;
	CGFloat backgroundColorAlpha;
	CGFloat interButtonSpace;
	CGFloat height;
	NSTimeInterval animateInDuration;
	NSTimeInterval animateOutDuration;
	UIViewAnimationOptions animateInCurve;
	UIViewAnimationOptions animateOutCurve;
} VSActivityPopoverLayoutBits;



static NSString *specifierPlusKey(NSString *specifier, NSString *key) {
	return [NSString stringWithFormat:@"%@.%@", specifier, key];
}


static VSActivityPopoverLayoutBits activityPopoverLayoutBits(VSTheme *theme, NSString *specifier) {
	
	VSActivityPopoverLayoutBits layoutBits;
	
	layoutBits.padding = [theme edgeInsetsForKey:specifierPlusKey(specifier, @"padding")];
	layoutBits.borderTop = [theme boolForKey:specifierPlusKey(specifier, @"borderTop")];
	layoutBits.borderBottom = [theme boolForKey:specifierPlusKey(specifier, @"borderBottom")];
	layoutBits.borderWidth = [theme floatForKey:specifierPlusKey(specifier, @"borderWidth")];
	layoutBits.buttonWidth = [theme floatForKey:specifierPlusKey(specifier, @"buttonWidth")];
	layoutBits.backgroundColorAlpha = [theme floatForKey:specifierPlusKey(specifier, @"backgroundColorAlpha")];
	layoutBits.interButtonSpace = [theme floatForKey:specifierPlusKey(specifier, @"interButtonSpace")];
	layoutBits.height = [theme floatForKey:specifierPlusKey(specifier, @"height")];
	layoutBits.animateInDuration = [theme timeIntervalForKey:specifierPlusKey(specifier, @"animateInDuration")];
	layoutBits.animateOutDuration = [theme timeIntervalForKey:specifierPlusKey(specifier, @"animateOutDuration")];
	layoutBits.animateInCurve = [theme curveForKey:specifierPlusKey(specifier, @"animateInCurve")];
	layoutBits.animateOutCurve = [theme curveForKey:specifierPlusKey(specifier, @"animateOutCurve")];
	
	layoutBits.buttonHeight = layoutBits.height - (layoutBits.padding.top + layoutBits.padding.bottom);
	
	if (layoutBits.borderTop) {
		layoutBits.height += layoutBits.borderWidth;
	}
	if (layoutBits.borderBottom) {
		layoutBits.height += layoutBits.borderBottom;
	}
	
	return layoutBits;
}


@interface VSActivityPopover () <VSPopoverBackgroundViewDelegate>

@property (nonatomic, assign, readonly) VSActivityPopoverLayoutBits layoutBits;
@property (nonatomic, strong, readonly) NSMutableArray *menuItems;
@property (nonatomic, strong, readonly) NSString *popoverSpecifier;
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) VSPopoverBackgroundView *backgroundView;
@property (nonatomic, assign) VSDirection animationDirection;
@property (nonatomic, strong) UIColor *buttonColor;
@property (nonatomic, weak) UIView *parentView;
@property (nonatomic, weak) UIView *bar;
@property (nonatomic, strong) UIView *topBorder;
@property (nonatomic, strong) UIView *bottomBorder;

@end


@implementation VSActivityPopover


#pragma mark - Init

- (instancetype)initWithPopoverSpecifier:(NSString *)popoverSpecifier {
	
	CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
	VSActivityPopoverLayoutBits layoutBits = activityPopoverLayoutBits(app_delegate.theme, popoverSpecifier);
	CGRect frame = CGRectMake(0.0f, 0.0f, screenWidth, layoutBits.height);
	
	self = [self initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_layoutBits = layoutBits;
	_menuItems = [NSMutableArray new];
	
	self.opaque = NO;
	self.translucent = YES;
	if (layoutBits.backgroundColorAlpha > 0.001f) { /*don't bother if 0 alpha*/
		UIColor *backgroundColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"backgroundColor")];
		backgroundColor = [backgroundColor colorWithAlphaComponent:layoutBits.backgroundColorAlpha];
		self.backgroundColor = backgroundColor;
	}
	else {
		self.backgroundColor = [UIColor clearColor];
	}
	
	//UIColor *tintColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"barTintColor")];
	//tintColor = [tintColor qs_colorWithAlpha:[app_delegate.theme floatForKey:specifierPlusKey(popoverSpecifier, @"barTintColorAlpha")]];
	//self.barTintColor = tintColor;
	
	_popoverSpecifier = popoverSpecifier;
	
	self.accessibilityViewIsModal = YES;
	self.clipsToBounds = YES;
	
	UIColor *borderColor = [app_delegate.theme colorForKey:specifierPlusKey(popoverSpecifier, @"borderColor")];
	if (layoutBits.borderTop && layoutBits.borderWidth > 0.01f) {
		_topBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, layoutBits.borderWidth)];
		_topBorder.backgroundColor = borderColor;
		[self addSubview:_topBorder];
	}
	if (layoutBits.borderBottom && layoutBits.borderWidth > 0.01f) {
		_bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f, CGRectGetMaxY(frame) - layoutBits.borderWidth, frame.size.width, layoutBits.borderWidth)];
		_bottomBorder.backgroundColor = borderColor;
		[self addSubview:_bottomBorder];
	}
	
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
	
	VSActivityPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGRect r = CGRectZero;
	
	r.size.width = layoutBits.buttonWidth;
	r.size.height = layoutBits.buttonHeight;
	r.origin.y = layoutBits.padding.top;
	
	r.origin.x = layoutBits.padding.left;
	r.origin.x += layoutBits.buttonWidth * ix;
	r.origin.x += layoutBits.interButtonSpace * ix;
	
	return r;
}


- (void)layoutButtons {
	
	[self removeButtons];
	
	NSUInteger ix = 0;
	
	for (VSMenuItem *oneMenuItem in self.menuItems) {
		
		VSIconGridButton *oneButton = [[VSIconGridButton alloc] initWithFrame:[self rectForButtonAtIndex:ix] menuItem:oneMenuItem destructive:NO popoverSpecifier:self.popoverSpecifier];
		[self addSubview:oneButton];
		[self.buttons addObject:oneButton];
		ix++;
	}
	
}


- (void)addBackgroundView:(CGRect)backgroundViewRect view:(UIView *)view {
	self.backgroundView = [[VSPopoverBackgroundView alloc] initWithFrame:backgroundViewRect popoverSpecifier:self.popoverSpecifier delegate:self];
	[view addSubview:self.backgroundView];
	
}


- (void)showInView:(UIView *)view fromBehindBar:(UIView *)bar animationDirection:(VSDirection)direction {
	
	if (self.showing)
		return;
	self.showing = YES;
	
	[self addBackgroundView:[UIScreen mainScreen].bounds view:view];
	
	[view insertSubview:self belowSubview:bar];
	[view insertSubview:self.backgroundView belowSubview:self];
	
	CGRect r = bar.frame;
	r.size = [self sizeThatFits:CGSizeZero];
	
	if (direction == VSDown) {
		r.origin.y = CGRectGetMaxY(bar.frame) - r.size.height;
	}
	
	self.frame = r;
	
	[self layoutButtons];
	
	self.animationDirection = direction;
	self.parentView = view;
	self.bar = bar;
	
	[self animateIn:direction];
}


#pragma mark - Dismiss

- (void)dismiss:(VSPopoverDidDismissCallback)completion {
	
	if (!self.showing) {
		if (completion != nil)
			completion(self);
		return;
	}
	
	self.showing = NO;
	[self animateOutAndDismiss:completion];
}


#pragma mark - UIView

- (CGFloat)height {
	return self.layoutBits.height;
}


- (CGSize)sizeThatFits:(CGSize)constrainingSize {
	
#pragma unused(constrainingSize)
	
	CGSize size = CGSizeZero;
	
	CGFloat width = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
	
	if (self.superview != nil) {
		width = self.superview.bounds.size.width;
	}
	
	size.width = width;
	size.height = self.height;
	return size;
}


#pragma mark - Drawing


- (BOOL)isOpaque {
	return NO;
}


#pragma mark - Animations

- (void)animateIn:(VSDirection)direction {
	
	[self.parentView bringSubviewToFront:self.backgroundView];
	[self.parentView bringSubviewToFront:self];
	[self.parentView bringSubviewToFront:self.bar];
	
	self.backgroundView.alpha = 0.0f;
	
	CGRect rTargetFrame = self.frame;
	if (direction == VSUp)
		rTargetFrame.origin.y -= self.frame.size.height;
	else
		rTargetFrame.origin.y += self.frame.size.height;
	
	CGRect rBackgroundFrame = CGRectZero;
	rBackgroundFrame.size.width = self.frame.size.width;
	CGRect rBackgroundTargetFrame = rBackgroundFrame;
	
	if (direction == VSUp) {
		rBackgroundFrame.size.height = CGRectGetMinY(self.frame);
		rBackgroundTargetFrame.size.height = CGRectGetMinY(rTargetFrame);
	}
	else {
		rBackgroundFrame.origin.y = CGRectGetMaxY(self.frame);
		rBackgroundFrame.size.height = CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetMinY(rBackgroundFrame);
		rBackgroundTargetFrame.origin.y = CGRectGetMaxY(rTargetFrame);
		rBackgroundTargetFrame.size.height = CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetMinY(rBackgroundTargetFrame);
	}
	
	self.backgroundView.frame = rBackgroundFrame;
	
	[UIView animateWithDuration:self.layoutBits.animateInDuration animations:^{
		
		self.frame = rTargetFrame;
		self.backgroundView.frame = rBackgroundTargetFrame;
		[self.backgroundView restoreInitialAlpha];
	} completion:^(BOOL finished) {
		
		//		[self.parentView bringSubviewToFront:self];
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self);
	}];
	
}


- (void)animateOutAndDismiss:(VSPopoverDidDismissCallback)completion {
	
	[self.parentView bringSubviewToFront:self.backgroundView];
	[self.parentView bringSubviewToFront:self];
	[self.parentView bringSubviewToFront:self.bar];
	
	CGRect rTargetFrame = self.frame;
	
	if (self.animationDirection == VSDown) {
		rTargetFrame.origin.y -= self.frame.size.height;
	}
	else {
		rTargetFrame.origin.y += self.frame.size.height;
	}
	
	CGRect rBackgroundTargetFrame = self.backgroundView.frame;
	if (self.animationDirection == VSUp) {
		rBackgroundTargetFrame.size.height += CGRectGetHeight(self.frame);
	}
	else {
		rBackgroundTargetFrame.origin.y -= CGRectGetHeight(self.frame);
		rBackgroundTargetFrame.size.height += CGRectGetHeight(self.frame);
	}
	
	[UIView animateWithDuration:self.layoutBits.animateOutDuration animations:^{
		
		self.frame = rTargetFrame;
		self.backgroundView.frame = rBackgroundTargetFrame;
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


#pragma mark - Accessibility

- (BOOL)accessibilityPerformEscape {
	[self didTapPopoverBackgroundView:self.backgroundView];
	return YES;
}


@end
