//
//  VSDetailToSearchResultsAnimator.m
//  Vesper
//
//  Created by Brent Simmons on 3/17/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSDetailToSearchResultsAnimator.h"
#import "VSTimelineViewController.h"
#import "VSSearchResultsViewController.h"
#import "VSTimelineCell.h"
#import "VSDetailTransitionView.h"
#import "VSThumbnail.h"
#import "VSDetailViewController.h"
#import "VSDetailTextView.h"
#import "VSTagDetailScrollView.h"
#import "VSNavbarView.h"
#import "VSSearchBarContainerView.h"
#import "VSDetailView.h"


@interface VSDetailToSearchResultsAnimator ()

@property (nonatomic, readonly) VSTimelineViewController *timelineViewController;
@property (nonatomic, readonly) VSDetailViewController *detailViewController;
@property (nonatomic, readonly) VSSearchResultsViewController *searchResultsViewController;
@property (nonatomic, readonly) NSIndexPath *indexPath;
@property (nonatomic, readonly) VSNote *note;
@property (nonatomic, readonly) VSTimelineNote *timelineNote;
@property (nonatomic, assign) NSUInteger numberOfAnimations;
@property (nonatomic, copy) QSVoidCompletionBlock completion;
@property (nonatomic) VSDetailTransitionView *smokescreenView;

@end


@implementation VSDetailToSearchResultsAnimator


#pragma mark - Init

- (instancetype)initWithNote:(VSNote *)note timelineNote:(VSTimelineNote *)timelineNote indexPath:(NSIndexPath *)indexPath timelineViewController:(VSTimelineViewController *)timelineViewController searchResultsViewController:(VSSearchResultsViewController *)searchResultsViewController detailViewController:(VSDetailViewController *)detailViewController {
	
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_note = note;
	_timelineNote = timelineNote;
	_indexPath = indexPath;
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


- (void)animateDetailTextToNote {
	
	[self beginAnimationBlock];
	
	VSTimelineCell *cell = (VSTimelineCell *)[self.searchResultsViewController.tableView cellForRowAtIndexPath:self.indexPath];
	cell.highlighted = NO;
	
	UIImage *selectedRowImage = [cell imageForAnimationWithThumbnailHidden:YES];
	UIImageView *selectedRowImageView = [[UIImageView alloc] initWithImage:selectedRowImage];
	CGRect rCell = cell.frame;
	rCell = [self.searchResultsViewController.tableView convertRect:rCell toView:self.smokescreenView];
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
	
	(void)self.detailViewController.view;
	UIImageView *textImageView = [[UIImageView alloc] initWithImage:[self.detailViewController.detailView textImageForAnimation]];
	CGRect rTextViewImage = rCell;
	rTextViewImage.origin.y = RSNavbarPlusStatusBarHeight() + self.detailViewController.textView.textContainerInset.top;
	rTextViewImage.origin.y -= 12.0f;
	rTextViewImage.origin.x = [app_delegate.theme floatForKey:@"detailTextMarginLeft"];
	rTextViewImage.size = textImageView.image.size;
	textImageView.frame = rTextViewImage;
	
	[self.smokescreenView addSubview:textImageView];
	
	UIImageView *tagsView = [UIImageView rs_imageViewWithSnapshotOfView:self.detailViewController.tagsScrollView clearBackground:YES];
	CGRect rTagsView = self.detailViewController.tagsScrollView.frame;
	tagsView.frame = rTagsView;
	[self.smokescreenView addSubview:tagsView];
	
	UIImageView *detailImageView = nil;
	if (self.detailViewController.textView.image != nil) {
		detailImageView = [[UIImageView alloc] initWithImage:self.detailViewController.textView.image];
		detailImageView.clipsToBounds = YES;
		detailImageView.contentMode = UIViewContentModeScaleAspectFill;
		CGRect rDetailImageView = CGRectZero;
		rDetailImageView.origin.y = RSNavbarPlusStatusBarHeight();// + detailViewController.textView.contentOffset.y;
		CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
		
		rDetailImageView.size.width = screenWidth;//[app_delegate.theme floatForKey:@"detailImageViewWidth"];
		rDetailImageView.size.height = screenWidth;//[app_delegate.theme floatForKey:@"detailImageViewHeight"];
		detailImageView.frame = rDetailImageView;
		[self.smokescreenView addSubview:detailImageView];
	}
	
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailSelectedNoteReverse" animations:^{
		
		selectedRowImageView.frame = rCell;
		selectedRowImageView.alpha = 1.0f;
		
		CGRect r = textImageView.frame;
		r.origin.y = rCell.origin.y;
		//        r.origin.y += 4.0f; /*fudge*/
		textImageView.frame = r;
		textImageView.alpha = 0.0f;
		
		if (detailImageView != nil) {
			CGRect thumbnailRect = cell.thumbnailRect;
			thumbnailRect = [cell convertRect:thumbnailRect toView:self.smokescreenView];
			thumbnailRect = [VSThumbnail apparentRectForActualRect:thumbnailRect];
			detailImageView.frame = thumbnailRect;
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
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	[self beginAnimationBlock];
	
	VSDetailTransitionView *smokescreenView = (VSDetailTransitionView *)(self.smokescreenView);
	smokescreenView.navbar.hidden = YES;
	
	UIImageView *searchbarImageView = [UIImageView rs_imageViewWithSnapshotOfView:self.timelineViewController.searchBarContainerView clearBackground:NO];
	CGRect rSearchBar = searchbarImageView.frame;
	rSearchBar = [self.timelineViewController.searchBarContainerView convertRect:rSearchBar toView:self.smokescreenView];
	//    rSearchBar.size = searchbarImageView.image.size;
	searchbarImageView.frame = rSearchBar;
	searchbarImageView.alpha = 0.0f;
	[smokescreenView addSubview:searchbarImageView];
	
	UIImageView *imageDetailView = [UIImageView rs_imageViewWithSnapshotOfView:self.detailViewController.navbar clearBackground:NO];
	[smokescreenView addSubview:imageDetailView];
	CGRect rImageDetail = CGRectMake(0.0f, 0.0f, imageDetailView.image.size.width, imageDetailView.image.size.height);
	imageDetailView.frame = rImageDetail;
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailNavbarReverse" animations:^{
		
		searchbarImageView.alpha = 1.0f;
		
		CGRect r = imageDetailView.frame;
		r.origin.y = -RSNavbarPlusStatusBarHeight();
		imageDetailView.frame = r;
		imageDetailView.alpha = [app_delegate.theme floatForKey:@"detailNavbarReverseAlpha"];
		
	} completion:^(BOOL finished) {
		
		[self endAnimationBlock];
	}];
}


- (void)animateTableIn {
	
	[self beginAnimationBlock];
	VSDetailTransitionView *smokescreenView = (VSDetailTransitionView *)(self.smokescreenView);
	
	self.searchResultsViewController.draggedNote = self.timelineNote;
	[self.searchResultsViewController.tableView reloadData];
	UIImageView *tableAnimationView = [UIImageView rs_imageViewWithSnapshotOfView:self.searchResultsViewController.tableView clearBackground:NO];
	self.searchResultsViewController.draggedNote = nil;
	[self.searchResultsViewController.tableView reloadData];
	tableAnimationView.contentMode = UIViewContentModeBottom;
	
	[smokescreenView.tableContainerView addSubview:tableAnimationView];
	CGRect rTableAnimation = self.searchResultsViewController.view.bounds;
	rTableAnimation.origin.y = 0.0f;
	rTableAnimation.origin.x = 0.0f;
	tableAnimationView.frame = rTableAnimation;
	
	CGFloat tableAnimationScale = [app_delegate.theme floatForKey:@"detailBackgroundNotesReverseScale"];
	CGFloat tableAnimationAlpha = [app_delegate.theme floatForKey:@"detailBackgroundNotesReverseAlpha"];
	CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, tableAnimationScale, tableAnimationScale);
	tableAnimationView.transform = transform;
	tableAnimationView.alpha = tableAnimationAlpha;
	
	UIImageView *searchBarImageView = [UIImageView rs_imageViewWithSnapshotOfView:(UIView *)self.timelineViewController.searchBarContainerView clearBackground:NO];
	[smokescreenView addSubview:searchBarImageView];
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
		
		[tableAnimationView removeFromSuperview];
		[self endAnimationBlock];
	}];
}


- (void)runAnimations {
	
	[self animateDetailTextToNote];
	[self animateNavbarAwayFromDetailView];
	[self animateTableIn];
}


#pragma mark - API

- (void)animate:(QSVoidCompletionBlock)completion {
	
	self.completion = completion;
	
	self.smokescreenView = (VSDetailTransitionView *)[self.timelineViewController addSmokescreenViewOfClass:[VSDetailTransitionView class]];
	[self runAnimations];
}


@end
