//
//  VSTagTextFieldContainerView.m
//  Vesper
//
//  Created by Brent Simmons on 4/12/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTagTextFieldContainerView.h"
#import "VSTagProxy.h"
#import "VSDetailView.h"


typedef struct {
	CGFloat bubbleHeight;
	CGFloat cornerRadius;
	CGFloat textMarginLeft;
	CGFloat textMarginRight;
	CGFloat fontSize;
	CGFloat outlineWidth;
} VSTagTextFieldLayoutBits;


@interface VSTagTextFieldContainerView ()

@property (nonatomic, assign) VSTagTextFieldLayoutBits layoutBits;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign, readwrite) BOOL editing;
@property (nonatomic, strong) UIColor *outlineColor;
@property (nonatomic, strong) UIColor *fillColor;

@end


@implementation VSTagTextFieldContainerView


#pragma mark - Class Methods

+ (VSTagTextFieldLayoutBits)layoutBits {
	
	VSTagTextFieldLayoutBits layoutBits;
	
	layoutBits.bubbleHeight = [app_delegate.theme floatForKey:@"tagBubbleHeight"];
	layoutBits.cornerRadius = [app_delegate.theme floatForKey:@"tagBubbleCornerRadius"];
	layoutBits.textMarginLeft = [app_delegate.theme floatForKey:@"tagBubbleTextMarginLeft"];
	layoutBits.textMarginRight = [app_delegate.theme floatForKey:@"tagBubbleTextMarginRight"];
	layoutBits.fontSize = [app_delegate.theme floatForKey:@"tagBubbleFontSize"];
	
	layoutBits.outlineWidth = [app_delegate.theme floatForKey:@"tagDetailEditingOutlineWidth"];
	if ([UIScreen mainScreen].scale >= 2.0f)
		layoutBits.outlineWidth = [app_delegate.theme floatForKey:@"tagDetailEditingOutlineWidthRetina"];
	
	return layoutBits;
}


+ (UIColor *)bubbleColor {
	return [app_delegate.theme colorForKey:@"tagDetailColor"];
}


+ (UIFont *)font {
	return [app_delegate.theme fontForKey:@"tagBubbleFont"];
}


+ (UIColor *)textColor {
	return [app_delegate.theme colorForKey:@"tagDetailEditingFontColor"];
}


static CGFloat kMinimumWidth = 46.0f;

+ (CGSize)initialSize {
	
	VSTagTextFieldLayoutBits layoutBits = [self layoutBits];
	CGFloat paddingLeft = layoutBits.textMarginLeft;
	CGFloat paddingRight = layoutBits.textMarginRight;
	
	CGFloat initialTextWidth = 18.0f;
	CGFloat buttonWidth = paddingLeft + initialTextWidth + paddingRight;
	if (buttonWidth < kMinimumWidth)
		buttonWidth = kMinimumWidth;
	
	CGSize buttonSize = CGSizeMake(buttonWidth, layoutBits.bubbleHeight);
	return buttonSize;
}


+ (NSAttributedString *)attributedStringWithTitle:(NSString *)title {
	
	if (title == nil)
		return nil;
	
	NSDictionary *attributes = @{NSFontAttributeName : [self font]};
	NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:attributes];
	
	return attString;
}


+ (CGFloat)widthOfTitle:(NSString *)title {
	
	if (QSStringIsEmpty(title))
		return 0.0f;
	
	NSAttributedString *attString = [self attributedStringWithTitle:title];
	return [attString size].width;
}


+ (CGSize)sizeWithTitle:(NSString *)title editing:(BOOL)editing {
	
	VSTagTextFieldLayoutBits layoutBits = [self layoutBits];
	CGFloat paddingLeft = layoutBits.textMarginLeft;
	CGFloat paddingRight = layoutBits.textMarginRight;
	
	CGFloat textWidth = [self widthOfTitle:title];
	if (textWidth < 18.0f)
		textWidth = 18.0f;
	CGFloat buttonWidth = paddingLeft + textWidth + paddingRight;
	if (buttonWidth < kMinimumWidth)
		buttonWidth = kMinimumWidth;
	if (editing) {
		buttonWidth += [app_delegate.theme floatForKey:@"tagDetailEditingTextPaddingRight"];
	}
	
	CGSize buttonSize = CGSizeMake(buttonWidth, layoutBits.bubbleHeight);
	return buttonSize;
}


+ (instancetype)tagTextFieldContainerViewWithTagProxy:(VSTagProxy *)tagProxy {
	
	CGRect r = CGRectZero;
	r.size = [self initialSize];
	
	VSTagTextFieldContainerView *view = [[VSTagTextFieldContainerView alloc] initWithFrame:r tagProxy:tagProxy];
	return view;
}


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame tagProxy:(VSTagProxy *)tagProxy {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_tagProxy = tagProxy;
	
	_layoutBits = [[self class] layoutBits];
	_outlineColor = [app_delegate.theme colorForKey:@"tagDetailEditingOutlineColor"];
	_fillColor = [app_delegate.theme colorForKey:@"tagDetailEditingFillColor"];
	
	_textField = [[UITextField alloc] initWithFrame:[self rectOfTextField]];
	_textField.textColor = [[self class] textColor];
	_textField.font = [[self class] font];
	_textField.minimumFontSize = _layoutBits.fontSize;
	_textField.borderStyle = UITextBorderStyleNone;
	_textField.opaque = NO;
	_textField.backgroundColor = [UIColor clearColor];
	_textField.autocorrectionType = UITextAutocorrectionTypeNo;
	_textField.returnKeyType = UIReturnKeyNext;
	_textField.contentMode = UIViewContentModeRedraw;
	_textField.tintColor = [app_delegate.theme colorForKey:@"tagDetailEditingTintColor"];
	
	if (!QSStringIsEmpty(tagProxy.name))
		_textField.text = tagProxy.name;
	
	_textField.delegate = self;
	[self addSubview:_textField];
	
	self.clearsContextBeforeDrawing = YES;
	self.contentMode = UIViewContentModeRedraw;
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	
	[self setNeedsLayout];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	_textField.delegate = nil;
}


#pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)size {
	
	/*Ignores size parameter.*/
	
	return [[self class] sizeWithTitle:self.textField.text editing:self.editing];
}


- (void)layoutSubviews {
	
	[super layoutSubviews];
	
	CGRect rTextField = [self rectOfTextField];
	[self.textField qs_setFrameIfNotEqual:rTextField];
}


#pragma mark - Layout

- (CGSize)textFieldSize {
	
	CGSize size = [self.textField sizeThatFits:CGSizeMake(1024.0f, 20.0f)];
	
	if (self.editing) {
		size.width += [app_delegate.theme floatForKey:@"tagDetailEditingTextPaddingRight"];
	}
	static const CGFloat minWidth = 32.0f;
	static const CGFloat minHeight = 17.0f;
	
	if (size.width < minWidth)
		size.width = minWidth;
	if (size.height < minHeight)
		size.height = minHeight;
	
	return size;
}


- (CGRect)rectOfTextField {
	
	CGRect rTextField = self.textField.frame;
	CGSize textFieldSizeThatFits = [self textFieldSize];
	
	CGFloat paddingLeft = self.layoutBits.textMarginLeft;
	
	rTextField.origin.x = paddingLeft + 0.5f;
	rTextField.origin.y = [app_delegate.theme floatForKey:@"tagDetailEditingTextOffsetY"];
	rTextField.origin.y += 0.5f;
	rTextField.size.width = textFieldSizeThatFits.width;
	rTextField.size.height = textFieldSizeThatFits.height;
	
	return rTextField;
}


- (void)updateSizeForView {
	[self qs_performSelectorViaResponderChain:@selector(updateSizeForView:) withObject:self];
}


#pragma mark - Tag proxy

- (void)updateTextForTagProxy {
	self.tagProxy.name = self.textField.text;
}


#pragma mark - Tag Suggestion View

- (void)updateTagSuggestionView {
	
	NSString *text = self.textField.text;
	[self qs_performSelectorViaResponderChain:@selector(updateTagSuggestionViewWithText:) withObject:text];
}


NSString *VSTagDidBeginEditingNotification = @"VSTagDidBeginEditingNotification";
NSString *VSTagKey = @"VSTagKey";

- (void)sendTagDidBeginEditingNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:VSTagDidBeginEditingNotification object:self userInfo:@{VSTagKey : self}];
	
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.editing = YES;
	self.tagProxy.isEditing = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:VSDidBecomeFirstResponderNotification object:self userInfo:@{VSResponderKey : self.textField}];
	[self sendTagDidBeginEditingNotification];
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
	self.editing = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:VSDidResignFirstResponderNotification object:self userInfo:@{VSResponderKey : textField}];
	[self updateTextForTagProxy];
	self.tagProxy.isEditing = NO;
	[self qs_performSelectorViaResponderChain:@selector(tagTextFieldDidEndEditing:) withObject:self];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	[self performSelectorOnMainThread:@selector(updateSizeForView) withObject:self waitUntilDone:NO];
	[self performSelector:@selector(updateTagSuggestionView) withObject:nil afterDelay:0.1];
	return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	BOOL isEmpty = QSStringIsEmpty(textField.text);
	if (isEmpty)
		[self performSelectorOnMainThread:@selector(endEditing) withObject:nil waitUntilDone:NO];
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName:VSFastSwitchFirstResponderNotification object:self userInfo:nil];
		[[self nextResponder] qs_performSelectorViaResponderChain:@selector(ghostTagButtonTapped:) withObject:nil];
	}
	return NO;
}


#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
	
	[super drawRect:rect];
	
	UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layoutBits.cornerRadius];
 
	[self.fillColor set];
	[bezierPath fill];
	
	CGRect r = self.bounds;
	r = CGRectInset(r, 1.0f, 1.0f);
	UIBezierPath *bezierPathForStroke = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:self.layoutBits.cornerRadius];
	[self.outlineColor set];
	[bezierPathForStroke stroke];
}


#pragma mark - API

- (void)beginEditing {
	self.editing = YES;
	[self.textField becomeFirstResponder];
}


- (NSString *)text {
	return self.textField.text;
}


- (void)endEditing {
	self.editing = NO;
	[self updateTextForTagProxy];
	[self.textField resignFirstResponder];
}


- (BOOL)endEditing:(BOOL)force {
	self.editing = [super endEditing:force];
	return self.editing;
}

- (void)setUserAcceptedSuggestedTag:(NSString *)userAcceptedSuggestedTag {
	_userAcceptedSuggestedTag = userAcceptedSuggestedTag;
	self.textField.text = userAcceptedSuggestedTag;
	[self updateTextForTagProxy];
}


@end

