//
//  VSUI.m
//  Vesper
//
//  Created by Brent Simmons on 4/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSUI.h"
#import "VSDescriptionView.h"
#import "VSProgressView.h"
#import "VSSyncContainerViewController.h"


@interface VSNavigationController : UINavigationController

@end

@implementation VSUI

+ (UIFont *)groupedTableLabelFont {
	
	UIFont *font = [app_delegate.theme fontForKey:@"groupedTable.labelFont"];
	if (VSDefaultsUsingLightText()) {
		font = [app_delegate.theme fontForKey:@"groupedTable.labelFontLight"];
	}
	
	return font;
}

+ (UITextField *)groupedTableTextField:(BOOL)secure placeholder:(NSString *)placeholder {
	
	UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
	textField.opaque = NO;
	textField.backgroundColor = [UIColor clearColor];
	textField.font = [self groupedTableLabelFont];
	textField.secureTextEntry = secure;
	textField.textColor = [app_delegate.theme colorForKey:@"groupedTable.textFieldFontColor"];
	textField.placeholder = placeholder;
	[textField sizeToFit];
	
	textField.contentMode = UIViewContentModeRedraw;
	
	return textField;
}


+ (void)configureGroupedTableLabel:(UILabel *)label labelText:(NSString *)labelText {
	
	label.backgroundColor = [UIColor clearColor];
	label.opaque = NO;
	label.font = [self groupedTableLabelFont];
	label.textColor = [app_delegate.theme colorForKey:@"groupedTable.labelFontColor"];
	
	NSAttributedString *attString = [NSAttributedString qs_attributedStringWithText:labelText font:label.font color:label.textColor kerning:YES];
	label.attributedText = attString;
	
	label.contentMode = UIViewContentModeRedraw;
	[label sizeToFit];
}


+ (void)configureGroupedTableCell:(UITableViewCell *)cell {
	
	cell.contentMode = UIViewContentModeRedraw;
	cell.opaque = YES;
	
	cell.contentView.backgroundColor = [app_delegate.theme colorForKey:@"groupedTable.cellBackgroundColor"];
	cell.contentView.opaque = YES;
	
	cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	cell.backgroundView.backgroundColor = cell.contentView.backgroundColor;
	cell.backgroundView.opaque = YES;
}


+ (UIFont *)groupedTableButtonFont {
	
	UIFont *font = [app_delegate.theme fontForKey:@"groupedTable.buttonFont"];
	if (VSDefaultsUsingLightText()) {
		font = [app_delegate.theme fontForKey:@"groupedTable.buttonFontLight"];
	}
	
	return font;
}


+ (void)configureGroupedTableButtonCell:(UITableViewCell *)cell labelText:(NSString *)labelText destructive:(BOOL)destructive textAlignment:(NSTextAlignment)textAlignment {
	
	[self configureGroupedTableCell:cell];
	
	cell.textLabel.textAlignment = textAlignment;
	cell.textLabel.font = [self groupedTableButtonFont];
	cell.textLabel.textColor = [app_delegate.theme colorForKey:@"groupedTable.buttonFontColor"];
	if (destructive) {
		cell.textLabel.textColor = [app_delegate.theme colorForKey:@"groupedTable.buttonDestructiveFontColor"];
	}
	
	NSAttributedString *attString = [NSAttributedString qs_attributedStringWithText:labelText font:cell.textLabel.font color:cell.textLabel.textColor kerning:YES];
	cell.textLabel.attributedText = attString;
}


+ (void)layoutGroupedTableLabel:(UILabel *)label labelWidth:(CGFloat)labelWidth contentView:(UIView *)contentView {
	
	CGRect rBounds = contentView.bounds;
	
	CGFloat textOriginX = [app_delegate.theme floatForKey:@"groupedTable.labelMarginLeft"];
	CGFloat textWidth = labelWidth;
	CGFloat textHeight = CGRectGetHeight(label.frame);
	
	CGRect r = CGRectMake(textOriginX, 0.0, textWidth, textHeight);
	r = CGRectCenteredVerticallyInRect(r, rBounds);
	r = CGRectIntegral(r);
	r.size.height = textHeight;
	[label qs_setFrameIfNotEqual:r];
}


+ (void)layoutGroupedTableRightView:(UIView *)view originX:(CGFloat)originX marginRight:(CGFloat)marginRight contentView:(UIView *)contentView {
	
	CGRect rBounds = contentView.bounds;
	
	CGRect r = view.bounds;
	r.origin.x = originX;
	r.size.width = CGRectGetMaxX(rBounds) - (r.origin.x + marginRight);
	r.size.height = CGRectGetHeight(view.bounds);
	r = CGRectCenteredVerticallyInRect(r, rBounds);
	r = CGRectIntegral(r);
	r.size.height = CGRectGetHeight(view.bounds);
	
	[view qs_setFrameIfNotEqual:r];
}


+ (void)layoutGroupedTableSwitch:(UISwitch *)switchView marginRight:(CGFloat)marginRight contentView:(UIView *)contentView {
	
	CGRect rBounds = contentView.bounds;
	
	CGRect r = switchView.bounds;
	r.origin.x = CGRectGetMaxX(rBounds) - (CGRectGetWidth(switchView.bounds) + marginRight);
	r = CGRectCenteredVerticallyInRect(r, rBounds);
	r = CGRectIntegral(r);
	r.size = switchView.bounds.size;
	
	[switchView qs_setFrameIfNotEqual:r];
}


+ (UINavigationController *)navigationControllerWithViewController:(UIViewController *)rootViewController {
	
	UINavigationController *controller = [[VSNavigationController alloc] initWithRootViewController:rootViewController];
	controller.navigationBar.tintColor = [app_delegate.theme colorForKey:@"navbarTextButtonColor"];
	controller.navigationBar.barTintColor = [app_delegate.theme colorForKey:@"navbarBackgroundColor"];
	controller.navigationBar.translucent = NO;
	
	UIColor *titleColor = [app_delegate.theme colorForKey:@"navbarTitleColor"];
	UIFont *font = [app_delegate.theme fontForKey:@"navbarTitleFont"];
	if (VSDefaultsTextWeight() == VSTextWeightLight) {
		font = [app_delegate.theme fontForKey:@"navbarTitleLightFont"];
	}
	
	controller.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : titleColor, NSFontAttributeName: font};
	
	UIFont *textButtonFont = [app_delegate.theme fontForKey:@"navbarBackButtonFont"];
	if (VSDefaultsTextWeight() == VSTextWeightLight) {
		textButtonFont = [app_delegate.theme fontForKey:@"navbarBackButtonLightFont"];
	}
	
	NSDictionary *barButtonAppearance = @{NSForegroundColorAttributeName: [app_delegate.theme colorForKey:@"navbarTextButtonColor"], NSFontAttributeName : textButtonFont};
	[[UIBarButtonItem appearanceWhenContainedIn:[VSNavigationController class], nil] setTitleTextAttributes:barButtonAppearance forState:UIControlStateNormal];
	
	UIImage *backButtonImage = [UIImage imageNamed:@"chevron"];
	CGSize imageSize = backButtonImage.size;
	backButtonImage = [backButtonImage resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, imageSize.height, 0.0, 0.0)];
	backButtonImage = [backButtonImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[[UIBarButtonItem appearanceWhenContainedIn:[VSNavigationController class], nil] setBackButtonBackgroundImage:backButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
	
	CGFloat titleOffsetHorizontal = [app_delegate.theme floatForKey:@"realNavbarBackButtonTextOffsetX"];
	CGFloat titleOffsetVertical = [app_delegate.theme floatForKey:@"realNavbarBackButtonTextOffsetY"];
	[[UIBarButtonItem appearanceWhenContainedIn:[VSNavigationController class], nil] setBackButtonTitlePositionAdjustment:UIOffsetMake(titleOffsetHorizontal, titleOffsetVertical) forBarMetrics:UIBarMetricsDefault];
	
	return controller;
}


+ (UIFont *)groupedTableDescriptionLabelFont {
	
	UIFont *font = [app_delegate.theme fontForKey:@"groupedTable.descriptionFont"];
	if (VSDefaultsUsingLightText()) {
		font = [app_delegate.theme fontForKey:@"groupedTable.descriptionFontLight"];
	}
	
	return font;
}


+ (UILabel *)groupedTableDescriptionLabel:(NSString *)text {
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
	label.font = [self groupedTableDescriptionLabelFont];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.numberOfLines = 0;
	
	UIColor *color = [app_delegate.theme colorForKey:@"groupedTable.descriptionFontColor"];
	NSAttributedString *attString = [NSAttributedString qs_attributedStringWithText:text font:label.font color:color kerning:YES];
	label.attributedText = attString;
	
	return label;
}


+ (UIFont *)groupedTableHeaderFont {
	
	UIFont *font = [app_delegate.theme fontForKey:@"groupedTable.headerFont"];
	if (VSDefaultsUsingLightText()) {
		font = [app_delegate.theme fontForKey:@"groupedTable.headerFontLight"];
	}
	
	return font;
}


+ (VSDescriptionView *)headerViewForTable:(UITableView *)tableView text:(NSString *)text {
	
	VSDescriptionView *headerView = [[VSDescriptionView alloc] initWithText:text edgeInsets:[app_delegate.theme edgeInsetsForKey:@"groupedTable.headerMargin"]];
	
	headerView.label.font = [self groupedTableHeaderFont];
	headerView.label.textColor = [app_delegate.theme colorForKey:@"groupedTable.headerFontColor"];
	
	text = [app_delegate.theme string:text transformedWithTextCaseTransformKey:@"groupedTable.headerTextTransform"];
	headerView.label.text = text;
	
	return headerView;
}


+ (NSAttributedString *)showHideButtonAttributedTitleForText:(NSString *)s pressed:(BOOL)pressed {
	
	UIFont *font = [app_delegate.theme fontForKey:@"groupedTable.showHideButtonFont"];
	UIColor *color = [app_delegate.theme colorForKey:@"groupedTable.showHideButtonFontColor"];
	if (pressed) {
		color = [app_delegate.theme colorForKey:@"groupedTable.showHideButtonPressedFontColor"];
		CGFloat alpha = [app_delegate.theme floatForKey:@"groupedTable.showHideButtonPressedAlpha"];
		color = [color colorWithAlphaComponent:alpha];
	}
	
	return [NSAttributedString qs_attributedStringWithText:s font:font color:color kerning:YES];
}


+ (UIButton *)showHideButton {
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[self updateShowHideButton:button state:VSShow];
	
	button.contentMode = UIViewContentModeCenter;
	[button sizeToFit];
	CGRect rButton = button.frame;
	rButton.size.width += [app_delegate.theme floatForKey:@"groupedTable.showHideButtonPaddingLeft"];
	rButton.size.width += [app_delegate.theme floatForKey:@"groupedTable.showHideButtonPaddingRight"];
	button.frame = rButton;
	
	return button;
}


+ (void)updateShowHideButton:(UIButton *)button withText:(NSString *)s {
	
	NSAttributedString *title = [self showHideButtonAttributedTitleForText:s pressed:NO];
	NSAttributedString *titlePressed = [self showHideButtonAttributedTitleForText:s pressed:YES];
	
	[button setAttributedTitle:title forState:UIControlStateNormal];
	[button setAttributedTitle:titlePressed forState:UIControlStateHighlighted];
	[button setAttributedTitle:titlePressed forState:UIControlStateSelected];
}


+ (void)updateShowHideButton:(UIButton *)button state:(VSShowHideButtonState)state {
	
	if (state == VSShow) {
		[self updateShowHideButton:button withText:NSLocalizedString(@"SHOW", nil)];
	}
	else {
		[self updateShowHideButton:button withText:NSLocalizedString(@"HIDE", nil)];
	}
}


+ (void)configureNavbar:(UINavigationBar *)navbar {
	
	UIColor *titleColor = [app_delegate.theme colorForKey:@"navbarTitleColor"];
	UIFont *font = [app_delegate.theme fontForKey:@"navbarTitleFont"];
	if (VSDefaultsTextWeight() == VSTextWeightLight)
		font = [app_delegate.theme fontForKey:@"navbarTitleLightFont"];
	navbar.titleTextAttributes = @{NSForegroundColorAttributeName : titleColor, NSFontAttributeName: font};
	navbar.barTintColor = [app_delegate.theme colorForKey:@"navbarBackgroundColor"];
}

@end



@implementation VSNavigationController


@end

