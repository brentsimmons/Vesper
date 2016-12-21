//
//  UIImageView+RSExtras.h
//  Vesper
//
//  Created by Brent Simmons on 5/22/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@import UIKit;


@interface UIImageView (RSExtras)


/*clipsToBounds YES, contentModeTop, autoresizing none*/

+ (UIImageView *)rs_imageViewWithSnapshotOfView:(UIView *)view clearBackground:(BOOL)clearBackground;

@end
