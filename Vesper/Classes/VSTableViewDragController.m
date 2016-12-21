//
//  VSTableViewDragController.m
//  Vesper
//
//  Created by Brent Simmons on 4/20/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTableViewDragController.h"


@interface VSTableViewDragController ()

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) id<VSTableViewDragControllerDelegate> delegate;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, assign) BOOL dragging;
@property (nonatomic, strong) UIImage *dragImage;
@property (nonatomic, strong) UIImageView *dragImageView;
@property (nonatomic, strong) UIImageView *dragImageViewWithoutShadows;
@property (nonatomic, strong) NSIndexPath *draggingIndexPath;
@property (nonatomic, strong) NSIndexPath *destinationIndexPath;
@property (nonatomic, assign) CGFloat touchOffsetY;
@property (nonatomic, strong) NSTimer *autoscrollTimer;
@property (nonatomic, assign) CGFloat autoscrollDelta;
@property (nonatomic, assign) CGFloat autoscrollThreshold;
@property (nonatomic, assign) CGFloat autoscrollCoefficient;
@property (nonatomic, assign) BOOL searchBarShowing;
@property (nonatomic, assign) CGFloat searchBarHeight;
@end


@implementation VSTableViewDragController

static const CGFloat kDragImageShadowSize = 6.0f;

#pragma mark - Init

- (instancetype)initWithTableView:(UITableView *)tableView delegate:(id<VSTableViewDragControllerDelegate>)delegate {
	
	self = [super init];
	if (self == nil)
		return nil;
	
	_delegate = delegate;
	_tableView = tableView;
	_enabled = YES;
	
	_autoscrollThreshold = [app_delegate.theme floatForKey:@"noteDragAutoscrollThreshold"];
	_autoscrollCoefficient = [app_delegate.theme floatForKey:@"noteDragAutoscrollCoefficient"];
	
	_longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	_longPressGestureRecognizer.delegate = self;
	[_tableView addGestureRecognizer:_longPressGestureRecognizer];
	
	_searchBarHeight = [app_delegate.theme floatForKey:@"searchBarContainerViewHeight"];
	
	[self addObserver:self forKeyPath:@"dragging" options:0 context:NULL];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[_autoscrollTimer qs_invalidateIfValid];
	_autoscrollTimer = nil;
	[self removeObserver:self forKeyPath:@"dragging"];
	_longPressGestureRecognizer.delegate = nil;
	[_tableView removeGestureRecognizer:_longPressGestureRecognizer];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"dragging"]) {
		
		if (self.dragging) {
			
			if (self.dragImageView == nil) {
				self.dragImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
				self.dragImageView.contentMode = UIViewContentModeCenter;
				[self.tableView addSubview:self.dragImageView];
			}
			self.autoscrollDelta = 0.0f;
			[self startAutoscrollTimer];
		}
		
		else {
			self.draggingIndexPath = nil;
			self.dragImage = nil;
			[self.dragImageView removeFromSuperview];
			self.dragImageView = nil;
			self.touchOffsetY = 0.0f;
			self.autoscrollDelta = 0.0f;
			[self stopAutoscrollTimer];
		}
	}
}


#pragma mark - Autoscroll

- (void)autoscroll:(NSTimer *)timer {
	
	/*While scrolling, the index path of the gap cell may change.*/
	
	CGPoint currentOffset = self.tableView.contentOffset;
	CGPoint updatedOffset = CGPointMake(currentOffset.x, currentOffset.y + self.autoscrollDelta);
	
	if (updatedOffset.y < 0)
		updatedOffset.y = 0;
	
	else if (self.tableView.contentSize.height < self.tableView.frame.size.height)
		updatedOffset = currentOffset;
	
	else if (updatedOffset.y > self.tableView.contentSize.height - self.tableView.frame.size.height)
		updatedOffset.y = self.tableView.contentSize.height - self.tableView.frame.size.height;
	
	if (!self.searchBarShowing && updatedOffset.y < self.searchBarHeight)
		updatedOffset.y = self.searchBarHeight;
	
	if (!CGPointEqualToPoint(currentOffset, updatedOffset)) {
		self.tableView.contentOffset = updatedOffset;
	}
	[self.delegate dragControllerDidScroll:self];
	
	CGPoint gestureLocation = [self.longPressGestureRecognizer locationInView:self.tableView];
	[self updateDragImageFrameWithGestureLocation:gestureLocation];
}


- (void)updateAutoscrollDeltaWithGestureLocation:(CGPoint)gestureLocation {
	
	CGFloat relativeY = gestureLocation.y - self.tableView.contentOffset.y;
	CGFloat maxTableY = CGRectGetHeight(self.tableView.frame);
	CGFloat delta = 0.0f;
	
	//    NSLog(@"relativeY %f maxTableY %f bottomThresholdY %f", relativeY, maxTableY, maxTableY - self.autoscrollThreshold);
	
	if (relativeY < self.autoscrollThreshold) /*Top scroll?*/
		delta = -((self.autoscrollThreshold - relativeY) * self.autoscrollCoefficient);
	
	else if (relativeY >= maxTableY - self.autoscrollThreshold) {
		//        NSLog(@"bottom scroll");
		delta = (self.autoscrollThreshold - (maxTableY - relativeY)) * self.autoscrollCoefficient;
		//        NSLog(@"delta %f", delta);
	}
	
	self.autoscrollDelta = delta;
}


- (void)startAutoscrollTimer {
	self.autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 30.0f target:self selector:@selector(autoscroll:) userInfo:nil repeats:YES];
}


- (void)stopAutoscrollTimer {
	
	[self.autoscrollTimer qs_invalidateIfValid];
	self.autoscrollTimer = nil;
}


#pragma mark - Drag Image

- (UIImage *)dragImageViewFromDelegate:(NSIndexPath *)indexPath {
	return [self.delegate dragController:self dragImageForRowAtIndexPath:indexPath];
}


- (UIImage *)dragImageForIndexPath:(NSIndexPath *)indexPath {
	
	/*Add shadows above and below image returned from delegate.*/
	
	UIImage *rawDragImage = [self dragImageViewFromDelegate:indexPath];
	
	CGSize imageViewSize = [self imageViewSizeWithCellSize:rawDragImage.size];
	CGRect rImage = CGRectZero;
	rImage.size = imageViewSize;
	
	UIGraphicsBeginImageContextWithOptions(imageViewSize, NO, [UIScreen mainScreen].scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSaveGState(context);
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 4.0f, [UIColor colorWithWhite:0.0f alpha:0.85f].CGColor);
	[[UIColor orangeColor] set];
	UIRectFill(CGRectMake(0.0f, kDragImageShadowSize, rImage.size.width, 1.0f));
	CGContextRestoreGState(context);
	
	CGContextSaveGState(context);
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, -1.0f), 4.0f, [UIColor colorWithWhite:0.0f alpha:0.85f].CGColor);
	[[UIColor orangeColor] set];
	UIRectFill(CGRectMake(0.0f, (CGRectGetMaxY(rImage) - kDragImageShadowSize) - 1.0f, rImage.size.width, 1.0f));
	CGContextRestoreGState(context);
	
	[rawDragImage drawAtPoint:CGPointMake(0.0f, kDragImageShadowSize)];
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return image;
}


- (CGSize)imageViewSizeWithCellSize:(CGSize)cellSize {
	
	CGRect rImageView = CGRectZero;
	rImageView.size = cellSize;
	rImageView = CGRectInset(rImageView, 0.0f, -kDragImageShadowSize);
	
	return rImageView.size;
}


- (CGRect)imageViewFrameWithCellFrame:(CGRect)cellFrame {
	
	CGRect rImageView = cellFrame;
	rImageView.size = [self imageViewSizeWithCellSize:cellFrame.size];
	rImageView.origin.y -= kDragImageShadowSize;
	
	return rImageView;
}


#pragma mark - Long Press Gesture

- (void)updateDragImageFrameWithGestureLocation:(CGPoint)gestureLocation {
	
	CGFloat dragImageViewY = gestureLocation.y; //- self.tableView.contentOffset.y;
	dragImageViewY -= self.touchOffsetY;
	dragImageViewY -= kDragImageShadowSize;
	
	CGRect r = self.dragImageView.frame;
	r.origin.x = 0.0f;
	r.origin.y = dragImageViewY;
	if (r.origin.y < VSNavbarHeight)
		r.origin.y = VSNavbarHeight;
	
	[self.dragImageView qs_setFrameIfNotEqual:r];
	[self.dragImageViewWithoutShadows qs_setFrameIfNotEqual:r];
}


- (void)longPressGestureDidBegin:(UILongPressGestureRecognizer *)gestureRecognizer {
	
	
	CGPoint location = [gestureRecognizer locationInView:self.tableView];
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
	if (indexPath == nil)
		return;
	
	if (![self.delegate dragController:self dragShouldBeginForRowAtIndexPath:indexPath])
		return;
	
	self.draggingIndexPath = indexPath;
	self.destinationIndexPath = nil;
	
	CGPoint contentOffset = self.tableView.contentOffset;
	self.searchBarShowing = contentOffset.y < self.searchBarHeight;
	
	self.dragging = YES;
	
	self.dragImage = [self dragImageForIndexPath:self.draggingIndexPath];
	self.dragImageView.image = self.dragImage;
	
	CGRect rCell = [self.tableView rectForRowAtIndexPath:self.draggingIndexPath];
	self.dragImageView.frame = [self imageViewFrameWithCellFrame:rCell];
	
	self.dragImageView.alpha = 0.0f;
	NSTimeInterval duration = [app_delegate.theme floatForKey:@"noteDragPopupAnimationDuration"];
	
	self.dragImageViewWithoutShadows = [[UIImageView alloc] initWithImage:[self dragImageViewFromDelegate:self.draggingIndexPath]];
	self.dragImageViewWithoutShadows.contentMode = UIViewContentModeCenter;
	self.dragImageViewWithoutShadows.frame = self.dragImageView.frame;
	[self.tableView insertSubview:self.dragImageViewWithoutShadows belowSubview:self.dragImageView];
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	[UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.dragImageView.alpha = 1.0f;
	} completion:^(BOOL finished) {
		[self.dragImageViewWithoutShadows removeFromSuperview];
		self.dragImageViewWithoutShadows = nil;
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
	
	[self.tableView bringSubviewToFront:self.dragImageView];
	
	self.touchOffsetY = location.y - rCell.origin.y;
	
	[self.delegate dragController:self dragDidBeginForRowAtIndexPath:self.draggingIndexPath];
}


- (void)longPressGestureDidChange:(UILongPressGestureRecognizer *)gestureRecognizer {
	
	CGPoint location = [gestureRecognizer locationInView:self.tableView];
	if (location.y < 51.0f)
		location.y = 51.0f; /*Account for search bar. TODO: get that number the right way*/
	NSIndexPath *indexPathOfRowBeneath = [self.tableView indexPathForRowAtPoint:location];
	if (indexPathOfRowBeneath != nil) {
		[self.delegate dragController:self dragDidHoverOverRowAtIndexPath:indexPathOfRowBeneath];
	}
	self.destinationIndexPath = indexPathOfRowBeneath;
	[self updateDragImageFrameWithGestureLocation:location];
	[self updateAutoscrollDeltaWithGestureLocation:location];
}


- (void)longPressGestureDidEnd:(UILongPressGestureRecognizer *)gestureRecognizer {
	
	[self stopAutoscrollTimer];
	NSTimeInterval duration = [app_delegate.theme floatForKey:@"noteDragSlideInAnimationDuration"];
 
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	[UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		
		NSIndexPath *indexPathToUse = self.destinationIndexPath;
		if (indexPathToUse == nil) {
			//            NSLog(@"using draggingIndexPath");
			indexPathToUse = self.draggingIndexPath;
		}
		
		//        NSLog(@"row %d", indexPathToUse.row);
		if (indexPathToUse != nil) {
			CGRect destinationRect = [self.tableView rectForRowAtIndexPath:indexPathToUse];
			self.dragImageView.frame = destinationRect;
			self.dragImageViewWithoutShadows.frame = destinationRect;
		}
		
	} completion:^(BOOL finished) {
		
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		[self.delegate dragController:self dragDidCompleteAtIndexPath:self.destinationIndexPath];
		self.dragging = NO;
	}];
	
}


- (void)longPressGestureCanceled:(UILongPressGestureRecognizer *)gestureRecognizer {
	
	self.dragging = NO;
	[self.delegate draggingDidCancel:self];
}


#pragma mark - UIGestureRezognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	if (!self.enabled)
		return NO;
	
	CGPoint location = [gestureRecognizer locationInView:self.tableView];
	NSIndexPath *draggingIndexPath = [self.tableView indexPathForRowAtPoint:location];
	if (draggingIndexPath == nil)
		return NO;
	
	return YES;
}

#pragma mark - Actions

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
	
	switch (gestureRecognizer.state) {
		case UIGestureRecognizerStateBegan:
			[self longPressGestureDidBegin:gestureRecognizer];
			break;
			
		case UIGestureRecognizerStateChanged:
			[self longPressGestureDidChange:gestureRecognizer];
			break;
			
		case UIGestureRecognizerStateEnded:
			[self longPressGestureDidEnd:gestureRecognizer];
			break;
			
		case UIGestureRecognizerStateCancelled:
			[self longPressGestureCanceled:gestureRecognizer];
			break;
			
		default:
			break;
	}
}


@end
