//
//  VSTagPopover.m
//  Vesper
//
//  Created by Brent Simmons on 5/23/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTagPopover.h"
#import "VSTagPopoverButton.h"
#import "VSMenuItem.h"


@implementation VSTagPopover

- (CGFloat)height {
	
	VSMenuPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGFloat height = layoutBits.buttonHeight;
	height += (layoutBits.borderWidth * 2.0f);
	height += (layoutBits.chevronSize.height);
	
	return QSCeil(height);
}


- (CGFloat)width {
	
	NSUInteger ix = 0;
	
	CGRect rectOfPreviousButton = CGRectZero;
	NSUInteger numberOfMenuItems = [self.menuItems count];
	
	for (VSMenuItem *oneMenuItem in self.menuItems) {
		
		oneMenuItem.position = VSMiddle;
		if (ix == 0)
			oneMenuItem.position = VSFirst;
		else if (oneMenuItem == [self.menuItems lastObject])
			oneMenuItem.position = VSLast;
		
		if (numberOfMenuItems == 1)
			oneMenuItem.position = VSOnly;
		
		CGRect r = [self rectForButtonAtIndex:ix title:oneMenuItem.title rectOfPreviousButton:rectOfPreviousButton position:oneMenuItem.position];
		rectOfPreviousButton = r;
		
		ix++;
	}
	
	CGFloat width = CGRectGetMaxX(rectOfPreviousButton);
	width += (self.layoutBits.borderWidth * 2.0f);
	
	return QSCeil(width);
}


- (CGRect)rectForButtonAtIndex:(NSUInteger)ix title:(NSString *)title rectOfPreviousButton:(CGRect)rectOfPreviousButton position:(VSPosition)position {
	
	VSMenuPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGRect r = rectOfPreviousButton;
	r.origin.y = layoutBits.borderWidth;
	r.origin.x = CGRectGetMaxX(r);
	
	if (position == VSMiddle || position == VSLast)
		r.origin.x += layoutBits.dividerWidth;
	
	if (ix == 0)
		r.origin.x = layoutBits.borderWidth;
	
	CGFloat buttonWidth = [VSTagPopoverButton widthOfButtonWithTitle:title popoverSpecifier:self.popoverSpecifier];
	r.size.width = QSCeil(buttonWidth);
	
	r.size.height = layoutBits.buttonHeight;
	
	return r;
}


- (void)layoutButtons {
	
	/*TODO: not repeat code from -width*/
	[self removeButtons];
	
	NSUInteger ix = 0;
	
	CGRect rectOfPreviousButton = CGRectZero;
	
	NSUInteger numberOfMenuItems = [self.menuItems count];
	for (VSMenuItem *oneMenuItem in self.menuItems) {
		
		oneMenuItem.position = VSMiddle;
		if (ix == 0)
			oneMenuItem.position = VSFirst;
		else if (oneMenuItem == [self.menuItems lastObject])
			oneMenuItem.position = VSLast;
		if (numberOfMenuItems == 1)
			oneMenuItem.position = VSOnly;
		
		CGRect r = [self rectForButtonAtIndex:ix title:oneMenuItem.title rectOfPreviousButton:rectOfPreviousButton position:oneMenuItem.position];
		rectOfPreviousButton = r;
		
		VSTagPopoverButton *oneButton = [[VSTagPopoverButton alloc] initWithFrame:r menuItem:oneMenuItem destructive:(ix == self.destructiveButtonIndex) popoverSpecifier:self.popoverSpecifier];
		
		[self addSubview:oneButton];
		[self.buttons addObject:oneButton];
		ix++;
	}
}


- (CGRect)bubbleRect {
	
	VSMenuPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGRect rBubble = self.bounds;
	rBubble.size.height -= layoutBits.chevronSize.height;
	rBubble.origin.x += layoutBits.padding.left;
	rBubble.size.width = self.width;
	
	if (self.arrowOnTop)
		rBubble.origin.y += layoutBits.chevronSize.height;
	
	rBubble = CGRectInset(rBubble, layoutBits.borderCornerRadius, layoutBits.borderCornerRadius);
	
	rBubble.origin.x += 0.5f;
	rBubble.size.width -= 2.0f;
	rBubble.origin.y += 0.5f;
	rBubble.size.height -= 1.0f;
	
	return rBubble;
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
	
	r.origin.x = self.chevronPoint.x - 30.0f;
	if (r.origin.x < 10.0f)
		r.origin.x = 10.0f;
	
	while (CGRectGetMaxX(r) > (view.bounds.size.width - 10.0f))
		r.origin.x -= 10.0f;
	
	if (r.origin.x < 10.0f)
		r.origin.x = 10.0f;
	
	self.frame = r;
	
	static const CGFloat chevronSideMargin = 20.0f;
	while (self.chevronPoint.x > CGRectGetMaxX(r) - chevronSideMargin) {
		CGPoint chevronPoint = self.chevronPoint;
		chevronPoint.x -= chevronSideMargin;
		self.chevronPoint = chevronPoint;
		//        r.origin.x -= 10.0f;
	}
	
	while (self.chevronPoint.x < CGRectGetMinX(r) + chevronSideMargin) {
		CGPoint chevronPoint = self.chevronPoint;
		chevronPoint.x += chevronSideMargin;
		self.chevronPoint = chevronPoint;
		//        r.origin.x += 10.0f;
	}
	
	self.frame = r;
	
	//    CGRect rContainer = view.bounds;
	//    r = CGRectCenteredHorizontallyInRect(r, rContainer);
	
	//    while (point.x > CGRectGetMaxX(r) - 10.0f)
	//        r.origin.x += 10.0f;
	
	//    self.frame = r;
	
	[self addShadow];
	
	[self fadeIn];
}


- (void)drawRect:(CGRect)rect {
	
	[super drawRect:rect];
	UIBezierPath *path = [self popoverPath];
	
	[self.fillColor set];
	[path fill];
	[self.borderColor set];
	[path stroke];
	
	/*Draw dividers*/
	
	for (UIView *oneView in self.subviews) {
		
		VSPosition position = VSFirst;
		
		if (oneView != self.subviews[0])
			position = VSMiddle;
		if (oneView == [self.subviews lastObject])
			position = VSLast;
		
		if (position == VSLast)
			break;
		
		CGRect rDivider = oneView.frame;
		if (RSIsRetinaScreen()) {
			rDivider.origin.y += 0.5f;
			rDivider.size.height -= 1.0f;
		}
		rDivider.size.width = self.layoutBits.dividerWidth;
		rDivider.origin.x = CGRectGetMaxX(oneView.frame);
		rDivider.origin.x = QSCeil(rDivider.origin.x);
		
		UIColor *dividerColor = [app_delegate.theme colorForKey:VSThemeSpecifierPlusKey(self.popoverSpecifier, @"dividerColor")];
		[dividerColor set];
		UIRectFill(rDivider);
	}
	
}


@end
