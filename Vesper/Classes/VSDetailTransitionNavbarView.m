//
//  VSBlankNavbarView.m
//  Vesper
//
//  Created by Brent Simmons on 4/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSDetailTransitionNavbarView.h"


@implementation VSDetailTransitionNavbarView


- (UIImage *)imageForAnimation:(BOOL)includePlusButton {
	
	CGSize size = self.bounds.size;
	if (!includePlusButton) {
		CGFloat composeButtonX = self.composeButton.frame.origin.x;
		size.width = composeButtonX - 1.0f;
	}
	
	UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self.layer renderInContext:context];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}


- (BOOL)clipsToBounds {
	return YES;
}


@end

