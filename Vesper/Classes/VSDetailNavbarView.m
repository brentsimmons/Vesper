//
//  VSDetailNavbarView.m
//  Vesper
//
//  Created by Brent Simmons on 4/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSDetailNavbarView.h"
#import "VSNavbarButton.h"


typedef struct {
	CGFloat plusButtonWidth;
	CGFloat plusButtonMarginRight;
	CGFloat activityButtonWidth;
	CGFloat activityButtonMarginRight;
	CGFloat cameraButtonWidth;
	CGFloat cameraButtonMarginRight;
	CGFloat keyboardButtonWidth;
} VSDetailNavbarLayoutBits;


static VSDetailNavbarLayoutBits navbarLayoutBits(VSTheme *theme) {
	
	VSDetailNavbarLayoutBits layoutBits;
	
	layoutBits.plusButtonWidth = [theme floatForKey:@"detailPlusButtonWidth"];
	layoutBits.plusButtonMarginRight = [theme floatForKey:@"detailPlusButtonMarginRight"];
	layoutBits.activityButtonWidth = [theme floatForKey:@"detailActivityButtonWidth"];
	layoutBits.activityButtonMarginRight = [theme floatForKey:@"detailActivityButtonMarginRight"];
	layoutBits.cameraButtonWidth = [theme floatForKey:@"detailCameraButtonWidth"];
	layoutBits.cameraButtonMarginRight = [theme floatForKey:@"detailCameraButtonMarginRight"];
	layoutBits.keyboardButtonWidth = [theme floatForKey:@"detailKeyboardButtonWidth"];
 
	return layoutBits;
}


@interface VSDetailNavbarView ()

@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIButton *plusButton;
@property (nonatomic, strong, readwrite) UIButton *activityButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) NSString *backButtonTitle;
@property (nonatomic, assign) VSDetailNavbarLayoutBits layoutBits;
@property (nonatomic, strong) NSTimer *buttonSwapTimer;
@property (nonatomic, strong, readwrite) UIImageView *panbackChevron;
@property (nonatomic, strong, readwrite) UILabel *panbackLabel;

@end


@implementation VSDetailNavbarView


#pragma mark Init

- (id)initWithFrame:(CGRect)frame backButtonTitle:(NSString *)backButtonTitle {
	
	_backButtonTitle = backButtonTitle;
	
	self = [self initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_layoutBits = navbarLayoutBits(app_delegate.theme);
	
	[self addObserver:self forKeyPath:@"editMode" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"readonly" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"panbackPercent" options:0 context:NULL];
	[self setNeedsLayout];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	
	if (_buttonSwapTimer != nil) {
		[_buttonSwapTimer qs_invalidateIfValid];
		_buttonSwapTimer = nil;
	}
	
	[self removeObserver:self forKeyPath:@"editMode"];
	[self removeObserver:self forKeyPath:@"readonly"];
	[self removeObserver:self forKeyPath:@"panbackPercent"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"editMode"]) {
		[self updateUI];
	}
	
	else if ([keyPath isEqualToString:@"readonly"]) {
		self.plusButton.hidden = self.readonly;
		self.cameraButton.hidden = self.readonly;
		[self setNeedsLayout];
	}
	
	else if ([keyPath isEqualToString:@"panbackPercent"]) {
		[self updatePositionsForPanbackInteraction];
	}
}


#pragma mark Buttons


- (void)displayKeyboardButton {
	
	[self.plusButton removeFromSuperview];
	[self addSubview:self.doneButton];
	[self layout];
	self.editMode = YES;
}


- (void)animateSwappingButtons:(UIButton *)buttonIncoming button2:(UIButton *)buttonOutgoing {
	
	NSTimeInterval duration = [app_delegate.theme timeIntervalForKey:@"detailNavbarButtonSwapAnimationDuration"];
	
	if ([buttonOutgoing isDescendantOfView:self]) {
		
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		[UIView animateWithDuration:duration animations:^{
			buttonOutgoing.alpha = 0.0f;
		} completion:^(BOOL finished) {
			[buttonOutgoing removeFromSuperview];
			buttonOutgoing.alpha = 1.0f;
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		}];
	}
	
	if (![buttonIncoming isDescendantOfView:self]) {
		
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		[self addSubview:buttonIncoming];
		buttonIncoming.alpha = 0.0f;
		
		NSTimeInterval animationPart2Delay = [app_delegate.theme timeIntervalForKey:@"detailNavbarButtonSwapAnimationDelay"];
		
		[UIView animateWithDuration:duration delay:animationPart2Delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
			buttonIncoming.alpha = 1.0f;
		} completion:^(BOOL finished) {
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		}];
	}
}


static NSString *kButtonIncomingKey = @"kButtonIncomingKey";
static NSString *kButtonOutgoingKey = @"kButtonOutgoingKey";

- (void)buttonSwapTimerDidFire:(NSTimer *)timer {
	
	UIButton *buttonIncoming = [timer userInfo][kButtonIncomingKey];
	UIButton *buttonOutgoing = [timer userInfo][kButtonOutgoingKey];
	
	[self animateSwappingButtons:buttonIncoming button2:buttonOutgoing];
	
	if (self.buttonSwapTimer != nil) {
		[self.buttonSwapTimer qs_invalidateIfValid];
		self.buttonSwapTimer = nil;
	}
}


- (void)coalescedAnimateSwappingButtons:(UIButton *)buttonIncoming button2:(UIButton *)buttonOutgoing {
	
	if (buttonIncoming == nil || buttonOutgoing == nil)
		return;
	
	if (self.buttonSwapTimer != nil)
		[self.buttonSwapTimer qs_invalidateIfValid];
	
	NSDictionary *userInfo = @{kButtonIncomingKey : buttonIncoming, kButtonOutgoingKey : buttonOutgoing};
	self.buttonSwapTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(buttonSwapTimerDidFire:) userInfo:userInfo repeats:NO];
}


- (void)updateUI {
	
	BOOL buttonSwapPending = (self.buttonSwapTimer != nil);
	
	[self.doneButton qs_setFrameIfNotEqual:[self rectOfDoneButton]];
	[self.plusButton qs_setFrameIfNotEqual:[self rectOfPlusButton]];
	
	BOOL plusButtonShowing = [self.plusButton isDescendantOfView:self];
	BOOL keyboardButtonShowing = [self.doneButton isDescendantOfView:self];
	
	if (self.editMode) {
		if (buttonSwapPending || (plusButtonShowing || !keyboardButtonShowing))
			[self coalescedAnimateSwappingButtons:self.doneButton button2:self.plusButton];
	}
	else {
		if (buttonSwapPending || (!plusButtonShowing || keyboardButtonShowing))
			[self coalescedAnimateSwappingButtons:self.plusButton button2:self.doneButton];
	}
}


- (void)setupControls {
	
	self.backButton = [VSNavbarBackButton buttonWithTitle:self.backButtonTitle];
	[self.backButton addTarget:nil action:@selector(detailViewDone:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.backButton];
	
	static UIColor *buttonTintColor = nil;
	static UIColor *buttonTintColorPressed = nil;
	static UIImage *doneButtonImage = nil;
	static UIImage *doneButtonImagePressed = nil;
	static UIImage *activityImage = nil;
	static UIImage *activityImagePressed = nil;
	static UIImage *plusImage = nil;
	static UIImage *plusImagePressed = nil;
	static UIImage *cameraImage = nil;
	static UIImage *cameraImagePressed = nil;
	static UIImage *sidebarImage = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		buttonTintColor = [app_delegate.theme colorForKey:@"navbarButtonColor"];
		buttonTintColorPressed = VSPressedColor(buttonTintColor);
		
		doneButtonImage = [[UIImage imageNamed:@"keyboard"] qs_imageTintedWithColor:buttonTintColor];
		doneButtonImagePressed = [[UIImage imageNamed:@"keyboard"] qs_imageTintedWithColor:buttonTintColorPressed];
		
		activityImage = [[UIImage imageNamed:@"activity"] qs_imageTintedWithColor:buttonTintColor];
		activityImagePressed = [[UIImage imageNamed:@"activity"] qs_imageTintedWithColor:buttonTintColorPressed];
		
		plusImage = [[UIImage imageNamed:@"addbutton"] qs_imageTintedWithColor:buttonTintColor];
		plusImagePressed = [[UIImage imageNamed:@"addbutton"] qs_imageTintedWithColor:buttonTintColorPressed];
		
		cameraImage = [[UIImage imageNamed:@"camera"] qs_imageTintedWithColor:buttonTintColor];
		cameraImagePressed = [[UIImage imageNamed:@"camera"] qs_imageTintedWithColor:buttonTintColorPressed];
		
		sidebarImage = [[[self class] sidebarImage] qs_imageTintedWithColor:[[self class] buttonTintColor]];
	});
	
	self.doneButton = [VSNavbarButton navbarButtonWithImage:doneButtonImage selectedImage:nil highlightedImage:doneButtonImagePressed];
	self.doneButton.frame = [self rectOfDoneButton];
	[self.doneButton addTarget:self action:@selector(detailViewEndEditing:) forControlEvents:UIControlEventTouchUpInside];
	self.doneButton.accessibilityLabel = NSLocalizedString(@"Done", nil);
	self.doneButton.accessibilityHint = NSLocalizedString(@"Double tap to finish editing this note", nil);
 
	self.activityButton = [VSNavbarButton navbarButtonWithImage:activityImage selectedImage:nil highlightedImage:activityImagePressed];
	self.activityButton.accessibilityLabel = NSLocalizedString(@"Share", nil);
	self.activityButton.accessibilityHint = NSLocalizedString(@"Double tap to take a share this note", nil);
	[self.activityButton addTarget:self action:@selector(detailActivityButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[self.activityButton sizeToFit];
	[self addSubview:self.activityButton];
 
	self.plusButton = [VSNavbarButton navbarButtonWithImage:plusImage selectedImage:nil highlightedImage:plusImagePressed];
	self.plusButton.accessibilityLabel = NSLocalizedString(@"Compose", nil);
	self.plusButton.accessibilityHint = NSLocalizedString(@"Double tap to compose a new note", nil);
	[self.plusButton addTarget:nil action:@selector(plusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	self.plusButton.frame = [self rectOfPlusButton];
	[self addSubview:self.plusButton];
	
	self.cameraButton = [VSNavbarButton navbarButtonWithImage:cameraImage selectedImage:nil highlightedImage:cameraImagePressed];
	self.cameraButton.accessibilityLabel = NSLocalizedString(@"Camera", nil);
	self.cameraButton.accessibilityHint = NSLocalizedString(@"Double tap to take a picture for this note", nil);
	[self.cameraButton addTarget:nil action:@selector(cameraButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.cameraButton];
	
	/*Pan-back*/
	
	self.panbackChevron = [[UIImageView alloc] initWithImage:sidebarImage];
	self.panbackChevron.contentMode = UIViewContentModeTopLeft;
	[self addSubview:self.panbackChevron];
	self.panbackChevron.hidden = YES;
	
	CGRect rLabel = [self rectOfPanbackLabel];
	UILabel *label = [[UILabel alloc] initWithFrame:rLabel];
	label.attributedText = self.backButton.titleLabel.attributedText;
	[self addSubview:label];
	self.panbackLabel = label;
	self.panbackLabel.hidden = YES;
	self.panbackLabel.alpha = 0.0f;
	
	CGRect bounds = CGRectMake(0.0f, 0.0f, self.bounds.size.width, RSNavbarPlusStatusBarHeight());
	self.titleField = [[UILabel alloc] initWithFrame:bounds];
	self.titleField.backgroundColor = [UIColor clearColor];
	self.titleField.textAlignment = NSTextAlignmentCenter;
	self.titleField.font = [self titleFieldFont];
	self.titleField.textColor = [[self class] navbarTitleColor];
	self.titleField.text = self.backButtonTitle;
	[self addSubview:self.titleField];
	self.titleField.hidden = YES;
	
	
	[self updateUI];
	[self setNeedsLayout];
}


#pragma mark - Animation

- (UIImage *)imageForAnimation:(BOOL)includePlusButton {
	
	[self layoutSubviews];
	
	CGSize size = self.bounds.size;
	if (!includePlusButton && !self.readonly) {
		CGFloat composeButtonX = self.plusButton.frame.origin.x;
		size.width = composeButtonX - 1.0f;
	}
	
	UIColor *originalBackgroundColor = self.backgroundColor;
	self.backgroundColor = [UIColor clearColor];
	
	UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
	
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	self.backgroundColor = originalBackgroundColor;
	
	return image;
}


#pragma mark - Panback Interaction

- (void)updatePositionsForPanbackInteraction {
	
	CGFloat alpha = 1.0f - (self.panbackPercent * 2.0f);
	self.cameraButton.alpha = alpha;
	self.activityButton.alpha = alpha;
	
	/*Panback label.*/
	
	if (self.panbackPercent < 0.5f) {
		self.panbackLabel.alpha = 1.0f - (self.panbackPercent * 2.0f);
		self.titleField.alpha = 0.0f;
		
		CGRect r = [self rectOfPanbackLabel];
		CGRect rTitleField = self.rectForTitleField;
		CGFloat xDistance = CGRectGetMinX(rTitleField) - CGRectGetMinX(r);
		xDistance += [app_delegate.theme floatForKey:@"detailPan.noteTitleLabelDestinationOffsetX"];
		r.origin.x = r.origin.x + (xDistance * self.panbackPercent * 2.0f);
		[self.panbackLabel qs_setFrameIfNotEqual:r];
		
		[self.titleField qs_setFrameIfNotEqual:self.rectForTitleField];
	}
	
	else {
		self.panbackLabel.alpha = 0.0f;
		self.titleField.alpha = (self.panbackPercent - 0.5f) * 2.0f;
		
		CGRect rPanback = [self rectOfPanbackLabel];
		CGRect rTitleField = self.rectForTitleField;
		CGFloat offsetX = [app_delegate.theme floatForKey:@"detailPan.timelineTitleLabelSourceOffsetX"];
		rPanback.origin.x += offsetX;
		CGFloat xDistance = CGRectGetMinX(rTitleField) - CGRectGetMinX(rPanback);
		rTitleField.origin.x = rPanback.origin.x + (xDistance * self.panbackPercent);
		[self.titleField qs_setFrameIfNotEqual:rTitleField];
	}
}


#pragma mark - Actions

- (void)detailViewEndEditing:(id)sender {
	
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(detailViewEndEditing:) withObject:sender];
}


- (void)detailActivityButtonTapped:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(detailActivityButtonTapped:) withObject:sender];
}


- (void)plusButtonTapped:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(plusButtonTapped:) withObject:sender];
}


#pragma mark UIView

- (CGRect)rectOfBackButton {
	
	CGRect r = CGRectZero;
	r.size = [VSNavbarBackButton sizeWithTitle:self.backButtonTitle];
	r.origin = [app_delegate.theme pointForKey:@"navbarBackButtonOrigin"];
	r.origin.y += self.statusBarHeight;
	return r;
}


- (CGRect)rectOfDoneButton {
	
	/*Keyboard button*/
	
	CGRect r = CGRectZero;
	r.size.width = self.layoutBits.keyboardButtonWidth;
	r.origin.x = CGRectGetMaxX(self.bounds) - r.size.width;
	r.size.height = self.heightMinusStatusBar;
	r.origin.y += self.statusBarHeight;
	return r;
}


- (CGRect)rectOfPlusButton {
	
	CGRect r = CGRectZero;
	r.size.width = self.layoutBits.plusButtonWidth;
	r.origin.x = CGRectGetMaxX(self.bounds) - (self.layoutBits.plusButtonMarginRight + r.size.width);
	r.size.height = self.heightMinusStatusBar;
	r.origin.y += self.statusBarHeight;
	return r;
}


- (CGRect)rectOfActivityButton {
	
	CGRect rNext = CGRectZero;
	if (self.editMode)
		rNext = [self rectOfDoneButton];
	else
		rNext = [self rectOfPlusButton];
	
	CGRect r = CGRectZero;
	r.size.width = self.layoutBits.activityButtonWidth;
	
	r.origin.x = CGRectGetMinX(rNext) - (self.layoutBits.activityButtonMarginRight + r.size.width);
	if (self.readonly) /*activity on right*/
		r.origin.x = CGRectGetMaxX(self.bounds) - r.size.width;
	
	r.size.height = self.heightMinusStatusBar;
	r.origin.y += self.statusBarHeight;
	return r;
}


- (CGRect)rectOfCameraButton {
	
	CGRect rNext = [self rectOfActivityButton];
	CGRect r = CGRectZero;
	r.size.width = self.layoutBits.cameraButtonWidth;
	r.origin.x = CGRectGetMinX(rNext) - (self.layoutBits.cameraButtonMarginRight + r.size.width);
	r.size.height = self.heightMinusStatusBar;
	r.origin.y += self.statusBarHeight;
	return r;
}


- (CGRect)rectOfPanbackChevron {
	
	CGRect r = CGRectZero;
	r.origin.x = 7.0f;
	r.origin.y = self.statusBarHeight + 7.5f;
	r.size = self.panbackChevron.image.size;
	
	return r;
}


- (CGRect)rectOfPanbackLabel {
	
	CGRect r = self.backButton.titleLabel.frame;
	r = [self convertRect:r fromView:self.backButton.titleLabel.superview];
	return r;
}


- (void)layout {
	
	CGRect rBackButton = [self rectOfBackButton];
	[self.backButton qs_setFrameIfNotEqual:rBackButton];
	
	CGRect rDoneButton = [self rectOfDoneButton];
	[self.doneButton qs_setFrameIfNotEqual:rDoneButton];
	
	CGRect rPlusButton = [self rectOfPlusButton];
	[self.plusButton qs_setFrameIfNotEqual:rPlusButton];
	
	CGRect rActivity = [self rectOfActivityButton];
	[self.activityButton qs_setFrameIfNotEqual:rActivity];
	
	CGRect rCamera = [self rectOfCameraButton];
	[self.cameraButton qs_setFrameIfNotEqual:rCamera];
	
	CGRect rPanbackChevron = [self rectOfPanbackChevron];
	[self.panbackChevron qs_setFrameIfNotEqual:rPanbackChevron];
}


- (void)layoutSubviews {
	[self layout];
}


@end

