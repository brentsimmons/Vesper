//
//  VSThumbnailRenderer.m
//  Vesper
//
//  Created by Brent Simmons on 10/23/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSThumbnailRenderer.h"
#import "QSImageRenderer.h"
#import "RSGeometry.h"


@interface VSThumbnailRenderer ()

@property (nonatomic, strong, readonly) QSImageRenderer *imageRenderer;

@end


static QS_IMAGE *renderThumbnail(QS_IMAGE *originalImage);


@implementation VSThumbnailRenderer


#pragma mark - Init

- (instancetype)init {
	
	self = [super init];
	if (self == nil) {
		return nil;
	}
	
	_imageRenderer = [[QSImageRenderer alloc] initWithRenderer:^QS_IMAGE *(QS_IMAGE *imageToRender) {
		
		return renderThumbnail(imageToRender);
	}];
	
	return self;
}


#pragma mark - API

- (void)renderThumbnailWithImage:(QS_IMAGE *)fullSizeImage imageResultBlock:(QSImageResultBlock)imageResultBlock {
	
	[self.imageRenderer renderImage:fullSizeImage imageResultBlock:imageResultBlock];
}


- (void)renderThumbnailWithData:(NSData *)fullSizeImageData imageResultBlock:(QSImageResultBlock)imageResultBlock {
	
	[QS_IMAGE qs_imageWithData:fullSizeImageData imageResultBlock:^(QS_IMAGE *image) {
		if (image != nil) {
			[self renderThumbnailWithImage:image imageResultBlock:imageResultBlock];
		}
	}];
}

@end


#pragma mark - Image Rendering

static CGSize apparentThumbnailSize;
static CGSize actualThumbnailSize;
static QS_EDGE_INSETS thumbnailPadding;
static CGFloat borderWidth;
static QS_COLOR *borderColor;
static CGFloat borderWidth;
static CGFloat borderRadius;
static CGFloat shadowAlpha;
static CGFloat shadowOffsetY;
static CGFloat shadowBlurRadius;
static QS_COLOR *shadowColor;


static void startup(void) {
	
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		
		thumbnailPadding = QSEdgeInsetsMake(2.0f, 2.0f, 4.0f, 2.0f);
		CGFloat thumbnailWidth = [app_delegate.theme floatForKey:@"thumbnailWidth"];
		CGFloat thumbnailHeight = [app_delegate.theme floatForKey:@"thumbnailHeight"];
		apparentThumbnailSize = CGSizeMake(thumbnailWidth, thumbnailHeight);
		actualThumbnailSize = apparentThumbnailSize;
		actualThumbnailSize.width += (thumbnailPadding.left + thumbnailPadding.right);
		actualThumbnailSize.height += (thumbnailPadding.top + thumbnailPadding.bottom);
		
		borderWidth = [app_delegate.theme floatForKey:@"thumbnailBorderWidth"];
		borderColor = [app_delegate.theme colorForKey:@"thumbnailBorderColor"];
		borderRadius = [app_delegate.theme floatForKey:@"thumbnailCornerRadius"];
		
		shadowAlpha = [app_delegate.theme floatForKey:@"thumbnailShadowAlpha"];
		shadowOffsetY = [app_delegate.theme floatForKey:@"thumbnailShadowOffsetY"];
		shadowBlurRadius = [app_delegate.theme floatForKey:@"thumbnailShadowBlurRadius"];
		shadowColor = [app_delegate.theme colorForKey:@"thumbnailShadowColor"];
		shadowColor = [shadowColor colorWithAlphaComponent:shadowAlpha];
	});
}


#if TARGET_OS_IPHONE

static UIImage *renderThumbnail(UIImage *rawImage) {
	
	assert(rawImage != nil);
	
	startup();
	
	@autoreleasepool {
		CGRect r = CGRectZero;
		r.size = apparentThumbnailSize;
		
		/*Render with rounded corners and border.*/
		
		QS_IMAGE *rawThumbnail = nil;
		
		UIGraphicsBeginImageContextWithOptions(apparentThumbnailSize, NO, 0.0f);
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		CGContextSaveGState(context);
		
		UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:borderRadius];
		[path addClip];
		VSDrawUIImageCenteredInRectWithAspectFill(rawImage, r);
		CGContextRestoreGState(context);
		
		rawThumbnail = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		/*Draw rawThumbnail with shadow.*/
		
		r.size = actualThumbnailSize;
		
		CGRect rApparentImage = VSThumbnailApparentRectForActualRect(r);
		
		UIGraphicsBeginImageContextWithOptions(actualThumbnailSize, NO, 0.0f);
		context = UIGraphicsGetCurrentContext();
		
		CGContextSaveGState(context);
		if (shadowAlpha > 0.0f)
			CGContextSetShadowWithColor(context, CGSizeMake(0.0f, shadowOffsetY), shadowBlurRadius, shadowColor.CGColor);
		[rawThumbnail drawAtPoint:rApparentImage.origin];
		CGContextRestoreGState(context);
		
		CGRect rBorder = rApparentImage;
		rBorder = CGRectInset(rBorder, 0.25f, 0.25f);
		UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:rBorder cornerRadius:borderRadius];
		if (borderWidth > 0.0f) {
			borderPath.lineWidth = borderWidth;
			[borderColor set];
			[borderPath stroke];
		}
		
		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		return image;
	}
}

#else /*Mac*/

static void drawImageWithAspectFillCenteredInRect(NSImage *image, NSRect r) {
	
	CGRect rImage = r;
	rImage.size = [image size];
	
	if (CGSizeEqualToSize(r.size, [image size])) {
		rImage = CGRectIntegral(rImage);
		rImage.size = [image size];
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


static NSImage *renderThumbnail(NSImage *rawImage) {
	
	/*TODO: Mac renderThumbnail*/
	
	assert(rawImage != nil);
	
	startup();
	
	@autoreleasepool {
		
		CGRect r = CGRectZero;
		r.size = apparentThumbnailSize;
		
		
		/*Render with rounded corners and border.*/
		
		NSImage *rawThumbnail = [[NSImage alloc] initWithSize:r.size];
		[rawThumbnail lockFocus];
		
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:r xRadius:borderRadius yRadius:borderRadius];
		[path addClip];
		
		drawImageWithAspectFillCenteredInRect(rawImage, r);
		
		[rawThumbnail unlockFocus];
		
		
		/*Draw rawThumbnail with shadow.*/
		
		r.size = actualThumbnailSize;
		CGRect rApparentImage = VSThumbnailApparentRectForActualRect(r);
		
		NSImage *thumbnail = [[NSImage alloc] initWithSize:r.size];
		[thumbnail lockFocus];
		
		[rawThumbnail drawInRect:rApparentImage];
		
		CGRect rBorder = rApparentImage;
		rBorder = CGRectInset(rBorder, 0.25f, 0.25f);
		NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:rBorder xRadius:borderRadius yRadius:borderRadius];
		if (borderWidth > 0.0f) {
			[borderPath setLineWidth:borderWidth];
			[borderColor set];
			[borderPath stroke];
		}
		
		[thumbnail unlockFocus];
		
		return thumbnail;
	}
}

#endif



CGRect VSThumbnailActualRectForApparentRect(CGRect apparentRect) {
	
	startup();
	
	CGRect r = apparentRect;
	
	r.origin.y -= thumbnailPadding.top;
	r.size.height += (thumbnailPadding.top + thumbnailPadding.bottom);
	
	r.origin.x -= thumbnailPadding.left;
	r.size.width += (thumbnailPadding.left + thumbnailPadding.right);
	
	return r;
}


CGRect VSThumbnailApparentRectForActualRect(CGRect actualRect) {
	
	startup();
	
	CGRect r = actualRect;
	
	r.origin.y += thumbnailPadding.top;
	r.size.height -= (thumbnailPadding.top + thumbnailPadding.bottom);
	
	r.origin.x += thumbnailPadding.left;
	r.size.width -= (thumbnailPadding.left + thumbnailPadding.right);
	
	return r;
}
