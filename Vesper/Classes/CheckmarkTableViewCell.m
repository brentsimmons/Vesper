//
//  CheckmarkTableViewCell.m
//  Vesper
//
//  Created by Brent Simmons on 9/19/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "CheckmarkTableViewCell.h"
#import "VSUI.h"


@implementation CheckmarkTableViewCell


- (id)initWithLabel:(NSString *)label {

	self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	if (!self) {
		return nil;
	}

	[VSUI configureGroupedTableCell:self];

	[VSUI configureGroupedTableLabel:self.textLabel labelText:label];

	return self;
}


#pragma mark - UIView

- (void)layoutSubviews {

	[super layoutSubviews];

	CGSize labelSize = [self.textLabel sizeThatFits:self.bounds.size];
	[VSUI layoutGroupedTableLabel:self.textLabel labelWidth:labelSize.width contentView:self.contentView];

	if (self.accessoryView != nil) {

		CGRect rAccessory = self.bounds;
		rAccessory.origin.y = 0.0f;
		rAccessory.size.width = [app_delegate.theme floatForKey:@"typographyScreen.textWeightCheckmarkViewWidth"];
		rAccessory.origin.x = CGRectGetMaxX(self.bounds) - CGRectGetWidth(rAccessory);

		[self.accessoryView qs_setFrameIfNotEqual:rAccessory];
	}
}


#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {

	return YES;
}


- (NSString *)accessibilityValue {

	return (self.accessoryView == nil) ? nil : NSLocalizedString(@"Selected", nil);
}

@end
