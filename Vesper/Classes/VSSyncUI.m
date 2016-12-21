//
//  VSSyncUI.m
//  Vesper
//
//  Created by Brent Simmons on 4/25/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSyncUI.h"
#import "VSBasicWebViewController.h"
#import "VSLinkButton.h"
#import "VSSyncContainerViewController.h"
#import "VSUI.h"


NSString *VSSyncUIShowingNotification = @"VSSyncUIShowingNotification";


@implementation VSSyncUI


+ (VSBasicWebViewController *)privacyPolicyViewController {

	NSString *urlString = [app_delegate.theme stringForKey:@"syncUI.privacyPolicyURL"];
	NSString *resourceName = [app_delegate.theme stringForKey:@"syncUI.privacyPolicyFilename"];

	VSBasicWebViewController *viewController = [[VSBasicWebViewController alloc] initWithURL:[NSURL URLWithString:urlString] fallbackResourceName:resourceName title:NSLocalizedString(@"Privacy Policy", @"Privacy Policy")];

	return viewController;
}


+ (VSBasicWebViewController *)modalPrivacyPolicyViewController {

	VSBasicWebViewController *viewController = [self privacyPolicyViewController];
	viewController.hasCloseButton = YES;
	return viewController;
}


+ (UIButton *)addPrivacyPolicyButtonToView:(UIView *)view {

	UIButton *button = [VSLinkButton linkButtonWithTitle:NSLocalizedString(@"Privacy Policy", @"Privacy Policy")];
	[view addSubview:button];
	[button sizeToFit];

	return button;
}


+ (VSBasicWebViewController *)faqViewController {

	NSString *urlString = [app_delegate.theme stringForKey:@"syncUI.faqURL"];
	NSString *resourceName = [app_delegate.theme stringForKey:@"syncUI.faqFilename"];

	VSBasicWebViewController *viewController = [[VSBasicWebViewController alloc] initWithURL:[NSURL URLWithString:urlString] fallbackResourceName:resourceName title:NSLocalizedString(@"Questions", @"Questions")];

	return viewController;
}


+ (VSBasicWebViewController *)modalFaqViewController {

	VSBasicWebViewController *viewController = [self faqViewController];
	viewController.hasCloseButton = YES;
	return viewController;
}


+ (UIButton *)addFAQButtonToView:(UIView *)view {

//	UIButton *button = [VSLinkButton linkButtonWithTitle:NSLocalizedString(@"Frequently Asked Questions", @"Frequently Asked Questions")];
	UIButton *button = [VSLinkButton linkButtonWithTitle:NSLocalizedString(@"Privacy Policy", @"Privacy Policy")];
	[view addSubview:button];
	[button sizeToFit];

	return button;
}


+ (void)layoutCenteredButton:(UIButton *)button view:(UIView *)view marginBottom:(CGFloat)marginBottom {

	CGRect rButton = button.frame;
	rButton.origin.y = CGRectGetMaxY(view.bounds) - (CGRectGetHeight(rButton) + marginBottom);
	rButton = CGRectCenteredHorizontallyInRect(rButton, view.bounds);
	[button qs_setFrameIfNotEqual:rButton];
}


+ (void)layoutPrivacyPolicyButton:(UIButton *)button view:(UIView *)view {

	CGFloat marginBottom = [app_delegate.theme floatForKey:@"syncUI.privacyPolicyButtonMarginBottom"];
	[self layoutCenteredButton:button view:view marginBottom:marginBottom];
}


+ (void)layoutFAQButton:(UIButton *)button view:(UIView *)view {

	CGFloat marginBottom = [app_delegate.theme floatForKey:@"syncUI.faqButtonMarginBottom"];
	[self layoutCenteredButton:button view:view marginBottom:marginBottom];
}


+ (UINavigationController *)initialController {

	VSSyncContainerViewController *containerViewController = [VSSyncContainerViewController new];
	UINavigationController *navigationController = [VSUI navigationControllerWithViewController:containerViewController];
	navigationController.navigationBarHidden = YES;

	return navigationController;
}


+ (UILabel *)descriptionLabel {

	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
	label.font = [app_delegate.theme fontForKey:@"groupedTable.descriptionFont"];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.numberOfLines = 0;
	
	return label;
}


+ (UITableView *)tableView {

	CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, screenWidth, 200.0) style:UITableViewStyleGrouped];
	tableView.backgroundColor = [app_delegate.theme colorForKey:@"syncUI.backgroundColor"];
	tableView.opaque = YES;
	tableView.scrollEnabled = NO;
	tableView.scrollsToTop = NO;

	return tableView;
}


+ (UITableView *)tableViewForViewController:(UIViewController *)viewController {

	UITableView *tableView = [self tableView];

	tableView.delegate = (id<UITableViewDelegate>)viewController;
	tableView.dataSource = (id<UITableViewDataSource>)viewController;

	[viewController.view addSubview:tableView];
	
	return tableView;
}


+ (UIView *)view {

	UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	view.backgroundColor = [app_delegate.theme colorForKey:@"syncUI.backgroundColor"];

	return view;
}


+ (void)layoutTableView:(UITableView *)tableView view:(UIView *)view themeSpecifier:(NSString *)themeSpecifier {

	CGRect r = view.bounds;

	r.origin = CGPointZero;
	r.origin.y = [app_delegate.theme floatForKey:[themeSpecifier stringByAppendingString:@".tableOffsetY"]];
	r.size.height = [app_delegate.theme floatForKey:[themeSpecifier stringByAppendingString:@".tableHeight"]];

	[tableView qs_setFrameIfNotEqual:r];
}


+ (void)sendSyncUIShowingNotification {

	[[NSNotificationCenter defaultCenter] postNotificationName:VSSyncUIShowingNotification object:nil];
}



@end
