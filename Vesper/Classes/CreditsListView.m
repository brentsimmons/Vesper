//
//  CreditsListView.m
//  Vesper
//
//  Created by Brent Simmons on 7/24/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "CreditsListView.h"


@interface CreditsListView ()

@property (nonatomic) UIImageView *listImageView;
@property (nonatomic) UIButton *supportButton;
@property (nonatomic) UILabel *versionLabel;

@end


@implementation CreditsListView


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self) {
		return nil;
	}

	_listImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"thanks"]];
	[self addSubview:_listImageView];


	_supportButton = [UIButton buttonWithType:UIButtonTypeCustom];

	UIFont *creditFont = [app_delegate.theme fontForKey:@"creditFont"];
	NSString *labelText = NSLocalizedString(@"For news and support, visit vesperapp.co.", nil);
	NSDictionary *atts = @{NSFontAttributeName : creditFont};
	NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithString:labelText attributes:atts];
	NSMutableAttributedString *buttonTitlePressed = [[NSMutableAttributedString alloc] initWithString:labelText attributes:atts];

	NSDictionary *linkAtts = @{NSForegroundColorAttributeName : [app_delegate.theme colorForKey:@"creditsLinkColor"]};
	NSDictionary *linkPressedAtts = @{NSForegroundColorAttributeName : [app_delegate.theme colorForKey:@"creditsLinkPressedColor"]};
	NSRange linkRange = [labelText rangeOfString:@"vesperapp.co"];

	[buttonTitle addAttributes:linkAtts range:linkRange];
	[buttonTitlePressed addAttributes:linkPressedAtts range:linkRange];

	[_supportButton setAttributedTitle:buttonTitle forState:UIControlStateNormal];
	[_supportButton setAttributedTitle:buttonTitlePressed forState:UIControlStateSelected];
	[_supportButton setAttributedTitle:buttonTitlePressed forState:UIControlStateHighlighted];

	[_supportButton addTarget:nil action:@selector(openVesperHomePage:) forControlEvents:UIControlEventTouchUpInside];

	_supportButton.adjustsImageWhenHighlighted = NO;
	_supportButton.adjustsImageWhenDisabled = NO;

	[self addSubview:_supportButton];
	[_supportButton sizeToFit];

	_versionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	_versionLabel.opaque = NO;
	_versionLabel.backgroundColor = [UIColor clearColor];
	_versionLabel.textAlignment = NSTextAlignmentCenter;
	_versionLabel.font = [app_delegate.theme fontForKey:@"creditsVersionFont"];
	_versionLabel.textColor = [app_delegate.theme colorForKey:@"creditsVersionFontColor"];

	NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString *buildText = NSLocalizedString(@"build", @"build");

	NSString *versionLabelString = [NSString stringWithFormat:@"%@ %@ (%@)", buildText, version, build];
#if __LP64__
	versionLabelString = [NSString stringWithFormat:@"%@ 64-bit", versionLabelString];
#endif
	_versionLabel.text = versionLabelString;
	[self insertSubview:_versionLabel aboveSubview:_supportButton];
	[_versionLabel sizeToFit];

	return self;
}


#pragma mark - Layout

- (CGRect)rectOfListImageView {

	CGSize imageSize = self.listImageView.image.size;
	CGRect r = CGRectZero;
	r.size = imageSize;

	r = CGRectCenteredHorizontallyInRect(r, self.bounds);
	r = CGRectIntegral(r);
	r.size = imageSize;

	return r;
}


static const CGFloat CreditsListViewSupportButtonMarginTop = -60.0f;

- (CGRect)rectOfSupportButton {

	CGRect rList = [self rectOfListImageView];
	CGRect r = self.supportButton.frame;

	r.origin.y = CGRectGetMaxY(rList);
	r.origin.y += CreditsListViewSupportButtonMarginTop;

	r.origin.x = 0.0f;
	r.size.width = CGRectGetWidth(self.bounds);

	return r;
}


- (CGRect)rectOfVersionLabel {

	CGRect rSupport = [self rectOfSupportButton];
	CGRect r = self.versionLabel.frame;

	static const CGFloat versionLabelMarginTop = 20.0f;
	r.origin.y = CGRectGetMaxY(rSupport) + versionLabelMarginTop;
	r.origin.x = 0.0f;
	r.size.width = CGRectGetWidth(self.bounds);

	return r;
}


#pragma mark - UIView

static const CGFloat CreditsListViewPaddingBottom = 12.0f;

- (CGSize)sizeThatFits:(CGSize)size {

	/*size.width is irrelevant --
	 the returned size.height is enough height to display everything.*/

	CGRect rVersion = [self rectOfVersionLabel];
	size.height = CGRectGetMaxY(rVersion) + CreditsListViewPaddingBottom;
	return size;
}


- (void)layoutSubviews {

	[self.listImageView qs_setFrameIfNotEqual:[self rectOfListImageView]];
	[self.versionLabel qs_setFrameIfNotEqual:[self rectOfVersionLabel]];
	[self.supportButton qs_setFrameIfNotEqual:[self rectOfSupportButton]];
}


@end
