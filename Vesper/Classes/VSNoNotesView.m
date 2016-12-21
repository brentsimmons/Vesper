//
//  VSNoNotesView.m
//  Vesper
//
//  Created by Brent Simmons on 5/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSNoNotesView.h"


@interface VSNoNotesView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@end


@implementation VSNoNotesView

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	UIImage *noNotesImage = [image qs_imageTintedWithColor:[app_delegate.theme colorForKey:@"noNotesColor"]];
	_imageView = [[UIImageView alloc] initWithImage:noNotesImage];
	[self addSubview:_imageView];
	
	_label = [[UILabel alloc] initWithFrame:CGRectZero];
	_label.backgroundColor = [UIColor clearColor];
	_label.font = [app_delegate.theme fontForKey:@"noNotesFont"];
	_label.text = NSLocalizedString(@"No Notes", @"No Notes");
	_label.textColor = [app_delegate.theme colorForKey:@"noNotesFontColor"];
	[_label sizeToFit];
	[self addSubview:_label];
	
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	
	return self;
}


- (CGSize)sizeThatFits:(CGSize)constrainingSize {
	
#pragma unused(constrainingSize)
	
	CGSize size = CGSizeZero;
	
	[self layout];
	
	size.height = CGRectGetMaxY(self.label.frame);
	size.width = CGRectGetMaxX(self.imageView.frame);
	
	return size;
}


- (void)layout {
	
	CGRect r = CGRectZero;
	
	CGSize imageSize = self.imageView.image.size;
	r.size = imageSize;
	
	r.size.height += [app_delegate.theme floatForKey:@"noNotesImageMarginBottom"];
	r.size.height += self.label.frame.size.height;
	
	CGRect rImageView = r;
	rImageView.size = imageSize;
	
	[self.imageView qs_setFrameIfNotEqual:rImageView];
	
	CGRect rLabel = r;
	rLabel.origin.y = CGRectGetMaxY(r) - self.label.frame.size.height;
	rLabel.size = self.label.frame.size;
	rLabel = CGRectCenteredHorizontallyInRect(rLabel, r);
	rLabel.size = self.label.frame.size;
	
	[self.label qs_setFrameIfNotEqual:rLabel];
}


- (void)layoutSubviews {
	[self layout];
}


@end
