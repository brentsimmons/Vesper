//
//  VSSyncNoAccountViewController.m
//  Vesper
//
//  Created by Brent Simmons on 2/7/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSyncNoAccountViewController.h"
#import "VSBasicWebViewController.h"
#import "VSSyncUI.h"
#import "VSSyncNoAccountHeaderView.h"
#import "VSSyncCreateAccountViewController.h"
#import "VSSyncSignInViewController.h"
#import "VSUI.h"
#import "VSNavbarView.h"
#import "VSLinkButtonFooterView.h"


@interface VSSyncNoAccountViewController () <UITableViewDataSource, UITableViewDelegate, VSLinkButtonFooterViewDelegate>

@property (nonatomic) VSSyncNoAccountHeaderView *headerView;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) VSNavbarView *navbar;
@property (nonatomic) VSLinkButtonFooterView *footerView;

@end

static const NSInteger kNumberOfRowsPerSection = 1;
#if SYNC_TRANSITION
static const NSInteger kNumberOfSections = 1;
#else
static const NSInteger kNumberOfSections = 2;
static const NSInteger kCreateAccountSection = 0;
static const NSInteger kSignInSection = 1;
#endif

static void *VSSidebarShowingContext = &VSSidebarShowingContext;


@implementation VSSyncNoAccountViewController


#pragma mark - Init

- (instancetype)init {
	
	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}
	
	[(id)app_delegate addObserver:self forKeyPath:VSSidebarShowingKey options:0 context:VSSidebarShowingContext];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[(id)app_delegate removeObserver:self forKeyPath:VSSidebarShowingKey context:VSSidebarShowingContext];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if (context == VSSidebarShowingContext) {
		self.tableView.scrollEnabled = !app_delegate.sidebarShowing;
	}
}


#pragma mark - UIViewController

- (void)loadView {
	
	self.view = [VSSyncUI view];
	self.tableView = [VSSyncUI tableViewForViewController:self];
	self.tableView.scrollEnabled = !app_delegate.sidebarShowing;
	[self.view addSubview:self.tableView];
	
	self.headerView = [[VSSyncNoAccountHeaderView alloc] initWithFrame:CGRectZero];
	CGRect rHeader = CGRectZero;
	rHeader.size.width = CGRectGetWidth([UIScreen mainScreen].bounds);
	CGSize bestSize = [self.headerView sizeThatFits:CGSizeMake(CGRectGetWidth(rHeader), CGFLOAT_MAX)];
	rHeader.size.height = bestSize.height;
	self.headerView.frame = rHeader;
	self.tableView.tableHeaderView = self.headerView;
	
	self.navbar = [VSNavbarView new];
	self.navbar.showComposeButton = NO;
	self.navbar.frame = RSNavbarRect();
	self.navbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
	self.navbar.title = NSLocalizedString(@"Sync", nil);
	[self.view addSubview:self.navbar];
	
	self.footerView = [[VSLinkButtonFooterView alloc] initWithText:@"Privacy Policy" delegate:self];
	self.tableView.tableFooterView = self.footerView;
}


- (void)viewDidLayoutSubviews {
	
	CGRect rNavbar = RSNavbarRect();
	[self.navbar qs_setFrameIfNotEqual:rNavbar];
	
	//	CGRect rHeader = self.view.bounds;
	//	rHeader.origin.x = 0.0;
	//	rHeader.origin.y = CGRectGetMaxY(rNavbar);
	//	CGSize bestSize = [self.headerView sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.bounds), CGFLOAT_MAX)];
	//	rHeader.size.height = bestSize.height;
	//	[self.headerView qs_setFrameIfNotEqual:rHeader];
	//
	CGRect rTable = CGRectZero;
	rTable.origin = CGPointZero;
	rTable.origin.y = CGRectGetMaxY(rNavbar);
	rTable.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(rNavbar);
	rTable.size.width = CGRectGetWidth(self.view.bounds);
	[self.tableView qs_setFrameIfNotEqual:rTable];
}


- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	NSIndexPath *selectedRowIndexPath = [self.tableView indexPathForSelectedRow];
	if (!selectedRowIndexPath) {
		return;
	}
	
	[self.tableView deselectRowAtIndexPath:selectedRowIndexPath animated:animated];
}


#pragma mark - VSLinkButtonFooterViewDelegate

- (void)linkButtonFooterViewTapped:(VSLinkButtonFooterView *)linkButtonFooterView {
	
	[self showPrivacyPolicy:linkButtonFooterView];
}


#pragma mark - Actions

- (void)showPrivacyPolicy:(id)sender {
	
#if USE_SAFARI_VIEW_CONTROLLER
	NSString *urlString = [app_delegate.theme stringForKey:@"syncUI.privacyPolicyURL"];
	NSURL *url = [NSURL URLWithString:urlString];
	[app_delegate openURL:url];
#else
	[self presentModalViewController:[VSSyncUI modalPrivacyPolicyViewController]];
	//	[self.navigationController pushViewController:[VSSyncUI privacyPolicyViewController] animated:YES];
#endif
}


#pragma mark - View Controllers

- (void)presentCreateAccountViewController {
	
#if !SYNC_TRANSITION
	[self presentModalViewController:[VSSyncCreateAccountViewController new]];
#endif
}


- (void)presentSignInViewController {
	
	if (VSSyncIsShutdown()) {
		return;
	}
	[self presentModalViewController:[VSSyncSignInViewController new]];
}


- (void)presentModalViewController:(UIViewController *)viewController {
	
	UINavigationController *navigationController = [VSUI navigationControllerWithViewController:viewController];
	navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	
	[self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (VSSyncIsShutdown()) {
		return 0;
	}
	return kNumberOfRowsPerSection;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	if (VSSyncIsShutdown()) {
		return 0;
	}
	return kNumberOfSections;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	
#if SYNC_TRANSITION
	NSString *labelText = NSLocalizedString(@"Sign In to an Existing Account", @"Sign In to an Existing Account");
#else
	NSString *labelText = NSLocalizedString(@"Create Account", @"Create Account");
	if (indexPath.section == kSignInSection) {
		labelText = NSLocalizedString(@"Sign In to an Existing Account", @"Sign In to an Existing Account");
	}
#endif
	
	[VSUI configureGroupedTableButtonCell:cell labelText:labelText destructive:NO textAlignment:NSTextAlignmentCenter];
	
	return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
#if SYNC_TRANSITION
	if (!VSSyncIsShutdown()) {
		[self presentSignInViewController];
	}
#else
	if (indexPath.section == kCreateAccountSection) {
		[self presentCreateAccountViewController];
	}
	else if (indexPath.section == kSignInSection) {
		[self presentSignInViewController];
	}
#endif
}


@end
