//
//  VSLinkButtonFooterView.m
//  Vesper
//
//  Created by Brent Simmons on 4/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSLinkButtonFooterView.h"
#import "VSLinkButton.h"


@interface VSLinkButtonFooterView ()

@property (nonatomic) UIButton *linkButton;
@property (nonatomic, weak) id<VSLinkButtonFooterViewDelegate> delegate;
@property (nonatomic, assign) UIEdgeInsets edgeInsets;

@end


@implementation VSLinkButtonFooterView


#pragma mark - Init

- (instancetype)initWithText:(NSString *)text delegate:(id<VSLinkButtonFooterViewDelegate>)delegate {

	CGRect r = CGRectZero;
	r.size.width = CGRectGetWidth([UIScreen mainScreen].bounds);
	r.size.height = 40.0f;

	self = [self initWithFrame:r];
	if (!self) {
		return nil;
	}

	_linkButton = [VSLinkButton linkButtonWithTitle:text];
	[_linkButton addTarget:self action:@selector(linkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:_linkButton];

	_edgeInsets = [app_delegate.theme edgeInsetsForKey:@"groupedTable.descriptionMargin"];

	_delegate = delegate;
	
	return self;
}


#pragma mark - Action

- (void)linkButtonTapped:(id)sender {
	
	[self.delegate linkButtonFooterViewTapped:self];
}


#pragma mark - Layout

- (CGRect)buttonRectForWidth:(CGFloat)width {

	CGRect rBounds = CGRectZero;
	rBounds.size.width = width;
	rBounds.size.height = CGFLOAT_MAX;

	CGRect r = self.linkButton.bounds;
	r.origin = CGPointZero;

	r = CGRectCenteredHorizontallyInRect(r, rBounds);
	r = CGRectIntegral(r);
	r.size.width = CGRectGetWidth(self.linkButton.bounds);

	r.origin.y = self.edgeInsets.top;

	return r;
}


- (CGSize)sizeThatFits:(CGSize)size {

	/*size.height is ignored.*/

	CGRect r = [self buttonRectForWidth:size.width];
	CGFloat height = CGRectGetMaxY(r) + self.edgeInsets.bottom;

	return CGSizeMake(size.width, height);
}


- (void)layoutSubviews {

	CGRect r = [self buttonRectForWidth:CGRectGetWidth(self.bounds)];
	[self.linkButton qs_setFrameIfNotEqual:r];
}

@end
