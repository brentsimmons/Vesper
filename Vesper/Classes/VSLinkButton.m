//
//  VSLinkButton.m
//  Vesper
//
//  Created by Brent Simmons on 4/25/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSLinkButton.h"


@implementation VSLinkButton


+ (UIButton *)linkButtonWithTitle:(NSString *)title {

	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

	UIFont *font = [app_delegate.theme fontForKey:@"linkButton.font"];
	if (VSDefaultsUsingLightText()) {
		font = [app_delegate.theme fontForKey:@"linkButton.fontLight"];
	}
	UIColor *color = [app_delegate.theme colorForKey:@"linkButton.color"];
	UIColor *colorPressed = [app_delegate.theme colorForKey:@"linkButton.colorPressed"];

	NSDictionary *atts = @{NSForegroundColorAttributeName: color, NSFontAttributeName : font, NSUnderlineStyleAttributeName : @(NO)};
	NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:atts];
	atts = @{NSForegroundColorAttributeName : colorPressed, NSFontAttributeName : font, NSUnderlineStyleAttributeName : @(NO)};
	NSMutableAttributedString *buttonTitlePressed = [[NSMutableAttributedString alloc] initWithString:title attributes:atts];

	[button setAttributedTitle:buttonTitle forState:UIControlStateNormal];
	[button setAttributedTitle:buttonTitlePressed forState:UIControlStateSelected];
	[button setAttributedTitle:buttonTitlePressed forState:UIControlStateHighlighted];

	button.adjustsImageWhenHighlighted = NO;
	button.adjustsImageWhenDisabled = NO;

	[button sizeToFit];
	
	return button;
}



@end
