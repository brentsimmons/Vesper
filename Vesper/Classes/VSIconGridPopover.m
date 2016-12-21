//
//  VSIconGridPopover.m
//  Vesper
//
//  Created by Brent Simmons on 5/13/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSIconGridPopover.h"
#import "VSIconGridButton.h"


@implementation VSIconGridPopover


- (CGFloat)height {
	
	VSMenuPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGFloat height = layoutBits.borderWidth + layoutBits.padding.top + layoutBits.padding.bottom + layoutBits.borderWidth + layoutBits.chevronSize.height;
	
	height += layoutBits.buttonHeight;
	
	return height;
}


- (CGFloat)width {
	
	VSMenuPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGFloat width = layoutBits.marginLeft + layoutBits.marginRight;
	width += layoutBits.padding.left + layoutBits.padding.right;
	width += [self.menuItems count] * layoutBits.buttonWidth;
	width += ([self.menuItems count] - 1) * layoutBits.interButtonSpace;
	
	return width;
}


- (CGRect)rectForButtonAtIndex:(NSUInteger)ix {
	
	VSMenuPopoverLayoutBits layoutBits = self.layoutBits;
	
	CGRect r = CGRectZero;
	
	r.origin.x = layoutBits.marginLeft + layoutBits.padding.left;
	r.origin.x += layoutBits.buttonWidth * ix;
	r.origin.x += layoutBits.interButtonSpace * ix;
	
	r.size.width = layoutBits.buttonWidth;
	
	r.origin.y = layoutBits.padding.top;
	if (self.arrowOnTop)
		r.origin.y += layoutBits.chevronSize.height;
 
	r.size.height = layoutBits.buttonHeight;
	
	return r;
}


- (void)layoutButtons {
	
	[self removeButtons];
	
	NSUInteger ix = 0;
	
	for (VSMenuItem *oneMenuItem in self.menuItems) {
		
		VSIconGridButton *oneButton = [[VSIconGridButton alloc] initWithFrame:[self rectForButtonAtIndex:ix] menuItem:oneMenuItem destructive:(ix == self.destructiveButtonIndex) popoverSpecifier:self.popoverSpecifier];
		[self addSubview:oneButton];
		[self.buttons addObject:oneButton];
		ix++;
	}
	
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
	
	CGRect rContainer = view.bounds;
	r = CGRectCenteredHorizontallyInRect(r, rContainer);
	
	while (point.x > CGRectGetMaxX(r) - 20.0f)
		r.origin.x += 20.0f;
	
	static const CGFloat minimumSideMargin = 5.0f;
	
	if (CGRectGetMaxX(r) > (view.bounds.size.width - minimumSideMargin)) {
		r.origin.x = (view.bounds.size.width - minimumSideMargin) - r.size.width;
		point.x -= 5.0f;
		self.chevronPoint = point;
	}
	
	if (r.origin.x < minimumSideMargin)
		r.origin.x = minimumSideMargin;
	
	self.frame = r;
	
	[self addShadow];
	
	[self fadeIn];
}


@end
