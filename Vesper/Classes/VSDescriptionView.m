//
//  VSDescriptionView.m
//  Vesper
//
//  Created by Brent Simmons on 4/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSDescriptionView.h"
#import "VSUI.h"


@interface VSDescriptionView ()

@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, readwrite) UILabel *label;

@end


@implementation VSDescriptionView


#pragma mark - Init

- (instancetype)initWithText:(NSString *)text edgeInsets:(UIEdgeInsets)edgeInsets {

	self = [self initWithFrame:CGRectZero];
	if (!self) {
		return self;
	}

	_edgeInsets = edgeInsets;

	_label = [VSUI groupedTableDescriptionLabel:text];
	[self addSubview:_label];

	return self;
}


#pragma mark - Text

- (void)updateText:(NSString *)s color:(UIColor *)color {

	if (!color) {
		color = [app_delegate.theme colorForKey:@"groupedTable.descriptionFontColor"];
	}
	NSAttributedString *attString = [NSAttributedString qs_attributedStringWithText:s font:self.label.font color:color kerning:YES];
	self.label.attributedText = attString;

	[self setNeedsLayout];
}


#pragma mark - Layout

- (CGRect)labelRectForWidth:(CGFloat)width {

	CGRect rBounds = CGRectZero;
	rBounds.size.width = width;
	rBounds.size.height = CGFLOAT_MAX;

	CGRect r = CGRectZero;
	r.origin.x = self.edgeInsets.left;
	r.origin.y = self.edgeInsets.top;
	r.size.width = CGRectGetWidth(rBounds) - (self.edgeInsets.left + self.edgeInsets.right);
	self.label.preferredMaxLayoutWidth = CGRectGetWidth(r);
	CGSize labelSize = [self.label sizeThatFits:CGSizeMake(CGRectGetWidth(r), CGFLOAT_MAX)];
	r.size.height = labelSize.height;

	return r;
}


- (CGSize)sizeThatFits:(CGSize)size {

	/*size.height is ignored.*/

	CGRect rLabel = [self labelRectForWidth:size.width];
	CGFloat height = CGRectGetMaxY(rLabel) + self.edgeInsets.bottom;

	return CGSizeMake(size.width, height);
}


- (void)layoutSubviews {

	CGRect r = [self labelRectForWidth:CGRectGetWidth(self.bounds)];
	[self.label qs_setFrameIfNotEqual:r];
}


@end
