//
//  VSImageScrollView.m
//  Vesper
//
//  Created by Brent Simmons on 4/16/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSImageScrollView.h"


@interface VSImageScrollView ()

@property (nonatomic, strong, readwrite) UIImageView *imageView;
//@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@end


@implementation VSImageScrollView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_imageView = [[UIImageView alloc] initWithImage:image];
	[self addSubview:_imageView];
	
	self.showsVerticalScrollIndicator = NO;
	self.showsHorizontalScrollIndicator = NO;
	self.bouncesZoom = YES;
	self.decelerationRate = UIScrollViewDecelerationRateFast;
	self.backgroundColor = [app_delegate.theme colorForKey:@"photoDetailBackgroundColor"];;
	self.opaque = YES;
	self.canCancelContentTouches = NO;
	self.clipsToBounds = YES;
	self.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	self.zoomScale = 1.0;
	
	self.delegate = self;
	
	//    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
	//    _tapGestureRecognizer.numberOfTapsRequired = 2;
	//    [self addGestureRecognizer:_tapGestureRecognizer];
	
	[self configureForImageSize:image.size];
	
	return self;
}


#pragma mark - UIView

- (void)layoutSubviews {
	
	if (self.closing)
		return;
	
	[super layoutSubviews];
	
	/*Center the image when it's smaller than screen size.*/
	
	CGRect rBounds = self.bounds;
	CGRect r = self.imageView.frame;
	
	if (r.size.width < rBounds.size.width)
		r.origin.x = (rBounds.size.width - r.size.width) / 2.0f;
	else
		r.origin.x = 0.0f;
	
	if (r.size.height < rBounds.size.height)
		r.origin.y = (rBounds.size.height - r.size.height) / 2.0f;
	else
		r.origin.y = 0.0f;
	
	[self.imageView qs_setFrameIfNotEqual:r];
}


#pragma mark - Tap Gesture Recognizer

//- (void)tapGesture:(UITapGestureRecognizer *)gestureRecognizer {
//
//    VSSendUIEventHappenedNotification();
//
//	CGPoint locationInImage = [gestureRecognizer locationInView:self.imageView];
//
//	CGFloat newZoomScale = (self.zoomScale == self.minimumZoomScale) ? self.maximumZoomScale : self.minimumZoomScale;
//
//	CGRect zoomRect = CGRectZero;
//	zoomRect.size.width = self.bounds.size.width / newZoomScale;
//	zoomRect.size.height = self.bounds.size.height / newZoomScale;
//	zoomRect.origin.x = locationInImage.x - zoomRect.size.width / 2;
//	zoomRect.origin.y = locationInImage.y - zoomRect.size.height / 2;
//
//	[self zoomToRect:zoomRect animated:YES];
//}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.imageView;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	VSSendUIEventHappenedNotification();
}


- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	
	VSSendUIEventHappenedNotification();
	
	CGFloat offsetX = (scrollView.bounds.size.width > self.contentSize.width)?
	(self.bounds.size.width - self.contentSize.width) * 0.5f : 0.0f;
	
	CGFloat offsetY = (self.bounds.size.height > self.contentSize.height)?
	(self.bounds.size.height - self.contentSize.height) * 0.5f : 0.0f;
	
	self.imageView.center = CGPointMake(self.contentSize.width * 0.5f + offsetX, self.contentSize.height * 0.5f + offsetY);
}


#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	VSSendUIEventHappenedNotification();
	[super touchesBegan:touches withEvent:event];
}


#pragma mark - Layout

- (void)configureForImageSize:(CGSize)imageSize {
	
	CGSize boundsSize = [self bounds].size;
	
	CGFloat xScale = boundsSize.width / imageSize.width;
	CGFloat yScale = boundsSize.height / imageSize.height;
	CGFloat minScale = MIN(xScale, yScale);
	
	CGFloat maxScale = (1.0f / [[UIScreen mainScreen] scale]) * 2.0f;
	
	if (minScale > maxScale)
		minScale = maxScale;
	
	self.contentSize = imageSize;
	self.maximumZoomScale = maxScale;
	self.minimumZoomScale = minScale;
	self.zoomScale = minScale;
}


@end

