//
//  VSSyncNoAccountHeaderView.m
//  Vesper
//
//  Created by Brent Simmons on 4/25/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSyncNoAccountHeaderView.h"
#import "VSSyncUI.h"
#import "VSUI.h"
#import "VSTypographySettings.h"


@interface VSSyncNoAccountHeaderView ()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *label;

@end


@implementation VSSyncNoAccountHeaderView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	
	if (!self) {
		return nil;
	}
	
	_imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cloud-logo"]];
	_imageView.contentMode = UIViewContentModeRedraw;
	[self addSubview:_imageView];
	
#if SYNC_TRANSITION
	NSString *s = NSLocalizedString(@"Vesper Sync will be turned off August 30 at 8:00 pm Pacific Time.\n\nNew accounts cannot be created — but if you already have an account, you can sign in.\n\nYou can also export your notes: tap the back arrow above, then tap Export.", @"");
	if (VSSyncIsShutdown()) {
		s = NSLocalizedString(@"Vesper Sync has been shut down, and Vesper will be removed from the App Store as of September 15, 2016.\n\nYou can export your notes and pictures: tap the back arrow above, then tap Export.", @"");
	}
#else
	NSString *s = NSLocalizedString(@"Sign in or create an account to back up your notes with Vesper Sync.\n\n", @"");
#endif
	UIFont *font = [app_delegate.theme fontForKey:@"groupedTable.pitchFont"];
	if (VSDefaultsUsingLightText()) {
		font = [app_delegate.theme fontForKey:@"groupedTable.pitchFontLight"];
	}
	CGFloat fontSize = app_delegate.typographySettings.bodyFont.pointSize;
	font = [font fontWithSize:fontSize];
	
	UIColor *color = [app_delegate.theme colorForKey:@"groupedTable.pitchFontColor"];
	NSAttributedString *attString = [NSAttributedString qs_attributedStringWithText:s font:font color:color kerning:YES];
	
	_label = [[UILabel alloc] initWithFrame:CGRectZero];
	_label.font = font;
	_label.opaque = NO;
	_label.backgroundColor = [UIColor clearColor];
	_label.numberOfLines = 0;
	_label.attributedText = attString;
	_label.contentMode = UIViewContentModeRedraw;
	
	[_label sizeToFit];
	
	[self addSubview:_label];
	
	return self;
}


#pragma mark - Layout

static const CGFloat kImageMarginTop = 12.0;
static const CGFloat kLabelMarginTop = 20.0;
static const CGFloat kLabelMarginLeft = 20.0;
static const CGFloat kLabelMarginRight = 20.0;
static const CGFloat kLabelMarginBottom = 20.0;

typedef struct {
	CGRect imageViewRect;
	CGRect labelRect;
} VSHeaderLayoutRects;

- (VSHeaderLayoutRects)layoutRectsForWidth:(CGFloat)width {
	
	CGRect rBounds = CGRectZero;
	rBounds.size.width = width;
	rBounds.size.height = CGFLOAT_MAX;
	
	CGRect rImageView = CGRectZero;
	rImageView.origin.y = kImageMarginTop;
	rImageView.size = self.imageView.image.size;
	rImageView = CGRectCenteredHorizontallyInRect(rImageView, rBounds);
	
	CGRect rLabel = CGRectZero;
	rLabel.origin.x = kLabelMarginLeft;
	rLabel.origin.y = CGRectGetMaxY(rImageView) + kLabelMarginTop;
	rLabel.size.width = CGRectGetWidth(rBounds) - (kLabelMarginLeft + kLabelMarginRight);
	self.label.preferredMaxLayoutWidth = CGRectGetWidth(rLabel);
	CGSize labelSize = [self.label sizeThatFits:CGSizeMake(CGRectGetWidth(rLabel), CGFLOAT_MAX)];
	rLabel.size.height = labelSize.height;
	
	VSHeaderLayoutRects layoutRects = {rImageView, rLabel};
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
	
	[self.imageView qs_setFrameIfNotEqual:layoutRects.imageViewRect];
	[self.label qs_setFrameIfNotEqual:layoutRects.labelRect];
}


@end
