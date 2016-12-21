//
//  VSImageUtilities.h
//  Vesper
//
//  Created by Brent Simmons on 4/13/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@import Foundation;


UIImage *VSScaleAndRotateImageToMaxResolution(UIImage *image, CGFloat maxResolution);

void VSDrawUIImageCenteredInRectWithAspectFill(UIImage *image, CGRect r);
