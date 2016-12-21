//
//  UIImageView+RSExtras.m
//  Vesper
//
//  Created by Brent Simmons on 5/22/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "UIImageView+RSExtras.h"


@implementation UIImageView (RSExtras)


+ (UIImageView *)rs_imageViewWithSnapshotOfView:(UIView *)view clearBackground:(BOOL)clearBackground {
	
	UIImage *image = [view rs_snapshotImage:clearBackground];
	if (image == nil)
		return nil;
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	imageView.clipsToBounds = YES;
	imageView.contentMode = UIViewContentModeTop;
	imageView.autoresizingMask = UIViewAutoresizingNone;
	
	return imageView;
}


@end
