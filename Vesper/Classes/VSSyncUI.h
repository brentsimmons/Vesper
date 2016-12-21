//
//  VSSyncUI.h
//  Vesper
//
//  Created by Brent Simmons on 4/25/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@class VSBasicWebViewController;


extern NSString *VSSyncUIShowingNotification;


@interface VSSyncUI : UIButton


+ (VSBasicWebViewController *)privacyPolicyViewController;
+ (VSBasicWebViewController *)modalPrivacyPolicyViewController; /*Has Cancel button*/

+ (VSBasicWebViewController *)faqViewController;
+ (VSBasicWebViewController *)modalFaqViewController; /*Has Cancel button*/

+ (UIButton *)addPrivacyPolicyButtonToView:(UIView *)view;

+ (UIButton *)addFAQButtonToView:(UIView *)view;

+ (void)layoutPrivacyPolicyButton:(UIButton *)button view:(UIView *)view;

+ (void)layoutFAQButton:(UIButton *)button view:(UIView *)view;

+ (UINavigationController *)initialController; /*Navigation controller that contains the first screen you see when you tap the Sync button.*/

+ (UILabel *)descriptionLabel;

+ (UITableView *)tableView; /*Grouped*/

+ (UITableView *)tableViewForViewController:(UIViewController *)viewController;

+ (UIView *)view; /*Sets background color.*/

+ (void)layoutTableView:(UITableView *)tableView view:(UIView *)view themeSpecifier:(NSString *)themeSpecifier;

+ (void)sendSyncUIShowingNotification;


@end
