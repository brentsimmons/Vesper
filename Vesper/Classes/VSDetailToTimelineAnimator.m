//
//  VSDetailToTimelineAnimator.m
//  Vesper
//
//  Created by Brent Simmons on 3/17/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSDetailToTimelineAnimator.h"
#import "VSTimelineViewController.h"
#import "VSTimelineCell.h"
#import "VSDetailTransitionView.h"
#import "VSDetailViewController.h"
#import "VSDetailTextView.h"
#import "VSDetailView.h"
#import "VSTagDetailScrollView.h"
#import "VSThumbnail.h"
#import "VSTimelineContext.h"
#import "VSDetailNavbarView.h"
#import "VSSearchBarContainerView.h"
#import "VSDetailToolbar.h"


@interface VSDetailToTimelineAnimator ()

@property (nonatomic, readonly) VSTimelineViewController *timelineViewController;
@property (nonatomic, readonly) VSDetailViewController *detailViewController;
@property (nonatomic, assign) NSUInteger numberOfAnimations;
@property (nonatomic, copy) QSVoidCompletionBlock completion;
@property (nonatomic, readonly) NSIndexPath *indexPath;
@property (nonatomic) VSDetailTransitionView *smokescreenView;

@end


@implementation VSDetailToTimelineAnimator

#pragma mark - Init

- (instancetype)initWithNote:(VSNote *)note indexPath:(NSIndexPath *)indexPath timelineViewController:(VSTimelineViewController *)timelineViewController detailViewController:(VSDetailViewController *)detailViewController {
	
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_indexPath = indexPath;
	_timelineViewController = timelineViewController;
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


- (void)animateDetailTextToNote {
	
	[self beginAnimationBlock];
	
	UIImage *selectedRowImage = nil;
	
	VSTimelineCell *cell = nil;
	if (self.indexPath != nil) {
		cell = (VSTimelineCell *)[self.timelineViewController.tableView cellForRowAtIndexPath:self.indexPath];
		cell.highlighted = NO;
		selectedRowImage = [cell imageForAnimationWithThumbnailHidden:YES];
	}
	
	UIImageView *selectedRowImageView = nil;
	CGRect rCell = CGRectZero;
	if (selectedRowImage != nil) {
		
		selectedRowImageView = [[UIImageView alloc] initWithImage:selectedRowImage];
		rCell = cell.frame;
		rCell = [self.timelineViewController.tableView convertRect:rCell toView:self.smokescreenView];
		CGRect rCellStart = rCell;
		rCellStart.origin.y = RSNavbarPlusStatusBarHeight();
		CGRect rSelectedRowImageView = rCellStart;
		rSelectedRowImageView.origin.y -= 12.0f;
		rSelectedRowImageView.origin.y += self.detailViewController.textView.textContainerInset.top;
		selectedRowImageView.frame = rSelectedRowImageView;
		selectedRowImageView.contentMode = UIViewContentModeTop;
		selectedRowImageView.autoresizingMask = UIViewAutoresizingNone;
		selectedRowImageView.alpha = 0.0f;
		
		[self.smokescreenView addSubview:selectedRowImageView];
	}
	
	(void)self.detailViewController.view;
	UIImageView *textImageView = [[UIImageView alloc] initWithImage:[self.detailViewController.detailView textImageForAnimation]];
	CGRect rTextViewImage = CGRectZero;
	rTextViewImage.origin.y = RSNavbarPlusStatusBarHeight() + self.detailViewController.textView.textContainerInset.top;
	rTextViewImage.origin.y -= 12.0f;
	rTextViewImage.origin.x = [app_delegate.theme floatForKey:@"detailTextMarginLeft"];
	rTextViewImage.size = textImageView.image.size;
	textImageView.frame = rTextViewImage;
	
	[self.smokescreenView addSubview:textImageView];
	
	UIImageView *detailImageView = nil;
	if (self.detailViewController.textView.image != nil) {
		detailImageView = [[UIImageView alloc] initWithImage:self.detailViewController.textView.image];
		detailImageView.clipsToBounds = YES;
		detailImageView.contentMode = UIViewContentModeScaleAspectFill;
		CGRect rDetailImageView = [self.detailViewController.textView convertRect:self.detailViewController.textView.imageView.frame toView:self.smokescreenView];
		detailImageView.frame = rDetailImageView;
		[self.smokescreenView addSubview:detailImageView];
	}
	
	UIView *selectedRowBackingView = nil;
	
	if (selectedRowImageView != nil) {
		selectedRowBackingView = [[UIView alloc] initWithFrame:selectedRowImageView.frame];
		selectedRowBackingView.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
		selectedRowBackingView.opaque = NO;
		[self.smokescreenView insertSubview:selectedRowBackingView belowSubview:selectedRowImageView];
	}
	
	UIImageView *tagsView = [UIImageView rs_imageViewWithSnapshotOfView:self.detailViewController.tagsScrollView clearBackground:YES];
	CGRect rTagsView = [self.detailViewController.detailView rectOfTagsView];
	tagsView.frame = rTagsView;
	[self.smokescreenView addSubview:tagsView];
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailSelectedNoteReverse" animations:^{
		
		selectedRowImageView.frame = rCell;
		selectedRowImageView.alpha = 1.0f;
		selectedRowBackingView.frame = rCell;
		
		CGRect r = textImageView.frame;
		if (cell != nil) {
			r.origin.y = rCell.origin.y;
			//            r.origin.y += 4.0f; /*fudge*/
			textImageView.frame = r;
		}
		textImageView.alpha = 0.0f;
		
		if (detailImageView != nil && cell != nil) {
			CGRect thumbnailRect = cell.thumbnailRect;
			thumbnailRect = [cell convertRect:thumbnailRect toView:self.smokescreenView];
			thumbnailRect = [VSThumbnail apparentRectForActualRect:thumbnailRect];
			detailImageView.frame = thumbnailRect;
		}
		
		if (detailImageView != nil && cell == nil) {
			/*Note was deleted. Fade out image.*/
			detailImageView.alpha = 0.0f;
		}
		
		tagsView.alpha = 0.0f;
		
		CGRect rTagDestination = r;
		rTagDestination.origin.y += [self.detailViewController.textView vs_contentSize].height;
		rTagDestination.origin.y += [app_delegate.theme floatForKey:@"tagDetailScrollViewMarginTop"];
		tagsView.frame = rTagDestination;
		
		
	} completion:^(BOOL finished) {
		
		[self endAnimationBlock];
	}];
	
}


- (void)animateNavbarAwayFromDetailView {
	
	[self beginAnimationBlock];
	
	VSDetailTransitionView *smokescreenView = (VSDetailTransitionView *)(self.smokescreenView);
	
	BOOL plusButtonOnBothViews = self.timelineViewController.context.canMakeNewNotes;
	if (plusButtonOnBothViews)
		plusButtonOnBothViews = !((VSDetailNavbarView *)(self.detailViewController.navbar)).editMode;
	
	if (plusButtonOnBothViews) {
		UIImageView *plusButtonImageView = [UIImageView rs_imageViewWithSnapshotOfView:smokescreenView.navbar.composeButton clearBackground:NO];
		plusButtonImageView.frame = smokescreenView.navbar.composeButton.frame;
		[smokescreenView.navbar addSubview:plusButtonImageView];
	}
	smokescreenView.navbar.sidebarButton.hidden = YES;
	smokescreenView.navbar.composeButton.hidden = YES;
	smokescreenView.navbar.titleField.hidden = YES;
	
	UIImage *imageTimeline = [self.timelineViewController.navbar imageForAnimation:!plusButtonOnBothViews];
	UIImageView *imageTimelineView = [[UIImageView alloc] initWithImage:imageTimeline];
	[smokescreenView.navbar addSubview:imageTimelineView];
	imageTimelineView.frame = CGRectMake(0.0f, 0.0f, imageTimeline.size.width, imageTimeline.size.height);
	imageTimelineView.contentMode = UIViewContentModeTop;
	imageTimelineView.alpha = 0.0f;
	
	UIImage *imageDetail = [(VSDetailNavbarView *)(self.detailViewController.navbar) imageForAnimation:plusButtonOnBothViews];
	UIImageView *imageDetailView = [[UIImageView alloc] initWithImage:imageDetail];
	[smokescreenView.navbar addSubview:imageDetailView];
	CGRect rImageDetail = CGRectMake(0.0f, 0.0f, imageDetail.size.width, imageDetail.size.height);
	imageDetailView.frame = rImageDetail;
	imageDetailView.contentMode = UIViewContentModeTop;
	imageDetailView.alpha = 1.0f;
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailNavbarReverse" animations:^{
		
		CGRect r = imageTimelineView.frame;
		r.origin.y = 0.0f;
		
		imageTimelineView.frame = r;
		imageTimelineView.alpha = 1.0f;
		
		r = imageDetailView.frame;
		imageDetailView.frame = r;
		imageDetailView.alpha = [app_delegate.theme floatForKey:@"detailNavbarReverseAlpha"];
		
	} completion:^(BOOL finished) {
		
		[self endAnimationBlock];
	}];
}


- (void)animateTableIn {
	
	[self beginAnimationBlock];
	
	VSDetailTransitionView *smokescreenView = (VSDetailTransitionView *)(self.smokescreenView);
	
	self.timelineViewController.draggedNote = [self.timelineViewController timelineNoteAtIndexPath:self.indexPath];
	[self.timelineViewController reloadData];
	
	UIView *tableAnimationView = [self.timelineViewController tableAnimationView:NO];
	
	self.timelineViewController.draggedNote = nil;
	[self.timelineViewController reloadData];
	
	[smokescreenView.tableContainerView addSubview:tableAnimationView];
	CGRect r = self.timelineViewController.tableView.bounds;
	r.origin.y = 0.0f;
	r.origin.x = 0.0f;
	tableAnimationView.frame = r;
	
	CGFloat tableAnimationTranslationY = [app_delegate.theme floatForKey:@"detailBackgroundNotesReverseTranslationY"];
	CGFloat tableAnimationScale = [app_delegate.theme floatForKey:@"detailBackgroundNotesReverseScale"];
	CGFloat tableAnimationAlpha = [app_delegate.theme floatForKey:@"detailBackgroundNotesReverseAlpha"];
	CGRect rTableAnimation = tableAnimationView.frame;
	rTableAnimation.origin.y += tableAnimationTranslationY;
	tableAnimationView.frame = rTableAnimation;
	CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, tableAnimationScale, tableAnimationScale);
	tableAnimationView.transform = transform;
	tableAnimationView.alpha = tableAnimationAlpha;
	
	UIGraphicsBeginImageContextWithOptions(self.timelineViewController.searchBarContainerView.bounds.size, NO, [UIScreen mainScreen].scale);
	[self.timelineViewController.searchBarContainerView.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *searchBarImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIImageView *searchBarImageView = [[UIImageView alloc] initWithImage:searchBarImage];
	searchBarImageView.clipsToBounds = YES;
	searchBarImageView.contentMode = UIViewContentModeTop;
	searchBarImageView.autoresizingMask = UIViewAutoresizingNone;
	[smokescreenView.tableContainerView addSubview:searchBarImageView];
	CGRect rSearchBar = self.timelineViewController.searchBarContainerView.frame;
	rSearchBar.origin.y -= RSNavbarPlusStatusBarHeight();
	searchBarImageView.frame = rSearchBar;
	searchBarImageView.alpha = 0.0f;
	CGFloat searchBarScale = [app_delegate.theme floatForKey:@"detailTransitionSearchBarScale"];
	CGAffineTransform searchBarTransform = CGAffineTransformScale(CGAffineTransformIdentity, searchBarScale, searchBarScale);
	searchBarImageView.transform = searchBarTransform;
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailBackgroundNotesReverse" animations:^{
		
		tableAnimationView.transform = CGAffineTransformIdentity;
		CGRect rEnd = rTableAnimation;
		rEnd.origin.y = 0.0f;
		tableAnimationView.frame = rEnd;
		tableAnimationView.alpha = 1.0f;
		searchBarImageView.alpha = 1.0f;
		searchBarImageView.transform = CGAffineTransformIdentity;
		
	} completion:^(BOOL finished) {
		
		[self.timelineViewController performSelector:@selector(cleanupAfterAnimateTableAway) withObject:nil afterDelay:1.0f];
		[tableAnimationView removeFromSuperview];
		[self endAnimationBlock];
	}];
}


- (void)animateDetailToolbarOut {
	
	[self beginAnimationBlock];
	
	VSDetailTransitionView *smokescreenView = (VSDetailTransitionView *)(self.smokescreenView);
	
	VSDetailToolbar *toolbar = self.detailViewController.detailView.toolbar;
	UIImageView *toolbarImageView = [toolbar imageViewForAnimation];
	
	CGRect rToolbar = toolbar.frame;
	rToolbar = [self.timelineViewController.view convertRect:rToolbar fromView:self.detailViewController.detailView];
	rToolbar = [self.timelineViewController.view convertRect:rToolbar toView:self.smokescreenView];
	toolbarImageView.frame = rToolbar;
	
	toolbarImageView.alpha = 1.0f;
	[smokescreenView addSubview:toolbarImageView];
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailNavbarReverse" animations:^{
		
		toolbarImageView.alpha = 0.0f;
		
	} completion:^(BOOL finished) {
		
		[self endAnimationBlock];
	}];
}


- (void)runAnimations {
	
	[self animateDetailTextToNote];
	[self animateNavbarAwayFromDetailView];
	[self animateTableIn];
	[self animateDetailToolbarOut];
}


#pragma mark - API

- (void)animate:(QSVoidCompletionBlock)completion {
	
	self.completion = completion;
	
	self.smokescreenView = (VSDetailTransitionView *)[self.timelineViewController addSmokescreenViewOfClass:[VSDetailTransitionView class]];
	[self runAnimations];
}


@end
