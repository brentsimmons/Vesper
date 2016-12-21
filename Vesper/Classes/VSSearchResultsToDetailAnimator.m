//
//  VSSearchResultsToDetailAnimator.m
//  Vesper
//
//  Created by Brent Simmons on 3/17/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSearchResultsToDetailAnimator.h"
#import "VSTimelineViewController.h"
#import "VSSearchResultsViewController.h"
#import "VSDetailViewController.h"
#import "VSNote.h"
#import "VSDetailTransitionView.h"
#import "VSNavbarView.h"
#import "VSSearchBarContainerView.h"
#import "VSTimelineCell.h"
#import "VSDetailTextView.h"
#import "VSThumbnail.h"
#import "VSTagDetailScrollView.h"
#import "VSDetailView.h"


@interface VSSearchResultsToDetailAnimator ()

@property (nonatomic, readonly) VSTimelineViewController *timelineViewController;
@property (nonatomic, readonly) VSDetailViewController *detailViewController;
@property (nonatomic, readonly) VSSearchResultsViewController *searchResultsViewController;
@property (nonatomic, readonly) NSIndexPath *indexPath;
@property (nonatomic, readonly) VSNote *note;
@property (nonatomic, readonly) VSTimelineNote *timelineNote;
@property (nonatomic, readonly) UIImage *detailAnimationImage;
@property (nonatomic, assign) NSUInteger numberOfAnimations;
@property (nonatomic, copy) QSVoidCompletionBlock completion;
@property (nonatomic) VSDetailTransitionView *smokescreenView;

@end


@implementation VSSearchResultsToDetailAnimator

- (instancetype)initWithNote:(VSNote *)note timelineNote:(VSTimelineNote *)timelineNote indexPath:(NSIndexPath *)indexPath image:(UIImage *)image searchResultsViewController:(VSSearchResultsViewController *)searchResultsViewController timelineViewController:(VSTimelineViewController *)timelineViewController detailViewController:(VSDetailViewController *)detailViewController {
	
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_note = note;
	_timelineNote = timelineNote;
	_indexPath = indexPath;
	_detailAnimationImage = image;
	_timelineViewController = timelineViewController;
	_searchResultsViewController = searchResultsViewController;
	_detailViewController = detailViewController;
	
	return self;
}


#pragma mark - Animations

- (void)beginAnimationBlock {
	
	[self.timelineViewController prepareForAnimation];
	self.numberOfAnimations = self.numberOfAnimations + 1;
}


- (void)endAnimationBlock {
	
	[self.timelineViewController finishAnimation];
	self.numberOfAnimations = self.numberOfAnimations - 1;
	
	if (self.numberOfAnimations < 1) {
		QSCallCompletionBlock(self.completion);
	}
}


- (void)animateTableAway {
	
	self.timelineViewController.searchOverlay.alpha = 1.0f;
	
	[self beginAnimationBlock];
	
	VSDetailTransitionView *smokescreenView = (VSDetailTransitionView *)(self.smokescreenView);
	
	self.searchResultsViewController.draggedNote = self.timelineNote;
	[self.searchResultsViewController.tableView reloadData]; /*Empties space for blank note*/
	
	UIImageView *tableAnimationView = [UIImageView rs_imageViewWithSnapshotOfView:self.searchResultsViewController.tableView clearBackground:NO];
	tableAnimationView.contentMode = UIViewContentModeBottom;
	[smokescreenView.tableContainerView addSubview:tableAnimationView];
	CGRect r = self.timelineViewController.tableView.bounds;
	r.origin = CGPointZero;
	
	tableAnimationView.frame = r;
	
	self.searchResultsViewController.draggedNote = nil;
	[self.searchResultsViewController.tableView reloadData]; /*Reclaim row for blank note*/
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailBackgroundNotes" animations:^{
		
		CGFloat tableAnimationScale = [app_delegate.theme floatForKey:@"detailBackgroundNotesScale"];
		CGFloat tableAnimationAlpha = [app_delegate.theme floatForKey:@"detailBackgroundNotesAlpha"];
		
		CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, tableAnimationScale, tableAnimationScale);
		tableAnimationView.transform = transform;
		tableAnimationView.alpha = tableAnimationAlpha;
		
	} completion:^(BOOL finished) {
		
		[self.timelineViewController performSelector:@selector(cleanupAfterAnimateTableAway) withObject:nil afterDelay:1.0f];
		[tableAnimationView removeFromSuperview];
		
		[self endAnimationBlock];
	}];
}


- (void)animateNavbar {
	
	[self beginAnimationBlock];
	
	VSDetailTransitionView *smokescreenView = (VSDetailTransitionView *)(self.smokescreenView);
	
	self.smokescreenView.navbar.hidden = YES;
	
	UIImage *imageOut = [self.timelineViewController.searchBarContainerView rs_snapshotImage:NO];
	UIImageView *imageOutView = [[UIImageView alloc] initWithImage:imageOut];
	imageOutView.frame = self.timelineViewController.searchBarContainerView.frame;
	imageOutView.contentMode = UIViewContentModeTop;
	[smokescreenView addSubview:imageOutView];
	
	CGFloat translationY = RSNavbarPlusStatusBarHeight();
	UIImage *imageIn = [self.detailViewController.navbar rs_snapshotImage:NO];
	UIImageView *imageInView = [[UIImageView alloc] initWithImage:imageIn];
	[smokescreenView addSubview:imageInView];
	CGRect rImageIn = CGRectMake(0.0f, -(translationY), imageIn.size.width, imageIn.size.height);
	imageInView.frame = rImageIn;
	imageInView.contentMode = UIViewContentModeTop;
	imageInView.alpha = [app_delegate.theme floatForKey:@"detailNavbarAlpha"];
	
	[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		
		imageOutView.alpha = 0.0f;
		CGFloat searchBarScale = [app_delegate.theme floatForKey:@"detailTransitionSearchBarScale"];
		CGAffineTransform searchBarTransform = CGAffineTransformScale(CGAffineTransformIdentity, searchBarScale, searchBarScale);
		imageOutView.transform = searchBarTransform;
		
		CGRect r = imageInView.frame;
		r.origin.y = 0.0f;
		imageInView.frame = r;
		imageInView.alpha = 1.0f;
		
	} completion:^(BOOL finished) {
		
		[self endAnimationBlock];
	}];
}


- (void)animateSelectedRow {
	
	[self beginAnimationBlock];
	
	//	BOOL noteHasThumbnail = self.timelineNote.hasThumbnail;
	
	VSTimelineCell *cell = (VSTimelineCell *)[self.searchResultsViewController.tableView cellForRowAtIndexPath:self.indexPath];
	
	cell.highlighted = NO;
	
	UIImage *selectedRowImage = [cell imageForAnimationWithThumbnailHidden:YES];
	UIImageView *selectedRowImageView = [[UIImageView alloc] initWithImage:selectedRowImage];
	CGRect rCell = cell.frame;
	rCell = [self.searchResultsViewController.tableView convertRect:rCell toView:self.smokescreenView];
	selectedRowImageView.frame = rCell;
	selectedRowImageView.contentMode = UIViewContentModeTop;
	selectedRowImageView.autoresizingMask = UIViewAutoresizingNone;
	
	[self.smokescreenView addSubview:selectedRowImageView];
	
	(void)self.detailViewController.view;
	UIImage *textViewImage = [self.detailViewController.detailView textImageForAnimation];
	
	UIImageView *textImageView = [[UIImageView alloc] initWithImage:textViewImage];
	textImageView.contentMode = UIViewContentModeTop;
	textImageView.autoresizingMask = UIViewAutoresizingNone;
	textImageView.alpha = 0.0f;
	CGRect rTextViewImage = rCell;
	rTextViewImage.origin.x = [app_delegate.theme floatForKey:@"detailTextMarginLeft"];
	rTextViewImage.size = textViewImage.size;
	textImageView.frame = rTextViewImage;
	
	[self.smokescreenView addSubview:textImageView];
	
	UIImageView *detailImageView = nil;
	if (self.detailAnimationImage != nil) {
		detailImageView = [[UIImageView alloc] initWithImage:self.detailAnimationImage];
		CGRect thumbnailRect = ((VSTimelineCell *)cell).thumbnailRect;
		thumbnailRect = [cell convertRect:thumbnailRect toView:self.smokescreenView];
		thumbnailRect = [VSThumbnail apparentRectForActualRect:thumbnailRect];
		detailImageView.frame = thumbnailRect;
		detailImageView.contentMode = UIViewContentModeScaleAspectFill;
		detailImageView.autoresizingMask = UIViewAutoresizingNone;
		detailImageView.clipsToBounds = YES;
		[self.smokescreenView addSubview:detailImageView];
	}
	
	UIImageView *tagsView = [UIImageView rs_imageViewWithSnapshotOfView:self.detailViewController.tagsScrollView clearBackground:YES];
	CGRect rTagsView = self.timelineViewController.view.bounds;
	rTagsView.origin.y = rTextViewImage.origin.y;
	rTagsView.origin.y += [self.detailViewController.textView vs_contentSize].height;
	rTagsView.origin.y += [app_delegate.theme floatForKey:@"tagDetailScrollViewMarginTop"];
	rTagsView.origin.x = 0.0f;
	tagsView.alpha = 0.0f;
	tagsView.frame = rTagsView;
	[self.smokescreenView addSubview:tagsView];
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailSelectedNote" animations:^{
		
		CGRect rDetailImageView = CGRectZero;
		rDetailImageView.origin.y = RSNavbarPlusStatusBarHeight();
		CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
		rDetailImageView.size.width = screenWidth;//[app_delegate.theme floatForKey:@"detailImageViewWidth"];
		rDetailImageView.size.height = screenWidth;//[app_delegate.theme floatForKey:@"detailImageViewHeight"];
		
		CGRect r = selectedRowImageView.frame;
		CGRect rTextView = self.detailViewController.textView.frame;
		rTextView = [self.smokescreenView convertRect:rTextView fromView:self.detailViewController.textView.superview];
		r.origin.y = rTextView.origin.y;
		
		if (detailImageView != nil)
			r.origin.y += rDetailImageView.size.height;
		//        if (noteHasThumbnail)
		//            r.origin.y -= 4.0f; /*fudge*/
		selectedRowImageView.frame = r;
		selectedRowImageView.alpha = 0.0f;
		
		r = textImageView.frame;
		r.origin.y = rTextView.origin.y;
		//		if (!noteHasThumbnail)
		//			r.origin.y += 4.0f;
		if (detailImageView != nil)
			r.origin.y += rDetailImageView.size.height;
		textImageView.frame = r;
		textImageView.alpha = 1.0f;
		
		if (detailImageView != nil)
			detailImageView.frame = rDetailImageView;
		
		tagsView.alpha = 1.0f;
		CGRect rTagsDestination = self.detailViewController.tagsScrollView.frame;
		tagsView.frame = rTagsDestination;
		
	} completion:^(BOOL finished) {
		
		[self endAnimationBlock];
	}];
}


- (void)runAnimations {
	
	[self animateTableAway];
	[self animateSelectedRow];
	[self animateNavbar];
}


#pragma mark - API

- (void)animate:(QSVoidCompletionBlock)completion {
	
	self.completion = completion;
	
	self.smokescreenView = (VSDetailTransitionView *)[self.timelineViewController addSmokescreenViewOfClass:[VSDetailTransitionView class]];
	[self runAnimations];
}


@end
