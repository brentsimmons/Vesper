//
//  VSSignInFooterView.h
//  Vesper
//
//  Created by Brent Simmons on 5/20/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@protocol VSSignInFooterViewDelegate <NSObject>

@required

- (void)privacyPolicyTapped:(id)sender;
- (void)forgotPasswordTapped:(id)sender;

@end


@interface VSSignInFooterView : UIView


- (instancetype)initWithFrame:(CGRect)frame delegate:(id<VSSignInFooterViewDelegate>)delegate;


@end
