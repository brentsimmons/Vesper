//
//  VSPictureNavbarView.m
//  Vesper
//
//  Created by Brent Simmons on 4/16/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSPictureNavbarView.h"
#import "VSNavbarButton.h"


typedef struct {
	CGFloat trashMarginBottom;
	CGFloat trashMarginLeft;
	CGFloat trashMarginRight;
	CGFloat trashWidth;
	CGFloat trashHeight;
	CGFloat doneButtonMarginLeft;
} VSPictureNavbarLayoutBits;


static VSPictureNavbarLayoutBits pictureViewControllerLayoutBits(VSTheme *theme) {
	
	VSPictureNavbarLayoutBits layoutBits;
	
	layoutBits.trashMarginBottom = [theme floatForKey:@"photoDetailTrashMarginBottom"];
	layoutBits.trashMarginLeft = [theme floatForKey:@"photoDetailTrashMarginLeft"];
	layoutBits.trashMarginRight = [theme floatForKey:@"photoDetailTrashMarginRight"];
	layoutBits.trashWidth = [theme floatForKey:@"photoDetailTrashWidth"];
	layoutBits.trashHeight = [theme floatForKey:@"photoDetailTrashHeight"];
	layoutBits.doneButtonMarginLeft = [theme floatForKey:@"photoDetailDoneButtonMarginLeft"];
	
	return layoutBits;
}



@interface VSPictureNavbarView ()

@property (nonatomic, strong) NSString *backButtonTitle;
@property (nonatomic, strong) NSString *trashButtonTitle;
@property (nonatomic, strong) VSPhotoTextButton *backButton;
@property (nonatomic, strong, readwrite) UIButton *trashButton;
@property (nonatomic, assign) VSPictureNavbarLayoutBits layoutBits;
@property (nonatomic, strong) UIView *backgroundView;
@end


@implementation VSPictureNavbarView

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_layoutBits = pictureViewControllerLayoutBits(app_delegate.theme);
	
	UIColor *backgroundColor = [app_delegate.theme colorForKey:@"photoDetailToolbarColor"];
	backgroundColor = [backgroundColor colorWithAlphaComponent:[app_delegate.theme floatForKey:@"photoDetailToolbarAlpha"]];
	self.backgroundColor = backgroundColor;
	
	[self addSubview:_backgroundView];
	
	return self;
}


#pragma mark - VSNavbarView

- (void)setupControls {
	
	self.backButtonTitle = NSLocalizedString(@"Done", @"Done");
	self.trashButtonTitle = NSLocalizedString(@"Delete", @"Delete");
	
	self.backButton = [VSPhotoTextButton buttonWithTitle:self.backButtonTitle];
	[self.backButton addTarget:self action:@selector(pictureDetailViewDone:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.backButton];
	
	UIImage *trashImage = [UIImage imageNamed:@"trash"];
	UIImage *trashPressedImage = [UIImage imageNamed:@"trash"];
	
	UIColor *tintColor = [app_delegate.theme colorForKey:@"navbarButtonColor"];
	UIColor *tintColorPressed = VSPressedColor(tintColor);
	trashImage = [trashImage qs_imageTintedWithColor:tintColor];
	trashPressedImage = [trashPressedImage qs_imageTintedWithColor:tintColorPressed];
	
	self.trashButton = [VSNavbarButton navbarButtonWithImage:trashImage selectedImage:nil highlightedImage:trashPressedImage];
	[self.trashButton addTarget:self action:@selector(trashButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.trashButton];
	self.trashButton.frame = [self rectOfTrashButtonWithBounds:self.bounds];
	
	[self setNeedsLayout];
}


#pragma mark - Actions

- (void)pictureDetailViewDone:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(pictureDetailViewDone:) withObject:sender];
}


- (void)pictureDetailDeleteAttachment:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(pictureDetailDeleteAttachment) withObject:sender];
}


- (void)trashButtonTapped:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(trashButtonTapped:) withObject:sender];
}


#pragma mark - UIView

- (BOOL)isOpaque {
	return NO;
}


- (CGRect)rectOfTrashButtonWithBounds:(CGRect)bounds {
	
	CGRect r = CGRectZero;
	
	r.size.width = self.layoutBits.trashWidth;
	r.size.height = self.layoutBits.trashHeight;
	r.origin.x = CGRectGetMaxX(bounds) - self.layoutBits.trashMarginRight;
	r.origin.x -= r.size.width;
	
	bounds.origin.y += VSNormalStatusBarHeight();
	bounds.size.height -= VSNormalStatusBarHeight();
	r = CGRectCenteredVerticallyInRect(r, bounds);
	
	return r;
}


- (void)layoutSubviews {
	
	CGRect rBounds = self.bounds;
	
	[self.backgroundView qs_setFrameIfNotEqual:rBounds];
	[self sendSubviewToBack:self.backgroundView];
	
	CGRect rBackButton = CGRectZero;
	CGSize backButtonSize = [VSPhotoTextButton sizeWithTitle:self.backButtonTitle];
	rBackButton.size = backButtonSize;
	rBackButton.origin.x = self.layoutBits.doneButtonMarginLeft;
	rBackButton.origin.y = VSNormalStatusBarHeight();
	[self.backButton qs_setFrameIfNotEqual:rBackButton];
	
	[self.trashButton qs_setFrameIfNotEqual:[self rectOfTrashButtonWithBounds:rBounds]];
}


- (void)drawRect:(CGRect)rect {
	
	[self.backgroundColor set];
	UIRectFill(rect);
}


@end
