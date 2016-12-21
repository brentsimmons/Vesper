//
//  VSSyncCreateAccountViewController.m
//  Vesper
//
//  Created by Brent Simmons on 2/7/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSyncCreateAccountViewController.h"
#import "VSSyncUI.h"
#import "VSBasicWebViewController.h"
#import "VSInputTextTableViewCell.h"
#import "VSLabelSwitchTableViewCell.h"
#import "VSUI.h"
#import "VSDescriptionView.h"
#import "VSGroupedTableButtonViewCell.h"
#import "VSLinkButtonFooterView.h"


@interface VSSyncCreateAccountViewController () <UITableViewDelegate, UITableViewDataSource, VSInputTextTableViewCellDelegate, VSLinkButtonFooterViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) VSLabelSwitchTableViewCell *emailUpdatesCell;
@property (nonatomic) VSInputTextTableViewCell *emailCell;
@property (nonatomic) VSInputTextTableViewCell *passwordCell;
@property (nonatomic) VSDescriptionView *descriptionView;
@property (nonatomic) VSGroupedTableButtonViewCell *buttonCell;
@property (nonatomic) VSDescriptionView *errorMessageView;
@property (nonatomic, assign) CGFloat errorMessageViewHeight;
@property (nonatomic) BOOL showingProgress;
@property (nonatomic) BOOL showingErrorMessage;
@property (nonatomic) VSLinkButtonFooterView *footerView;

@end


@implementation VSSyncCreateAccountViewController


#pragma mark - Init

- (instancetype)init {
	
	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}
	
	self.title = NSLocalizedString(@"Create Account", @"Create Account");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	return self;
}



#pragma mark - Dealloc

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UIViewController

typedef NS_ENUM(NSUInteger, VSCreateAccountSection) {
	VSSectionEmailPassword,
	VSSectionEmailUpdates,
	VSSectionButton
};

typedef NS_ENUM(NSUInteger, VSEmailPasswordRow) {
	VSRowEmail,
	VSRowPassword
};

static const NSInteger kNumberOfSections = 3;


- (void)loadView {
	
	self.view = [VSSyncUI view];
	self.tableView = [VSSyncUI tableViewForViewController:self];
	self.tableView.scrollEnabled = YES;
	
	UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancelButtonItem;
	
	self.buttonCell = [[VSGroupedTableButtonViewCell alloc] initWithLabelText:NSLocalizedString(@"Create Account", @"Create Account") destructive:NO textAlignment:NSTextAlignmentCenter];
	
	self.descriptionView = [[VSDescriptionView alloc] initWithText:NSLocalizedString(@"If enabled, you’ll very occasionally receive email from us regarding product updates. You can opt out at any time.", @"Email Updates") edgeInsets:[app_delegate.theme edgeInsetsForKey:@"groupedTable.descriptionMargin"]];
	
	self.emailUpdatesCell = [[VSLabelSwitchTableViewCell alloc] initWithLabel:NSLocalizedString(@"Email Updates", @"Email Updates")];
	self.emailUpdatesCell.switchView.on = NO;
	
	CGFloat labelWidth = [app_delegate.theme floatForKey:@"syncUI.createAccount.inputCellLabelWidth"];
	
	self.passwordCell = [[VSInputTextTableViewCell alloc] initWithLabelWidth:labelWidth label:NSLocalizedString(@"Password", @"Password") placeholder:nil secure:YES delegate:self];
	self.passwordCell.textField.returnKeyType = UIReturnKeyDone;
	self.passwordCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.passwordCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	
	self.emailCell = [[VSInputTextTableViewCell alloc] initWithLabelWidth:labelWidth label:NSLocalizedString(@"Email", @"Email") placeholder:nil secure:NO delegate:self];
	self.emailCell.textField.returnKeyType = UIReturnKeyNext;
	self.emailCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
	self.emailCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.emailCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	
	self.errorMessageView = [[VSDescriptionView alloc] initWithText:[self longestMostLikelyErrorMessage] edgeInsets:[app_delegate.theme edgeInsetsForKey:@"groupedTable.descriptionMargin"]];
	
	CGRect appFrame = [UIScreen mainScreen].applicationFrame;
	CGSize size = [self.errorMessageView sizeThatFits:CGSizeMake(CGRectGetWidth(appFrame), CGFLOAT_MAX)];
	self.errorMessageViewHeight = size.height;
	[self.errorMessageView updateText:@"" color:[app_delegate.theme colorForKey:@"groupedTable.errorMessageColor"]];
	
	self.footerView = [[VSLinkButtonFooterView alloc] initWithText:@"Privacy Policy" delegate:self];
	self.tableView.tableFooterView = self.footerView;
}


- (void)viewDidLayoutSubviews {
	
	CGRect rBounds = self.view.bounds;
	self.tableView.frame = rBounds;
}


#pragma mark - VSLinkButtonFooterViewDelegate

- (void)linkButtonFooterViewTapped:(VSLinkButtonFooterView *)linkButtonFooterView {
	
	[self showPrivacyPolicy:linkButtonFooterView];
}


#pragma mark - Actions

- (void)cancel:(id)sender {
	
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)showPrivacyPolicy:(id)sender {
	
	[self.view endEditing:YES];
	[self.navigationController pushViewController:[VSSyncUI privacyPolicyViewController] animated:YES];
}


- (void)createAccount:(id)sender {
	
	NSString *username = [self.emailCell.textField.text copy];
	username = [username qs_stringByTrimmingWhitespace];
	NSString *password = [self.passwordCell.textField.text copy];
	
	if (![[VSAccount account] usernameIsValid:username]) {
		[self displayErrorMessage:[self invalidUsernameErrorMessage]];
		return;
	}
	if (![[VSAccount account] passwordIsValid:password]) {
		[self displayErrorMessage:[self invalidPasswordErrorMessage]];
		return;
	}
	
	BOOL emailUpdates = self.emailUpdatesCell.switchView.isOn;
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	self.showingProgress = YES;
	[self.buttonCell startProgress];
	
	__weak VSSyncCreateAccountViewController *weakself = self;
	
	[[VSAccount account] createAccount:username password:password emailUpdates:emailUpdates resultBlock:^(VSAPIResult *apiResult) {
		
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		self.showingProgress = NO;
		
		if (!apiResult.succeeded) {
			
			[weakself handleCreateAccountError:apiResult];
			return;
		}
		
		
		[[NSNotificationCenter defaultCenter] qs_postNotificationNameOnMainThread:VSAccountUserDidCreateAccountNotification object:nil userInfo:nil];
		
		[weakself.buttonCell stopProgress:apiResult.succeeded imageViewAnimationBlock:nil];
		
		NSTimeInterval showSuccessDuration = [app_delegate.theme timeIntervalForKey:@"syncUI.createAccount.showSuccessDuration"];
		[weakself dismissAfterDelay:showSuccessDuration];
	}];
}


#pragma mark - Dismissing

- (void)dismissAfterDelay:(NSTimeInterval)delay {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		[self cancel:nil];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	});
}


#pragma mark - Errors

- (void)displayErrorMessage:(NSString *)s {
	
	[self.errorMessageView updateText:s color:[app_delegate.theme colorForKey:@"groupedTable.errorMessageColor"]];
}


- (void)clearErrorMessageAnimated:(BOOL)animated {
	
	if (!animated) {
		[self.errorMessageView updateText:@"" color:[app_delegate.theme colorForKey:@"groupedTable.errorMessageColor"]];
		return;
	}
	
	NSTimeInterval duration = [app_delegate.theme timeIntervalForKey:@"circleProgress.successFailureFadeOutDuration"];
	[UIView animateWithDuration:duration delay:0.0 options:0 animations:^{
		
		self.errorMessageView.label.alpha = 0.0f;
		
	} completion:^(BOOL finished) {
		;
	}];
}


- (NSString *)longestMostLikelyErrorMessage {
	
	/*This is just used to make sure the footer view gets the right initial size.
	 The actual text returned doesn't really matter and will never be displayed.*/
	
	return NSLocalizedString(@"Password must be seven or more characters.", nil);
}


- (NSString *)errorMessageForStatusCode:(NSInteger)statusCode {
	
	if (statusCode == 500) {
		return NSLocalizedString(@"Can’t create account due to a server error.", nil);
	}
	
	return nil;
}


- (NSString *)invalidUsernameErrorMessage {
	
	return NSLocalizedString(@"This email address isn’t a valid email address.", nil);
}


- (NSString *)invalidPasswordErrorMessage {
	
	return NSLocalizedString(@"Password must be seven or more characters.", nil);
}


- (NSString *)errorMessage:(VSAPIResult *)apiResult {
	
	if ([apiResult.resultString rangeOfString:@"VSErrorUsernameAlreadyExists"].location != NSNotFound) {
		
		return NSLocalizedString(@"This email address already has an account.", nil);
	}
	
	if ([apiResult.resultString rangeOfString:@"VSErrorInvalidPassword"].location != NSNotFound) {
		
		return [self invalidPasswordErrorMessage];
	}
	
	if ([apiResult.resultString rangeOfString:@"VSErrorInvalidUsername"].location != NSNotFound) {
		
		return [self invalidUsernameErrorMessage];
	}
	
	
	NSString *s = [self errorMessageForStatusCode:apiResult.statusCode];
	if (s) {
		return s;
	}
	
	if (apiResult.error) {
		return [apiResult.error localizedDescription];
	}
	
	return NSLocalizedString(@"Can’t create account due to an unknown error.", nil);
}


- (void)handleCreateAccountError:(VSAPIResult *)apiResult {
	
	self.showingErrorMessage = YES;
	
	NSString *errorMessage = [self errorMessage:apiResult];
	
	[self displayErrorMessage:errorMessage];
	self.errorMessageView.label.alpha = 0.0f;
	
	__weak VSSyncCreateAccountViewController *weakself = self;
	
	[self.buttonCell stopProgress:apiResult.succeeded imageViewAnimationBlock:^{
		
		weakself.errorMessageView.label.alpha = 1.0f;
		
	}];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (section == VSSectionEmailPassword) {
		return 2;
	}
	return 1;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kNumberOfSections;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section == VSSectionEmailPassword) {
		
		if (indexPath.row == VSRowEmail) {
			return self.emailCell;
		}
		
		return self.passwordCell;
	}
	
	
	if (indexPath.section == VSSectionEmailUpdates) {
		return self.emailUpdatesCell;
	}
	
	return self.buttonCell;
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return indexPath.section == VSSectionButton && !self.showingProgress;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section != VSSectionButton) {
		return;
	}
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[self createAccount:nil];
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	
	if (section == VSSectionEmailUpdates) {
		CGSize size = [self.descriptionView sizeThatFits:CGSizeMake(CGRectGetWidth(tableView.bounds), CGFLOAT_MAX)];
		return size.height;
	}
	
	else if (section == VSSectionEmailPassword) {
		return self.errorMessageViewHeight;
	}
	
	return 0.0;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	
	if (section == VSSectionEmailUpdates) {
		return self.descriptionView;
	}
	
	else if (section == VSSectionEmailPassword) {
		return self.errorMessageView;
	}
	
	return nil;
}


#pragma mark - Notifications

- (void)textDidChange:(NSNotification *)note {
	
	if (!self.showingErrorMessage) {
		return;
	}
	
	UITextField *textField = [note object];
	if (textField == self.emailCell.textField || textField == self.passwordCell.textField) {
		
		[self.buttonCell clearProgressViews:YES];
		[self clearErrorMessageAnimated:YES];
		self.showingErrorMessage = NO;
	}
}


- (void)keyboardWillShow:(NSNotification *)note {
	
	CGSize keyboardSize = [[note userInfo][UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	
	self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);;
	self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}


- (void)keyboardWillHide:(NSNotification *)note {
	
	self.tableView.contentInset = UIEdgeInsetsZero;
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}


#pragma mark - VSInputTextTableViewCellDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	if (textField == self.emailCell.textField) {
		[self.passwordCell.textField becomeFirstResponder];
	}
	else {
		[textField resignFirstResponder];
	}
	
	return YES;
}


@end
