//
//  VSImageUtilities.m
//  Vesper
//
//  Created by Brent Simmons on 4/13/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSImageUtilities.h"


UIImage *VSScaleAndRotateImageToMaxResolution(UIImage *image, CGFloat maxResolution) {
	
	/* http://stackoverflow.com/questions/538041/uiimagepickercontroller-camera-preview-is-portrait-in-landscape-app */
	
	//    int kMaxResolution = 640; // Or whatever
	
	CGImageRef imgRef = image.CGImage;
	
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > maxResolution || height > maxResolution) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = maxResolution;
#if __LP64__
			bounds.size.height = round(bounds.size.width / ratio);
#else
			bounds.size.height = roundf(bounds.size.width / ratio);
#endif
		}
		else {
			bounds.size.height = maxResolution;
#if __LP64__
			bounds.size.width = round(bounds.size.height * ratio);
#else
			bounds.size.width = roundf(bounds.size.height * ratio);
#endif
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
	CGFloat boundHeight;
	UIImageOrientation orient = image.imageOrientation;
	switch(orient) {
			
		case UIImageOrientationUp: //EXIF = 1
			transform = CGAffineTransformIdentity;
			break;
			
		case UIImageOrientationUpMirrored: //EXIF = 2
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
			
		case UIImageOrientationDown: //EXIF = 3
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, (CGFloat)M_PI);
			break;
			
		case UIImageOrientationDownMirrored: //EXIF = 4
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
			
		case UIImageOrientationLeftMirrored: //EXIF = 5
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0f * (CGFloat)M_PI / 2.0f);
			break;
			
		case UIImageOrientationLeft: //EXIF = 6
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0f * (CGFloat)M_PI / 2.0f);
			break;
			
		case UIImageOrientationRightMirrored: //EXIF = 7
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, (CGFloat)M_PI / 2.0);
			break;
			
		case UIImageOrientationRight: //EXIF = 8
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, (CGFloat)M_PI / 2.0);
			break;
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
			
	}
	
	UIGraphicsBeginImageContext(bounds.size);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	}
	else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
	
	CGContextConcatCTM(context, transform);
	
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return imageCopy;
}


void VSDrawUIImageCenteredInRectWithAspectFill(UIImage *image, CGRect r) {
	
	CGRect rImage = r;
	rImage.size = image.size;
	
	if (CGSizeEqualToSize(r.size, image.size)) {
		rImage = CGRectIntegral(rImage);
		rImage.size = image.size;
		[image drawInRect:rImage];
		return;
	}
	
	CGFloat scaleFactor = 1.0f;
	
	if (rImage.size.height < rImage.size.width)
		scaleFactor = rImage.size.height / r.size.height;
	else
		scaleFactor = rImage.size.width / r.size.width;
	
	rImage.size.height = rImage.size.height / scaleFactor;
	rImage.size.width = rImage.size.width / scaleFactor;
	
	rImage = CGRectCenteredInRect(rImage, r);
	rImage = CGRectIntegral(rImage);
	[image drawInRect:rImage];
}

