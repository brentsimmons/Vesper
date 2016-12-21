//
//  VSUI.h
//  Vesper
//
//  Created by Brent Simmons on 4/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@class VSDescriptionView;


@interface VSUI : NSObject


+ (UITextField *)groupedTableTextField:(BOOL)secure placeholder:(NSString *)placeholder;

+ (void)configureGroupedTableLabel:(UILabel *)label labelText:(NSString *)labelText;

+ (void)configureGroupedTableCell:(UITableViewCell *)cell;

+ (void)layoutGroupedTableLabel:(UILabel *)label labelWidth:(CGFloat)labelWidth contentView:(UIView *)contentView;

+ (void)layoutGroupedTableRightView:(UIView *)view originX:(CGFloat)originX marginRight:(CGFloat)marginRight contentView:(UIView *)contentView;

+ (void)layoutGroupedTableSwitch:(UISwitch *)switchView marginRight:(CGFloat)marginRight contentView:(UIView *)contentView;

+ (void)configureGroupedTableButtonCell:(UITableViewCell *)cell labelText:(NSString *)labelText destructive:(BOOL)destructive textAlignment:(NSTextAlignment)textAlignment;

+ (UINavigationController *)navigationControllerWithViewController:(UIViewController *)rootViewController;

+ (UILabel *)groupedTableDescriptionLabel:(NSString *)text;

+ (VSDescriptionView *)headerViewForTable:(UITableView *)tableView text:(NSString *)text;


typedef NS_ENUM(NSUInteger, VSShowHideButtonState) {
	VSShow,
	VSHide
};

+ (UIButton *)showHideButton;
+ (void)updateShowHideButton:(UIButton *)button state:(VSShowHideButtonState)state;


+ (void)configureNavbar:(UINavigationBar *)navbar;


@end
