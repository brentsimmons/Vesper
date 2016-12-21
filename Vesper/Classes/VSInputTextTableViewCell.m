//
//  VSInputTextTableViewCell.m
//  Vesper
//
//  Created by Brent Simmons on 4/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSInputTextTableViewCell.h"
#import "VSUI.h"


@interface VSInputTextTableViewCell () <UITextFieldDelegate>

@property (nonatomic, readwrite) UITextField *textField;
@property (nonatomic, assign) CGFloat labelWidth;
@property (nonatomic, assign) CGFloat labelHeight;
@property (nonatomic, assign) CGFloat textFieldHeight;
@property (nonatomic, assign) CGFloat textFieldMarginLeft;
@property (nonatomic, assign) CGFloat textFieldMarginRight;
@property (nonatomic) NSString *labelText;
@property (nonatomic) UIButton *showHideButton;
@property (nonatomic, weak) id<VSInputTextTableViewCellDelegate> delegate;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@end


@implementation VSInputTextTableViewCell

#pragma mark - Init

- (id)initWithLabelWidth:(CGFloat)labelWidth label:(NSString *)labelText placeholder:(NSString *)placeholder secure:(BOOL)secure delegate:(id<VSInputTextTableViewCellDelegate>)delegate{
	
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	if (!self) {
		return nil;
	}
	
	_delegate = delegate;
	_labelWidth = labelWidth;
	_labelText = labelText;
	
	[VSUI configureGroupedTableCell:self];
	
	_textField = [VSUI groupedTableTextField:secure placeholder:placeholder];
	[self.contentView insertSubview:_textField aboveSubview:self.textLabel];
	_textField.adjustsFontSizeToFitWidth = YES;
	_textField.delegate = self;
	
	_textFieldHeight = CGRectGetHeight(_textField.bounds);
	_textFieldMarginLeft = [app_delegate.theme floatForKey:@"groupedTable.textFieldMarginLeft"];
	_textFieldMarginRight = [app_delegate.theme floatForKey:@"groupedTable.textFieldMarginRight"];
	
	if (QSStringIsEmpty(labelText) || labelWidth < 1.0) {
		_textFieldMarginLeft = [app_delegate.theme floatForKey:@"groupedTable.labelMarginLeft"];
		_labelHeight = 0.0;
	}
	
	if (!QSStringIsEmpty(labelText) && labelWidth > 0.1) {
		[VSUI configureGroupedTableLabel:self.textLabel labelText:labelText];
		_labelHeight = CGRectGetHeight(self.textLabel.bounds);
	}
	
	_textField.placeholder = placeholder;
	
	if (secure && [app_delegate.theme boolForKey:@"groupedTable.enableShowHideButtons"]) {
		_showHideButton = [VSUI showHideButton];
		[_showHideButton addTarget:self action:@selector(showHideButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		[self.contentView insertSubview:_showHideButton aboveSubview:self.textField];
	}
	
	self.showHideButton.hidden = YES;
	
	[self setNeedsLayout];
	
	_tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTapped:)];
	[self addGestureRecognizer:_tapGestureRecognizer];
	
	return self;
}


#pragma mark - Actions

- (void)showHideButtonTapped:(id)sender {
	
	if (self.textField.secureTextEntry) {
		[VSUI updateShowHideButton:self.showHideButton state:VSHide];
		self.textField.enabled = NO;
		self.textField.secureTextEntry = NO;
		self.textField.enabled = YES;
		[self.textField becomeFirstResponder];
	}
	
	else {
		[VSUI updateShowHideButton:self.showHideButton state:VSShow];
		self.textField.enabled = NO;
		self.textField.secureTextEntry = YES;
		self.textField.enabled = YES;
		[self.textField becomeFirstResponder];
	}
}


- (void)labelTapped:(id)sender {
	
	[self.textField becomeFirstResponder];
}


#pragma mark - UIView

- (void)layoutSubviews {
	
	[super layoutSubviews];
	
	if (QSStringIsEmpty(self.labelText) || self.labelWidth < 1.0) {
		[self.textLabel qs_setFrameIfNotEqual:CGRectZero];
	}
	else {
		[VSUI layoutGroupedTableLabel:self.textLabel labelWidth:self.labelWidth contentView:self.contentView];
	}
	
	CGFloat textFieldOriginX = CGRectGetMaxX(self.textLabel.frame) + self.textFieldMarginLeft;
	[VSUI layoutGroupedTableRightView:self.textField originX:textFieldOriginX marginRight:self.textFieldMarginRight contentView:self.contentView];
	
	if (self.showHideButton) {
		
		CGRect rButton = self.showHideButton.frame;
		CGRect rTextField = self.textField.frame;
		
		rButton.origin.x = CGRectGetMaxX(rTextField) - CGRectGetWidth(rButton) + 5;
		rButton.origin.y = 10;
		rButton.size.height = CGRectGetHeight(self.contentView.bounds) - 2.0f;
		rButton = CGRectCenteredVerticallyInRect(rButton, self.contentView.bounds);
		[self.showHideButton qs_setFrameIfNotEqual:rButton];
		
		rTextField.size.width -= (CGRectGetWidth(rButton) + 4.0f);
		[self.textField qs_setFrameIfNotEqual:rTextField];
	}
}


#pragma mark - UI

- (void)updateShowHideButtonVisibility {
	
	NSString *s = self.textField.text;
	
	if (QSStringIsEmpty(s)) {
		self.showHideButton.hidden = YES;
	}
	else {
		self.showHideButton.hidden = NO;
	}
}


#pragma mark - UITextFieldDelegate

- (void)updateShowHideButtonCoalesced {
	
	[self qs_performSelectorCoalesced:@selector(updateShowHideButtonVisibility) withObject:nil afterDelay:0.1];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	[self updateShowHideButtonCoalesced];
	
	return [self.delegate textFieldShouldReturn:textField];
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	
	[self updateShowHideButtonCoalesced];
	
	return YES;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	
	[self updateShowHideButtonCoalesced];
	
	return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	[self updateShowHideButtonCoalesced];
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
	
	[self updateShowHideButtonCoalesced];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	[self updateShowHideButtonCoalesced];
	
	return YES;
}

@end
