//
//  VSSignInFooterView.m
//  Vesper
//
//  Created by Brent Simmons on 5/20/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSignInFooterView.h"
#import "VSLinkButton.h"


@interface VSSignInFooterView ()

@property (nonatomic) UIButton *privacyPolicyButton;
@property (nonatomic) UIButton *forgotPasswordButton;
@property (nonatomic, weak) id<VSSignInFooterViewDelegate> delegate;

@end


@implementation VSSignInFooterView


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<VSSignInFooterViewDelegate>)delegate {

	self = [super initWithFrame:frame];
	if (!self) {
		return nil;
	}

	_delegate = delegate;

	_privacyPolicyButton = [VSLinkButton linkButtonWithTitle:NSLocalizedString(@"Privacy Policy", @"Privacy Policy")];
	_forgotPasswordButton = [VSLinkButton linkButtonWithTitle:NSLocalizedString(@"Forgot Password?", @"Forgot Password?")];

	[_privacyPolicyButton addTarget:self action:@selector(privacyPolicyTapped:) forControlEvents:UIControlEventTouchUpInside];
	[_forgotPasswordButton addTarget:self action:@selector(forgotPasswordTapped:) forControlEvents:UIControlEventTouchUpInside];

	[self addSubview:_privacyPolicyButton];
	[self addSubview:_forgotPasswordButton];
	
	return self;
}


#pragma mark - Actions

- (void)privacyPolicyTapped:(id)sender {

	[self.delegate privacyPolicyTapped:sender];
}


- (void)forgotPasswordTapped:(id)sender {

	[self.delegate forgotPasswordTapped:sender];
}


#pragma mark - Layout

- (void)layoutSubviews {

	[super layoutSubviews];

	CGRect rBounds = self.bounds;

	CGRect rPrivacy = self.privacyPolicyButton.frame;
	CGSize bestSize = [self.privacyPolicyButton sizeThatFits:rBounds.size];
	rPrivacy.size = bestSize;
	rPrivacy.origin.x = [app_delegate.theme floatForKey:@"syncUI.signIn.privacyPolicyMarginLeft"];
	rPrivacy.origin.y = CGRectGetHeight(rBounds) - bestSize.height;
	[self.privacyPolicyButton qs_setFrameIfNotEqual:rPrivacy];

	CGRect rForgotPassword = self.forgotPasswordButton.frame;
	bestSize = [self.forgotPasswordButton sizeThatFits:rBounds.size];
	rForgotPassword.size = bestSize;
	rForgotPassword.origin.x = CGRectGetMaxX(rBounds) - (bestSize.width + [app_delegate.theme floatForKey:@"syncUI.signIn.forgotPasswordMarginRight"]);
	rForgotPassword.origin.y = rPrivacy.origin.y;
	[self.forgotPasswordButton qs_setFrameIfNotEqual:rForgotPassword];
}


@end
