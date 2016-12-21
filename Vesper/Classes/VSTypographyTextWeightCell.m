//
//  VSTypographyTextWeightCell.m
//  Vesper
//
//  Created by Brent Simmons on 8/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTypographyTextWeightCell.h"


@implementation VSTypographyTextWeightCell


#pragma mark - Init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier text:(NSString *)text {
	
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self == nil)
		return nil;
	
	self.contentMode = UIViewContentModeRedraw;
	self.opaque = YES;
	
	self.textLabel.backgroundColor = [UIColor clearColor];
	self.textLabel.opaque = NO;
	
	UIFont *font = [app_delegate.theme fontForKey:@"typographyScreen.cellFont"];
	UIColor *color = [app_delegate.theme colorForKey:@"typographyScreen.cellTextColor"];
	NSAttributedString *attString = [NSAttributedString qs_attributedStringWithText:text font:font color:color kerning:YES];
	self.textLabel.attributedText = attString;
	
	self.contentView.backgroundColor = [app_delegate.theme colorForKey:@"typographyScreen.cellBackgroundColor"];
	self.contentView.opaque = YES;
	
	self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	self.backgroundView.backgroundColor = self.contentView.backgroundColor;
	self.backgroundView.opaque = YES;
	
	[self setNeedsLayout];
	
	return self;
}


#pragma mark - UIView

- (void)layoutSubviews {
	
	[super layoutSubviews];
	
	CGRect r = self.textLabel.frame;
	r.origin.x = [app_delegate.theme floatForKey:@"typographyScreen.cellTextOriginX"];
	r.origin.y = [app_delegate.theme floatForKey:@"typographyScreen.textWeightTextOriginY"];
	
	[self.textLabel qs_setFrameIfNotEqual:r];
	
	if (self.accessoryView != nil) {
		
		CGRect rAccessory = self.bounds;
		rAccessory.origin.y = 0.0f;
		rAccessory.size.width = [app_delegate.theme floatForKey:@"typographyScreen.textWeightCheckmarkViewWidth"];
		rAccessory.origin.x = CGRectGetMaxX(self.bounds) - CGRectGetWidth(rAccessory);
		
		[self.accessoryView qs_setFrameIfNotEqual:rAccessory];
	}
}


#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
	return YES;
}


- (NSString *)accessibilityValue
{
	return (self.accessoryView == nil) ? nil : NSLocalizedString(@"Selected", nil);
}


@end
