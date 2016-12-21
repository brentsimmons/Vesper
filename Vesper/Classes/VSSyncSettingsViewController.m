//
//  VSSyncSettingsViewController.m
//  Vesper
//
//  Created by Brent Simmons on 2/7/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSyncSettingsViewController.h"
#import "VSSyncUI.h"
#import "VSBasicWebViewController.h"
#import "VSUI.h"
#import "VSLabelSwitchTableViewCell.h"
#import "VSDescriptionView.h"
#import "VSSyncChangePasswordViewController.h"
#import "VSGroupedTableButtonViewCell.h"
#import "VSNavbarView.h"
#import "VSLinkButtonFooterView.h"


@interface VSSyncSettingsViewController () <UITableViewDelegate, UITableViewDataSource, VSLinkButtonFooterViewDelegate>

@property (nonatomic) VSLabelSwitchTableViewCell *emailUpdatesCell;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) VSDescriptionView *lastSyncDescriptionView;
@property (nonatomic) VSDescriptionView *emailUpdatesDescriptionView;
@property (nonatomic) VSDescriptionView *sectionHeaderView;
@property (nonatomic) UITableViewCell *deleteAccountCell;
@property (nonatomic) UITableViewCell *changePasswordCell;
@property (nonatomic) VSGroupedTableButtonViewCell *logOutCell;
@property (nonatomic) VSNavbarView *navbar;
@property (nonatomic) BOOL loggingOut;
@property (nonatomic) VSLinkButtonFooterView *footerView;

@end


@implementation VSSyncSettingsViewController


typedef NS_ENUM(NSUInteger, VSSettingsSection) {
	VSSectionChangePasswordLogOut,
	VSSectionEmailUpdates,
	VSSectionDeleteAccount
};

typedef NS_ENUM(NSUInteger, VSChangePasswordLogOutRow) {
	VSRowChangePassword,
	VSRowLogOut
};

static const NSInteger kNumberOfSections = 2;
static void *emailUpdatesContext = &emailUpdatesContext;
static void *VSLastSyncDateContext = &VSLastSyncDateContext;
static void *loggingOutContext = &loggingOutContext;
static void *VSTypographySidebarShowingContext = &VSTypographySidebarShowingContext;
static NSString *VSLastSyncDateKey = @"lastSyncDate";
static NSString *VSEmailUpdatesKey = @"emailUpdates";
static NSString *VSLoggingOutKey = @"loggingOut";


#pragma mark - Init

- (instancetype)init {
	
	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}
	
	[[VSAccount account] addObserver:self forKeyPath:VSEmailUpdatesKey options:0 context:emailUpdatesContext];
	[[VSAccount account] addObserver:self forKeyPath:VSLastSyncDateKey options:0 context:VSLastSyncDateContext];
	[self addObserver:self forKeyPath:VSLoggingOutKey options:0 context:loggingOutContext];
	[(id)app_delegate addObserver:self forKeyPath:VSSidebarShowingKey options:0 context:VSTypographySidebarShowingContext];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	
	[self removeObserver:self forKeyPath:VSLoggingOutKey context:loggingOutContext];
	[[VSAccount account] removeObserver:self forKeyPath:VSEmailUpdatesKey context:emailUpdatesContext];
	[[VSAccount account] removeObserver:self forKeyPath:VSLastSyncDateKey context:VSLastSyncDateContext];
	[(id)app_delegate removeObserver:self forKeyPath:VSSidebarShowingKey context:VSTypographySidebarShowingContext];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if (context == emailUpdatesContext) {
		[self updateEmailUpdatesSwitch];
	}
	
	else if (context == VSLastSyncDateContext) {
		[self updateLastSyncLabel];
	}
	
	else if (context == loggingOutContext) {
		[self updateLastSyncLabel];
	}
	else if (context == VSTypographySidebarShowingContext) {
		self.tableView.scrollEnabled = !app_delegate.sidebarShowing;
	}
}


#pragma mark - UIViewController

- (void)loadView {
	
	self.view = [VSSyncUI view];
	self.tableView = [VSSyncUI tableViewForViewController:self];
	self.tableView.scrollEnabled = !app_delegate.sidebarShowing;
	
	self.lastSyncDescriptionView = [[VSDescriptionView alloc] initWithText:[self lastSyncDateString]  edgeInsets:[app_delegate.theme edgeInsetsForKey:@"groupedTable.descriptionMargin"]];
	self.emailUpdatesDescriptionView = [[VSDescriptionView alloc] initWithText:NSLocalizedString(@"If enabled, you’ll very occasionally receive email from us regarding product updates.", @"If enabled, you’ll very occasionally receive email from us regarding product updates.") edgeInsets:[app_delegate.theme edgeInsetsForKey:@"groupedTable.descriptionMargin"]];
	
	self.deleteAccountCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	[VSUI configureGroupedTableButtonCell:self.deleteAccountCell labelText:NSLocalizedString(@"Delete Account", @"Delete Account") destructive:YES textAlignment:NSTextAlignmentCenter];
	
	self.changePasswordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	[VSUI configureGroupedTableButtonCell:self.changePasswordCell labelText:NSLocalizedString(@"Change Password", @"Change Password") destructive:NO textAlignment:NSTextAlignmentLeft];
	
	self.logOutCell = [[VSGroupedTableButtonViewCell alloc] initWithLabelText:NSLocalizedString(@"Sign Out", @"Sign Out") destructive:NO textAlignment:NSTextAlignmentLeft];
	
	self.emailUpdatesCell = [[VSLabelSwitchTableViewCell alloc] initWithLabel:NSLocalizedString(@"Email Updates", @"Email Updates")];
	[self.emailUpdatesCell.switchView addTarget:self action:@selector(emailUpdatesSwitchDidChangeValue:) forControlEvents:UIControlEventValueChanged];
	
	self.sectionHeaderView = [VSUI headerViewForTable:self.tableView text:[VSAccount account].username];
	
	self.navbar = [VSNavbarView new];
	self.navbar.showComposeButton = NO;
	self.navbar.frame = RSNavbarRect();
	self.navbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
	self.navbar.title = NSLocalizedString(@"Sync", nil);
	[self.view addSubview:self.navbar];
	
	self.footerView = [[VSLinkButtonFooterView alloc] initWithText:@"Privacy Policy" delegate:self];
	self.tableView.tableFooterView = self.footerView;
	
	[[VSAccount account] downloadEmailUpdatesSetting:nil];
}


- (void)viewDidLayoutSubviews {
	
	CGRect rNavbar = RSNavbarRect();
	[self.navbar qs_setFrameIfNotEqual:rNavbar];
	
	CGRect rBounds = self.view.bounds;
	CGRect rTable = rBounds;
	rTable.origin.y = CGRectGetMaxY(rNavbar);
	rTable.size.height = CGRectGetHeight(rBounds) - CGRectGetMinY(rTable);
	[self.tableView qs_setFrameIfNotEqual:rTable];
	self.tableView.contentInset = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
}


- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	
	[self updateLastSyncLabel];
	[self updateEmailUpdatesSwitch];
	[self.logOutCell clearProgressViews:NO];
}


- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	NSIndexPath *selectedRowIndexPath = [self.tableView indexPathForSelectedRow];
	if (!selectedRowIndexPath) {
		return;
	}
	
	[self.tableView deselectRowAtIndexPath:selectedRowIndexPath animated:animated];
}


#pragma mark - UI

- (void)updateEmailUpdatesSwitch {
	
	self.emailUpdatesCell.switchView.on = [VSAccount account].emailUpdates;
}


- (NSString *)lastSyncDateString {
	
	if (self.loggingOut) {
		return @"";
	}
	
	NSDate *lastSyncDate = [VSAccount account].lastSyncDate;
	if (!lastSyncDate) {
		return NSLocalizedString(@"Not synced yet", @"Not synced yet");
	}
	
	static NSDateFormatter *dateFormatter = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [NSDateFormatter new];
		dateFormatter.dateStyle = kCFDateFormatterMediumStyle;
		dateFormatter.timeStyle = kCFDateFormatterShortStyle;
	});
	
	NSString *dateString = [dateFormatter stringFromDate:lastSyncDate];
	NSString *s = NSLocalizedString(@"Last sync ", @"Last sync ");
	
	return [s stringByAppendingString:dateString];
}


- (void)updateLastSyncLabel {
	
	self.lastSyncDescriptionView.label.text = [self lastSyncDateString];
}

- (void)presentModalViewController:(UIViewController *)viewController {
	
	UINavigationController *navigationController = [VSUI navigationControllerWithViewController:viewController];
	navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	
	[self presentViewController:navigationController animated:YES completion:nil];
}


- (void)showChangePasswordViewController {
	
	[self presentModalViewController:[VSSyncChangePasswordViewController new]];
}


- (void)runLogoutProgressAndLogout {
	
	/*Show progress, then a check mark, then do the actual logout (which triggers a view switch).*/
	
	self.loggingOut = YES;
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	[self.logOutCell startProgress];
	
	NSTimeInterval logoutProgressDuration = [app_delegate.theme timeIntervalForKey:@"syncUI.settings.logoutShowProgressDuration"];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(logoutProgressDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		[self.logOutCell stopProgress:YES imageViewAnimationBlock:nil];
		
		NSTimeInterval logoutSuccessDuration = [app_delegate.theme timeIntervalForKey:@"syncUI.settings.logoutShowSuccessDuration"];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(logoutSuccessDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
			[[VSAccount account] signOut];
			self.loggingOut = NO;
		});
	});
}


#pragma mark - VSLinkButtonFooterViewDelegate

- (void)linkButtonFooterViewTapped:(VSLinkButtonFooterView *)linkButtonFooterView {
	
	[self showPrivacyPolicy:linkButtonFooterView];
}


#pragma mark - Actions

- (void)emailUpdatesSwitchDidChangeValue:(id)sender {
	
	[VSAccount account].emailUpdates = self.emailUpdatesCell.switchView.isOn;
	[[VSAccount account] uploadEmailUpdatesSetting:nil];
}


- (void)showPrivacyPolicy:(id)sender {
	
	[self presentModalViewController:[VSSyncUI modalPrivacyPolicyViewController]];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (section == VSSectionChangePasswordLogOut) {
		return 2;
	}
	return 1;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kNumberOfSections;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section == VSSectionChangePasswordLogOut) {
		
		if (indexPath.row == VSRowChangePassword) {
			return [self changePasswordCell];
		}
		
		return [self logOutCell];
	}
	
	
	if (indexPath.section == VSSectionEmailUpdates) {
		return [self emailUpdatesCell];
	}
	
	return [self deleteAccountCell];
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return (indexPath.section == VSSectionChangePasswordLogOut || indexPath.section == VSSectionDeleteAccount);
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section == VSSectionDeleteAccount) {
		
		/*TODO*/
		
		return;
	}
	
	if (indexPath.section == VSSectionChangePasswordLogOut) {
		
		if (indexPath.row == VSRowChangePassword) {
			[self showChangePasswordViewController];
		}
		
		else if (indexPath.row == VSRowLogOut) {
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			[self runLogoutProgressAndLogout];
		}
	}
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	
	UIView *headerView = [self tableView:tableView viewForHeaderInSection:section];
	if (!headerView) {
		return 0.0;
	}
	
	CGSize size = [headerView sizeThatFits:CGSizeMake(CGRectGetWidth(tableView.bounds), CGFLOAT_MAX)];
	return size.height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if (section == VSSectionChangePasswordLogOut) {
		return self.sectionHeaderView;
	}
	
	return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	
	VSDescriptionView *descriptionView = (VSDescriptionView *)[self tableView:tableView viewForFooterInSection:section];
	if (!descriptionView) {
		return 0.0;
	}
	
	CGSize size = [descriptionView sizeThatFits:CGSizeMake(CGRectGetWidth(tableView.bounds), CGFLOAT_MAX)];
	return size.height;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	
	if (section == VSSectionChangePasswordLogOut) {
		return self.lastSyncDescriptionView;
	}
	else if (section == VSSectionEmailUpdates) {
		return self.emailUpdatesDescriptionView;
	}
	
	return nil;
}


@end
