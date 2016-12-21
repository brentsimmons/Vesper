//
//  VSSyncSignInViewController.m
//  Vesper
//
//  Created by Brent Simmons on 2/7/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSyncSignInViewController.h"
#import "VSSyncUI.h"
#import "VSBasicWebViewController.h"
#import "VSUI.h"
#import "VSInputTextTableViewCell.h"
#import "VSAccount.h"
#import "VSDescriptionView.h"
#import "VSGroupedTableButtonViewCell.h"
#import "VSLinkButtonFooterView.h"
#import "VSSignInFooterView.h"
#import "VSSyncForgotPasswordViewController.h"


@interface VSSyncSignInViewController () <UITableViewDelegate, UITableViewDataSource, VSInputTextTableViewCellDelegate, VSSignInFooterViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) VSInputTextTableViewCell *emailCell;
@property (nonatomic) VSInputTextTableViewCell *passwordCell;
@property (nonatomic) VSGroupedTableButtonViewCell *buttonCell;
@property (nonatomic) VSDescriptionView *footerView;
@property (nonatomic, assign) BOOL showingProgressOrError;
@property (nonatomic, assign) CGFloat footerViewHeight;
@property (nonatomic) VSSignInFooterView *tableFooterView;

@end


typedef NS_ENUM(NSUInteger, VSSignInSection) {
	VSSectionEmailPassword,
	VSSectionButton
};

typedef NS_ENUM(NSUInteger, VSEmailPasswordRow) {
	VSRowEmail,
	VSRowPassword
};

static const NSInteger kNumberOfSections = 2;

@implementation VSSyncSignInViewController


#pragma mark - Init

- (instancetype)init {
	
	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}
	
	self.title = NSLocalizedString(@"Sign In", @"Sign In");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forgotPasswordEmailAddressUsed:) name:VSSyncForgotPasswordEmailAddressUsedNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UIViewController

- (void)loadView {
	
	self.view = [VSSyncUI view];
	self.tableView = [VSSyncUI tableViewForViewController:self];
	self.tableView.scrollEnabled = YES;
	
	UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancelButtonItem;
	
	self.buttonCell = [[VSGroupedTableButtonViewCell alloc] initWithLabelText:NSLocalizedString(@"Sign In", @"Sign In") destructive:NO textAlignment:NSTextAlignmentCenter];
	
	CGFloat labelWidth = [app_delegate.theme floatForKey:@"syncUI.signIn.inputCellLabelWidth"];
	
	self.emailCell = [[VSInputTextTableViewCell alloc] initWithLabelWidth:labelWidth label:NSLocalizedString(@"Email", @"Email") placeholder:nil secure:NO delegate:self];
	self.emailCell.textField.returnKeyType = UIReturnKeyNext;
	self.emailCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
	self.emailCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.emailCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	
	NSString *username = [VSAccount account].username;
	if (username) {
		self.emailCell.textField.text = username;
	}
	
	self.passwordCell = [[VSInputTextTableViewCell alloc] initWithLabelWidth:labelWidth label:NSLocalizedString(@"Password", @"Password") placeholder:nil secure:YES delegate:self];
	self.passwordCell.textField.returnKeyType = UIReturnKeyDone;
	self.passwordCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.passwordCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	
	self.footerView = [[VSDescriptionView alloc] initWithText:[self longestMostLikelyErrorMessage] edgeInsets:[app_delegate.theme edgeInsetsForKey:@"groupedTable.descriptionMargin"]];
	
	CGRect appFrame = [UIScreen mainScreen].applicationFrame;
	CGSize size = [self.footerView sizeThatFits:CGSizeMake(CGRectGetWidth(appFrame), CGFLOAT_MAX)];
	self.footerViewHeight = size.height;
	[self.footerView updateText:@"" color:[app_delegate.theme colorForKey:@"groupedTable.errorMessageColor"]];
	
	CGRect rTableFooterView = [UIScreen mainScreen].bounds;
	rTableFooterView.origin = CGPointZero;
	rTableFooterView.size.height = [app_delegate.theme floatForKey:@"syncUI.signIn.footerHeight"];
	self.tableFooterView = [[VSSignInFooterView alloc] initWithFrame:rTableFooterView delegate:self];
	self.tableView.tableFooterView = self.tableFooterView;
	
	[VSUI configureNavbar:self.navigationController.navigationBar];
}


- (void)viewDidLayoutSubviews {
	
	CGRect rBounds = self.view.bounds;
	self.tableView.frame = rBounds;
}


#pragma mark - VSSignInFooterViewDelegate

- (void)privacyPolicyTapped:(id)sender {
	
	[self showPrivacyPolicy:sender];
}


- (void)forgotPasswordTapped:(id)sender {
	
	[self showForgotPassword:sender];
}


#pragma mark - Actions

- (void)cancel:(id)sender {
	
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)showPrivacyPolicy:(id)sender {
	
	[self.view endEditing:YES];
	[self.navigationController pushViewController:[VSSyncUI privacyPolicyViewController] animated:YES];
}


- (void)showForgotPassword:(id)sender {
	
	[self.view endEditing:YES];
	
	NSString *username = [self.emailCell.textField.text copy];
	if (username) {
		username = [username qs_stringByTrimmingWhitespace];
	}
	else {
		username = [VSAccount account].username;
	}
	
	VSSyncForgotPasswordViewController *viewController = [[VSSyncForgotPasswordViewController alloc] initWithEmailAddress:username];
	[self.navigationController pushViewController:viewController animated:YES];
}


- (void)login:(id)sender {
	
	NSString *username = [self.emailCell.textField.text copy];
	username = [username qs_stringByTrimmingWhitespace];
	NSString *password = [self.passwordCell.textField.text copy];
	
	if (QSStringIsEmpty(username) || QSStringIsEmpty(password)) {
		return;
	}
	
	[self login:username password:password];
}


#pragma mark - Error Message

- (void)displayErrorMessage:(NSString *)s {
	
	[self.footerView updateText:s color:[app_delegate.theme colorForKey:@"groupedTable.errorMessageColor"]];
}


- (void)clearErrorMessageAnimated:(BOOL)animated {
	
	if (!animated) {
		[self.footerView updateText:@"" color:[app_delegate.theme colorForKey:@"groupedTable.errorMessageColor"]];
		return;
	}
	
	NSTimeInterval duration = [app_delegate.theme timeIntervalForKey:@"circleProgress.successFailureFadeOutDuration"];
	[UIView animateWithDuration:duration delay:0.0 options:0 animations:^{
		
		self.footerView.label.alpha = 0.0f;
		
	} completion:^(BOOL finished) {
		;
	}];
}


- (NSString *)longestMostLikelyErrorMessage {
	
	/*This is just used to make sure the footer view gets the right initial size.
	 The actual text returned doesn't really matter and will never be displayed.*/
	
	return [[self errorMessageForStatusCode:401] stringByAppendingString:@"\n\n"];
}


- (NSString *)errorMessageForStatusCode:(NSInteger)statusCode {
	
	if (statusCode == 500) {
		return NSLocalizedString(@"Can’t sign in due to a server error.", nil);
	}
	else if (statusCode == 401) {
		return NSLocalizedString(@"Can’t sign in because the email and password don’t match an account.", nil);
	}
	
	return nil;
}


- (NSString *)errorMessage:(VSAPIResult *)apiResult {
	
	NSString *s = [self errorMessageForStatusCode:apiResult.statusCode];
	if (s) {
		return s;
	}
	
	if (apiResult.error) {
		return [apiResult.error localizedDescription];
	}
	
	return NSLocalizedString(@"Can’t sign in due to an unknown error.", nil);
}


#pragma mark - Login

- (void)dismissAfterDelay:(NSTimeInterval)delay {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		[self cancel:nil];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	});
}


- (void)login:(NSString *)username password:(NSString *)password {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	self.showingProgressOrError = YES;
	[self.buttonCell startProgress];
	
	__weak VSSyncSignInViewController *weakself = self;
	
	[[VSAccount account] login:username password:password resultBlock:^(VSAPIResult *apiResult) {
		
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		
		NSString *errorMessage = nil;
		if (!apiResult.succeeded) {
			
			errorMessage = [weakself errorMessage:apiResult];
			
			[weakself displayErrorMessage:errorMessage];
			weakself.footerView.label.alpha = 0.0f;
			
			[weakself.buttonCell stopProgress:apiResult.succeeded imageViewAnimationBlock:^{
				
				weakself.footerView.label.alpha = 1.0f;
				
			}];
		}
		
		else {
			
			[weakself.buttonCell stopProgress:apiResult.succeeded imageViewAnimationBlock:nil];
			
			NSTimeInterval showSuccessDuration = [app_delegate.theme timeIntervalForKey:@"syncUI.signIn.showSuccessDuration"];
			[weakself dismissAfterDelay:showSuccessDuration];
			
			[[NSNotificationCenter defaultCenter] qs_postNotificationNameOnMainThread:VSAccountUserDidSignInManuallyNotification object:nil userInfo:nil];
		}
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
			return [self emailCell];
		}
		
		return [self passwordCell];
	}
	
	return [self buttonCell];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section != VSSectionButton) {
		return;
	}
	
	[self.view endEditing:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[self login:nil];
}


- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return indexPath.section == VSSectionButton && !self.showingProgressOrError;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	
	if (section != VSSectionEmailPassword) {
		return 0.0;
	}
	
	return self.footerViewHeight;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	
	if (section != VSSectionEmailPassword) {
		return nil;
	}
	
	return self.footerView;
}


#pragma mark - Notifications

- (void)textDidChange:(NSNotification *)note {
	
	if (!self.showingProgressOrError) {
		return;
	}
	
	UITextField *textField = [note object];
	if (textField == self.emailCell.textField || textField == self.passwordCell.textField) {
		
		[self.buttonCell clearProgressViews:YES];
		[self clearErrorMessageAnimated:YES];
		self.showingProgressOrError = NO;
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


- (void)forgotPasswordEmailAddressUsed:(NSNotification *)note {
	
	NSString *emailAddress = [note userInfo][VSSyncForgotPasswordEmailAddress];
	if (!QSStringIsEmpty(emailAddress)) {
		self.emailCell.textField.text = emailAddress;
	}
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
