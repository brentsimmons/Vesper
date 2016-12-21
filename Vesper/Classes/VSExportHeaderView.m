//
//  VSExportHeaderView.m
//  Vesper
//
//  Created by Brent Simmons on 7/4/16.
//  Copyright © 2016 Q Branch LLC. All rights reserved.
//

#import "VSExportHeaderView.h"
#import "VSTypographySettings.h"


@interface VSExportHeaderView ()

@property (nonatomic) UILabel *label;

@end


@implementation VSExportHeaderView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];

	if (!self) {
		return nil;
	}

	NSString *s = NSLocalizedString(@"Tap “Export Notes and Pictures” below to choose a location, such as iCloud Drive, where Vesper will place a copy of your notes and pictures.\n\nNotes can be opened in a text editor, and pictures can be opened with an image viewer or editor.", @"");
	NSAttributedString *attString = [self attributedStringWithText:s];
	
	_label = [[UILabel alloc] initWithFrame:CGRectZero];
	_label.font = [attString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
	_label.opaque = NO;
	_label.backgroundColor = [UIColor clearColor];
	_label.numberOfLines = 0;
	_label.attributedText = attString;
	_label.contentMode = UIViewContentModeRedraw;

	[_label sizeToFit];

	[self addSubview:_label];

	return self;
}


- (NSAttributedString *)attributedStringWithText:(NSString *)s {
	
	UIFont *font = [app_delegate.theme fontForKey:@"groupedTable.pitchFont"];
	if (VSDefaultsUsingLightText()) {
		font = [app_delegate.theme fontForKey:@"groupedTable.pitchFontLight"];
	}
	CGFloat fontSize = app_delegate.typographySettings.bodyFont.pointSize;
	font = [font fontWithSize:fontSize];
	
	UIColor *color = [app_delegate.theme colorForKey:@"groupedTable.pitchFontColor"];
	return [NSAttributedString qs_attributedStringWithText:s font:font color:color kerning:YES];
}


#pragma mark - Success Message

- (NSAttributedString *)successMessage {
	
	NSString *s = NSLocalizedString(@"It worked!\n\nYour notes and pictures have been exported.\n\nNote: it may take a few minutes before they appear in your chosen location.", @"");
	return [self attributedStringWithText:s];
}


- (void)switchToSuccessMessage {
	
	self.label.attributedText = [self successMessage];
}


#pragma mark - Layout

static const CGFloat kLabelMarginTop = 20.0;
static const CGFloat kLabelMarginLeft = 20.0;
static const CGFloat kLabelMarginRight = 20.0;
static const CGFloat kLabelMarginBottom = 20.0;

typedef struct {
	CGRect labelRect;
} VSHeaderLayoutRects;

- (VSHeaderLayoutRects)layoutRectsForWidth:(CGFloat)width {

	CGRect rBounds = CGRectZero;
	rBounds.size.width = width;
	rBounds.size.height = CGFLOAT_MAX;

	CGRect rLabel = CGRectZero;
	rLabel.origin.x = kLabelMarginLeft;
	rLabel.origin.y = kLabelMarginTop;
	rLabel.size.width = CGRectGetWidth(rBounds) - (kLabelMarginLeft + kLabelMarginRight);
	self.label.preferredMaxLayoutWidth = CGRectGetWidth(rLabel);
	CGSize labelSize = [self.label sizeThatFits:CGSizeMake(CGRectGetWidth(rLabel), CGFLOAT_MAX)];
	rLabel.size.height = labelSize.height;

	VSHeaderLayoutRects layoutRects = {rLabel};
	return layoutRects;
}


- (CGSize)sizeThatFits:(CGSize)size {

	/*size.height is ignored.*/

	VSHeaderLayoutRects layoutRects = [self layoutRectsForWidth:size.width];
	CGFloat height = CGRectGetMaxY(layoutRects.labelRect) + kLabelMarginBottom;

	return CGSizeMake(size.width, height);
}


- (void)layoutSubviews {

	VSHeaderLayoutRects layoutRects = [self layoutRectsForWidth:CGRectGetWidth(self.bounds)];

	[self.label qs_setFrameIfNotEqual:layoutRects.labelRect];
}

@end
