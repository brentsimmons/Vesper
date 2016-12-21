//
//  VSNavbarView.m
//  Vesper
//
//  Created by Brent Simmons on 2/6/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSNavbarView.h"
#import "VSNavbarButton.h"
#import "UIView+RSExtras.h"
#import "VSTypographySettings.h"


@interface VSNavbarView ()

@end


@implementation VSNavbarView


#pragma mark Init

- (void)commonInit {
	
	_showComposeButton = YES;
	self.backgroundColor = [UIColor clearColor];
	
	[self setupControls];
	
	[self setNeedsLayout];
	
	[self addObserver:self forKeyPath:@"showComposeButton" options:0 context:nil];
	[self addObserver:self forKeyPath:@"title" options:0 context:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typographySettingsDidChange:) name:VSTypographySettingsDidChangeNotification object:nil];
	
	self.backgroundColor = [[self class] backgroundColor];
}


- (id)init {
	CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
	return [self initWithFrame:CGRectMake(0.0f, 0.0f, screenWidth, RSNavbarPlusStatusBarHeight())];
}


- (id)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	[self commonInit];
	return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
	
	self = [super initWithCoder:aDecoder];
	if (self == nil)
		return nil;
	
	[self commonInit];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"showComposeButton"];
	[self removeObserver:self forKeyPath:@"title"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"showComposeButton"] && object == self)
		self.composeButton.hidden = !self.showComposeButton;
	
	else if ([keyPath isEqualToString:@"title"] && object == self) {
		NSDictionary *attributes = @{NSFontAttributeName : self.titleField.font, NSForegroundColorAttributeName : self.titleField.textColor, NSLigatureAttributeName : @1, NSKernAttributeName : [NSNull null]};
		NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:self.title attributes:attributes];
		self.titleField.attributedText = titleString;
	}
}


#pragma mark - Notifications

- (void)typographySettingsDidChange:(NSNotification *)note {
	[self updateTitleField];
}


#pragma mark - Class Methods

+ (UIColor *)backgroundColor {
	return [app_delegate.theme colorForKey:@"navbarBackgroundColor"];
}


+ (UIImage *)sidebarImage {
	
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *imageName = [app_delegate.theme stringForKey:@"navbarSidebarButton"];
		image = [UIImage imageNamed:imageName];
	});
	
	return image;
}


+ (UIImage *)sidebarImagePressed {
	
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *imageName = [app_delegate.theme stringForKey:@"navbarSidebarButtonPressed"];
		image = [UIImage imageNamed:imageName];
	});
	
	return image;
}


+ (UIImage *)composeImage {
	
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *imageName = [app_delegate.theme stringForKey:@"navbarComposeButton"];
		image = [UIImage imageNamed:imageName];
	});
	
	return image;
}


+ (UIImage *)composeImagePressed {
	
	static UIImage *image = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *imageName = [app_delegate.theme stringForKey:@"navbarComposeButtonPressed"];
		image = [UIImage imageNamed:imageName];
	});
	
	return image;
}


+ (UIColor *)buttonTintColor {
	return [app_delegate.theme colorForKey:@"navbarButtonColor"];
}


+ (UIColor *)navbarTitleColor {
	return [app_delegate.theme colorForKey:@"navbarTitleColor"];
}


#pragma mark Controls

- (UIFont *)titleFieldFont {
	
	UIFont *font = [app_delegate.theme fontForKey:@"navbarTitleFont"];
	if (VSDefaultsTextWeight() == VSTextWeightLight)
		font = [app_delegate.theme fontForKey:@"navbarTitleLightFont"];
	
	return font;
}


- (void)updateTitleField {
	
	self.titleField.font = [self titleFieldFont];
	[self setNeedsLayout];
	[self.titleField setNeedsDisplay];
}


- (void)setupControls {
	
	static UIColor *buttonTintColor = nil;
	static UIColor *buttonTintColorPressed = nil;
	static UIImage *sidebarImage = nil;
	static UIImage *sidebarImagePressed = nil;
	static UIImage *composeImage = nil;
	static UIImage *composeImagePressed = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		buttonTintColor = [[self class] buttonTintColor];
		buttonTintColorPressed = VSPressedColor(buttonTintColor);
		
		sidebarImage = [[[self class] sidebarImage] qs_imageTintedWithColor:buttonTintColor];
		sidebarImagePressed = [[[self class] sidebarImage] qs_imageTintedWithColor:buttonTintColorPressed];
		
		composeImage = [[[self class] composeImage] qs_imageTintedWithColor:buttonTintColor];
		composeImagePressed = [[[self class] composeImage] qs_imageTintedWithColor:buttonTintColorPressed];
	});
	
	
	self.sidebarButton = [VSNavbarButton navbarButtonWithImage:sidebarImage selectedImage:nil highlightedImage:sidebarImagePressed];
	self.sidebarButton.accessibilityLabel = NSLocalizedString(@"List", nil);
	// TODO: this needs to be updated when the sidebar is opened and put back when it's closed
	self.sidebarButton.accessibilityHint = NSLocalizedString(@"Double tap to open the sidebar", nil);
	[self.sidebarButton addTarget:nil action:@selector(toggleSidebar:) forControlEvents:UIControlEventTouchUpInside];
	self.sidebarButton.imageEdgeInsets = UIEdgeInsetsMake(2.0f, 0.0f, 0.0f, 0.0f);
	[self addSubview:self.sidebarButton];
	
	self.composeButton = [VSNavbarButton navbarButtonWithImage:composeImage selectedImage:nil highlightedImage:composeImagePressed];
	self.composeButton.accessibilityLabel = NSLocalizedString(@"Compose", nil);
	self.composeButton.accessibilityHint = NSLocalizedString(@"Double tap to compose a new note", nil);
	[self addSubview:self.composeButton];
	[self.composeButton addTarget:nil action:@selector(showComposeView:) forControlEvents:UIControlEventTouchUpInside];
	
	CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
	CGRect bounds = CGRectMake(0.0f, 0.0f, screenWidth, RSNavbarPlusStatusBarHeight());
	self.titleField = [[UILabel alloc] initWithFrame:bounds];
	self.titleField.backgroundColor = [UIColor clearColor];
	self.titleField.textAlignment = NSTextAlignmentCenter;
	
	self.titleField.font = [self titleFieldFont];
	
	self.titleField.textColor = [[self class] navbarTitleColor];
	
	[self addSubview:self.titleField];
	
}


#pragma mark - Alpha

- (void)setAlphaForSubviews:(CGFloat)alpha {
	
	for (UIView *oneSubview in self.subviews)
		oneSubview.alpha = alpha;
}


#pragma mark - Animations

- (UIImage *)imageForAnimation:(BOOL)includeRightmostButton {
	
	CGSize size = self.bounds.size;
	if (!includeRightmostButton) {
		CGRect r = self.composeButton.frame;
		size.width = CGRectGetMinX(r) - 1.0f;
	}
	
	UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
	
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return image;
	
}

#pragma mark Layout

- (CGFloat)statusBarHeight {
	return VSNormalStatusBarHeight();
}


- (CGFloat)heightMinusStatusBar {
	
	CGFloat statusbarHeight = VSNormalStatusBarHeight();
	CGFloat heightMinusStatusBar = self.bounds.size.height - statusbarHeight;
	return heightMinusStatusBar;
}


static const CGFloat VSSidebarButtonX = 0.0f;
static const CGFloat VSSidebarButtonY = 0.0f;
static const CGFloat VSTitleX = 48.0f;
static const CGFloat VSTitleY = 8.0f;
//static const CGFloat VSTitleWidth = 225.0f;
static const CGFloat VSTitleWidthMinusScreenWidth = 95.0f;
static const CGFloat VSTitleHeight = 28.0f;

- (CGRect)rectForTitleField {
	
	CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
	CGFloat titleWidth = screenWidth - VSTitleWidthMinusScreenWidth;
	CGRect r = CGRectMake(VSTitleX, VSTitleY, titleWidth, VSTitleHeight);
	r.origin.y += self.statusBarHeight;
	
	return r;
}


- (void)layoutSubviews {
	
	[super layoutSubviews];
	
	CGRect rButton = CGRectMake(VSSidebarButtonX, VSSidebarButtonY, 51.0f, self.heightMinusStatusBar);
	rButton.origin.y += self.statusBarHeight;
	
	[self.sidebarButton qs_setFrameIfNotEqual:rButton];
	
	CGFloat composeButtonMarginRight = [app_delegate.theme floatForKey:@"timelinePlusButtonMarginRight"];
	CGFloat composeButtonWidth = [app_delegate.theme floatForKey:@"timelinePlusButtonWidth"];
	CGFloat composeButtonOriginX = CGRectGetMaxX(self.bounds) - (composeButtonWidth + composeButtonMarginRight);
	rButton = CGRectMake(composeButtonOriginX, 0.0f, composeButtonWidth, self.heightMinusStatusBar);
	rButton.origin.y += self.statusBarHeight;
	[self.composeButton qs_setFrameIfNotEqual:rButton];
	
	[self.titleField qs_setFrameIfNotEqual:[self rectForTitleField]];
	
	if (!self.showComposeButton)
		self.composeButton.hidden = YES;
	
}


@end
