//
//  VSSyncForgotPasswordViewController.m
//  Vesper
//
//  Created by Brent Simmons on 5/20/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSyncForgotPasswordViewController.h"
#import "VSDescriptionView.h"
#import "VSGroupedTableButtonViewCell.h"
#import "VSInputTextTableViewCell.h"
#import "VSSyncUI.h"
#import "VSUI.h"


NSString *VSSyncForgotPasswordEmailAddressUsedNotification = @"VSSyncForgotPasswordEmailAddressUsedNotification";
NSString *VSSyncForgotPasswordEmailAddress = @"emailAddress";

@interface VSSyncForgotPasswordViewController () <VSInputTextTableViewCellDelegate>

@property (nonatomic) NSString *initialEmailAddress;
@property (nonatomic) VSDescriptionView *footerView;
@property (nonatomic) VSDescriptionView *buttonFooterView;
@property (nonatomic) VSGroupedTableButtonViewCell *buttonCell;
@property (nonatomic) VSInputTextTableViewCell *emailCell;
@property (nonatomic) CGFloat footerViewHeight;
@property (nonatomic) CGFloat buttonFooterViewHeight;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) BOOL showingProgressOrError;

@end


typedef NS_ENUM(NSUInteger, VSForgotPasswordSection) {
	VSSectionEmail,
	VSSectionButton
};

static const NSInteger kNumberOfSections = 2;


@implementation VSSyncForgotPasswordViewController


#pragma mark - Init

- (instancetype)initWithEmailAddress:(NSString *)emailAddress {
	
	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}
	
	_initialEmailAddress = emailAddress;
	
	self.title = NSLocalizedString(@"Forgot Password", @"Forgot Password");
	
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

- (void)loadView {
	
	self.view = [VSSyncUI view];
	self.tableView = [VSSyncUI tableViewForViewController:self];
	self.tableView.scrollEnabled = YES;
	[self.view addSubview:self.tableView];
	
	UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancelButtonItem;
	
	self.buttonCell = [[VSGroupedTableButtonViewCell alloc] initWithLabelText:NSLocalizedString(@"Reset", @"Reset") destructive:NO textAlignment:NSTextAlignmentCenter];
	
	CGFloat labelWidth = [app_delegate.theme floatForKey:@"syncUI.forgotPassword.inputCellLabelWidth"];
	
	self.emailCell = [[VSInputTextTableViewCell alloc] initWithLabelWidth:labelWidth label:NSLocalizedString(@"Email", @"Email") placeholder:nil secure:NO delegate:self];
	self.emailCell.textField.returnKeyType = UIReturnKeyDone;
	self.emailCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
	self.emailCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.emailCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	
	if (self.initialEmailAddress) {
		self.emailCell.textField.text = self.initialEmailAddress;
	}
	
	self.footerView = [[VSDescriptionView alloc] initWithText:NSLocalizedString(@"Enter your email address to reset your password.", nil) edgeInsets:[app_delegate.theme edgeInsetsForKey:@"groupedTable.descriptionMargin"]];
	
	CGRect appFrame = [UIScreen mainScreen].applicationFrame;
	CGFloat viewWidth = CGRectGetWidth(appFrame);
	
	CGSize footerSize = [self.footerView sizeThatFits:CGSizeMake(viewWidth, CGFLOAT_MAX)];
	CGRect rFooter = self.footerView.frame;
	rFooter.origin = CGPointZero;
	rFooter.size.width = viewWidth;
	rFooter.size.height = footerSize.height;
	self.footerView.frame = rFooter;
	self.footerViewHeight = CGRectGetHeight(rFooter);
	
	self.buttonFooterView = [[VSDescriptionView alloc] initWithText:[self longestMostLikelyErrorMessage] edgeInsets:[app_delegate.theme edgeInsetsForKey:@"groupedTable.descriptionMargin"]];
	CGSize buttonFooterSize = [self.buttonFooterView sizeThatFits:CGSizeMake(viewWidth, CGFLOAT_MAX)];
	CGRect rButtonFooter = self.buttonFooterView.frame;
	rButtonFooter.origin = CGPointZero;
	rButtonFooter.size.width = viewWidth;
	rButtonFooter.size.height = buttonFooterSize.height;
	self.buttonFooterView.frame = rButtonFooter;
	self.buttonFooterViewHeight = CGRectGetHeight(rButtonFooter);
	[self.buttonFooterView updateText:@"" color:[app_delegate.theme colorForKey:@"groupedTable.errorMessageColor"]];
	
	[VSUI configureNavbar:self.navigationController.navigationBar];
}


- (void)viewDidLayoutSubviews {
	
	CGRect rBounds = self.view.bounds;
	self.tableView.frame = rBounds;
}


#pragma mark - Actions

- (void)cancel:(id)sender {
	
	[self.navigationController popViewControllerAnimated:YES];
}


- (void)resetPassword:(id)sender {
	
	[self.view endEditing:YES];
	[self resetPassword];
}


#pragma mark - Success Message

- (void)displaySuccessMessage {
	
	[self.buttonFooterView updateText:NSLocalizedString(@"An email with instructions has been sent to you.", nil) color:nil];
	self.buttonFooterView.label.alpha = 1.0f;
}


#pragma mark - Error Message

- (void)displayErrorMessage:(NSString *)s {
	
	[self.buttonFooterView updateText:s color:[app_delegate.theme colorForKey:@"groupedTable.errorMessageColor"]];
}


- (void)clearErrorMessageAnimated:(BOOL)animated {
	
	if (!animated) {
		[self.buttonFooterView updateText:@"" color:[app_delegate.theme colorForKey:@"groupedTable.errorMessageColor"]];
		return;
	}
	
	NSTimeInterval duration = [app_delegate.theme timeIntervalForKey:@"circleProgress.successFailureFadeOutDuration"];
	[UIView animateWithDuration:duration delay:0.0 options:0 animations:^{
		
		self.buttonFooterView.label.alpha = 0.0f;
		
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
	
	if (statusCode == 500 || statusCode == 400) {
		return NSLocalizedString(@"Can’t reset password due to a server error.", nil);
	}
	else if (statusCode == 401) {
		return NSLocalizedString(@"Can’t reset password because the email address doesn’t match an account.", nil);
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
	
	return NSLocalizedString(@"Can’t reset password due to an unknown error.", nil);
}


#pragma mark - Reset Password

- (void)dismissAfterDelay:(NSTimeInterval)delay {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		[self cancel:nil];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	});
}


- (void)resetPassword {
	
	NSString *username = [self.emailCell.textField.text copy];
	username = [username qs_stringByTrimmingWhitespace];
	if (QSStringIsEmpty(username)) {
		return;
	}
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	self.showingProgressOrError = YES;
	[self.buttonCell startProgress];
	
	__weak VSSyncForgotPasswordViewController *weakself = self;
	
	[[VSAccount account] forgotPassword:username resultBlock:^(VSAPIResult *apiResult) {
		
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		
		NSString *errorMessage = nil;
		if (!apiResult.succeeded) {
			
			errorMessage = [weakself errorMessage:apiResult];
			
			[weakself displayErrorMessage:errorMessage];
			weakself.buttonFooterView.label.alpha = 0.0f;
			
			[weakself.buttonCell stopProgress:apiResult.succeeded imageViewAnimationBlock:^{
				
				weakself.buttonFooterView.label.alpha = 1.0f;
				
			}];
		}
		
		else {
			
			[[NSNotificationCenter defaultCenter] postNotificationName:VSSyncForgotPasswordEmailAddressUsedNotification object:self userInfo:@{VSSyncForgotPasswordEmailAddress : username}];
			
			[weakself displaySuccessMessage];
			[weakself.buttonCell stopProgress:apiResult.succeeded imageViewAnimationBlock:nil];
			
			NSTimeInterval showSuccessDuration = [app_delegate.theme timeIntervalForKey:@"syncUI.forgotPassword.showSuccessDuration"];
			[weakself dismissAfterDelay:showSuccessDuration];
		}
	}];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return 1;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kNumberOfSections;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section == VSSectionEmail) {
		return self.emailCell;
	}
	
	return self.buttonCell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section != VSSectionButton) {
		return;
	}
	
	[self.view endEditing:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[self resetPassword:nil];
}


- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return indexPath.section == VSSectionButton && !self.showingProgressOrError;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	
	if (section == VSSectionEmail) {
		return self.footerViewHeight;
	}
	
	return self.buttonFooterViewHeight;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	
	if (section == VSSectionEmail) {
		return self.footerView;
	}
	
	return self.buttonFooterView;
}


#pragma mark - Notifications

- (void)textDidChange:(NSNotification *)note {
	
	if (!self.showingProgressOrError) {
		return;
	}
	
	UITextField *textField = [note object];
	if (textField == self.emailCell.textField) {
		
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


#pragma mark - VSInputTextTableViewCellDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	if (textField == self.emailCell.textField) {
		[self resetPassword:nil];
	}
	
	return YES;
}



@end
