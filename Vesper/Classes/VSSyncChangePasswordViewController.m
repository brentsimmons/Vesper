//
//  VSSyncChangePasswordViewController.m
//  Vesper
//
//  Created by Brent Simmons on 2/7/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSyncChangePasswordViewController.h"
#import "VSSyncUI.h"
#import "VSBasicWebViewController.h"
#import "VSUI.h"
#import "VSInputTextTableViewCell.h"
#import "VSLinkButtonFooterView.h"


@interface VSSyncChangePasswordViewController () <UITableViewDelegate, UITableViewDataSource, VSInputTextTableViewCellDelegate, VSLinkButtonFooterViewDelegate>

@property (nonatomic) VSInputTextTableViewCell *password1Cell;
@property (nonatomic) VSInputTextTableViewCell *password2Cell;
@property (nonatomic) UITableViewCell *saveCell;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) VSLinkButtonFooterView *footerView;

@end


typedef NS_ENUM(NSUInteger, VSChangePasswordSection) {
	VSSectionPasswordFields,
	VSSectionButton
};

static const NSInteger kNumberOfSections = 2;
static const NSInteger kSaveRow = 0;


@implementation VSSyncChangePasswordViewController


#pragma mark - Init

- (instancetype)init {

	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}

	self.title = NSLocalizedString(@"Change Password", @"Change Password");

	return self;
}


#pragma mark - UIViewController

- (void)loadView {

	self.view = [VSSyncUI view];
	self.tableView = [VSSyncUI tableViewForViewController:self];
	self.tableView.scrollEnabled = YES;
	
	self.password1Cell = [self passwordCell:NSLocalizedString(@"New password", @"New password") returnKeyType:UIReturnKeyNext];
	self.password2Cell = [self passwordCell:NSLocalizedString(@"Confirm new password", @"Confirm new password") returnKeyType:UIReturnKeyDone];

	self.saveCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	[VSUI configureGroupedTableButtonCell:self.saveCell labelText:NSLocalizedString(@"Save", @"Save") destructive:NO textAlignment:NSTextAlignmentCenter];

	UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancelButtonItem;

	self.footerView = [[VSLinkButtonFooterView alloc] initWithText:@"Privacy Policy" delegate:self];
	self.tableView.tableFooterView = self.footerView;

	[VSUI configureNavbar:self.navigationController.navigationBar];
}


- (void)viewDidLayoutSubviews {

	[VSSyncUI layoutTableView:self.tableView view:self.view themeSpecifier:@"syncUI.changePassword"];
}


#pragma mark - Cells

- (VSInputTextTableViewCell *)passwordCell:(NSString *)placeholder returnKeyType:(UIReturnKeyType)returnKeyType {

	VSInputTextTableViewCell *cell = [[VSInputTextTableViewCell alloc] initWithLabelWidth:0.0 label:nil placeholder:placeholder secure:YES delegate:self];

	cell.textField.returnKeyType = returnKeyType;
	cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;

	return cell;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	if (section == VSSectionPasswordFields) {
		return 2;
	}
	return 1;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kNumberOfSections;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	if (indexPath.section == VSSectionPasswordFields) {

		if (indexPath.row == 0) {
			return self.password1Cell;
		}

		return self.password2Cell;
	}


	if (indexPath.section == VSSectionButton) {
		return self.saveCell;
	}

	// Shouldn't get here. Added 19 Dec. 2016 to make Xcode 8.2.1 happy.
	return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {

	return indexPath.section == VSSectionButton;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if (indexPath.section != VSSectionButton || indexPath.row != kSaveRow) {
		return;
	}

	[self.view endEditing:YES];

	NSString *password1 = [self.password1Cell.textField.text copy];
	NSString *password2 = [self.password2Cell.textField.text copy];

	if (![[VSAccount account] passwordIsValid:password1]) {
		return;
	}
	if (![[VSAccount account] passwordIsValid:password2]) {
		return;
	}
	if (![password1 isEqualToString:password2]) {
		return;
	}

	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];

	[[VSAccount account] changePassword:password1 resultBlock:^(VSAPIResult *apiResult) {

		[[UIApplication sharedApplication] endIgnoringInteractionEvents];

		if (apiResult.succeeded) {
			[self cancel:nil];
		}
	}];
}


#pragma mark - VSLinkButtonFooterViewDelegate

- (void)linkButtonFooterViewTapped:(VSLinkButtonFooterView *)linkButtonFooterView {

	[self showPrivacyPolicy:linkButtonFooterView];
}


#pragma mark - Actions

- (void)showPrivacyPolicy:(id)sender {

	[self.view endEditing:YES];
	[self.navigationController pushViewController:[VSSyncUI privacyPolicyViewController] animated:YES];
}


- (void)cancel:(id)sender {

	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

	if (textField == self.password1Cell.textField) {
		[self.password2Cell.textField becomeFirstResponder];
	}
	else {
		[textField resignFirstResponder];
	}

	return YES;
}


@end
