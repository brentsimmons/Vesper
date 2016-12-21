//
//  VSTimelineCellButtonContainer.m
//  Vesper
//
//  Created by Brent Simmons on 8/11/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTimelineCellButtonContainer.h"


@interface VSTimelineCellButtonContainer ()

@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, assign) CGFloat buttonWidth;
@property (nonatomic, assign, readwrite) CGFloat widthOfButtons;
@end


@implementation VSTimelineCellButtonContainer


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame buttons:(NSArray *)buttons themeSpecifier:(NSString *)themeSpecifier {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_buttons = buttons;
	_buttonWidth = [app_delegate.theme floatForKey:VSThemeSpecifierPlusKey(themeSpecifier, @"buttonWidth")];
	self.backgroundColor = [app_delegate.theme colorForKey:VSThemeSpecifierPlusKey(themeSpecifier, @"backgroundColor")];
	self.backgroundColor = [UIColor redColor];
	
	_widthOfButtons = [buttons count] * _buttonWidth;
	
	for (UIButton *oneButton in _buttons) {
		[self addSubview:oneButton];
	}
	
	[self setNeedsLayout];
	
	return self;
}


#pragma mark - UIView

- (void)layoutSubviews {
	
	[self.buttons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		UIButton *oneButton = (UIButton *)obj;
		
		CGRect r = CGRectZero;
		r.size.height = self.bounds.size.height;
		r.size.width = self.buttonWidth;
		r.origin.y = 0.0f;
		
		CGFloat startX = CGRectGetMaxX(self.bounds) - self.widthOfButtons;
		r.origin.x = startX + (idx * self.buttonWidth);
		
		oneButton.frame = r;
		
	}];
}


@end
