//
//  VSTimelineToDetailAnimator.m
//  Vesper
//
//  Created by Brent Simmons on 3/16/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSTimelineToDetailAnimator.h"
#import "VSNote.h"
#import "VSTimelineViewController.h"
#import "VSDetailViewController.h"
#import "VSDetailTransitionView.h"
#import "VSTheme.h"
#import "VSSearchBarContainerView.h"
#import "VSTimelineCell.h"
#import "VSThumbnail.h"
#import "VSDetailTextView.h"
#import "VSTagDetailScrollView.h"
#import "VSNavbarView.h"
#import "VSDetailNavbarView.h"
#import "VSDetailToolbar.h"
#import "VSDetailView.h"


@interface VSTimelineToDetailAnimator ()

@property (nonatomic, readonly) VSNote *note;
@property (nonatomic, readonly) NSIndexPath *indexPath;
@property (nonatomic, readonly) VSTimelineViewController *timelineViewController;
@property (nonatomic, readonly) VSDetailViewController *detailViewController;
@property (nonatomic, readonly) UIImage *detailAnimationImage;
@property (nonatomic, assign) NSUInteger numberOfAnimations;
@property (nonatomic, copy) QSVoidCompletionBlock completion;
@property (nonatomic) VSDetailTransitionView *smokescreenView;

@end


@implementation VSTimelineToDetailAnimator


#pragma mark - Init

- (instancetype)initWithNote:(VSNote *)note indexPath:(NSIndexPath *)indexPath detailAnimationImage:(UIImage *)detailAnimationImage timelineViewController:(VSTimelineViewController *)timelineViewController detailViewController:(VSDetailViewController *)detailViewController {
	
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_note = note;
	_indexPath = indexPath;
	_detailAnimationImage = detailAnimationImage;
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


- (void)animateTableAway {
	
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
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailBackgroundNotes" animations:^{
		
		CGFloat tableAnimationTranslationY = [app_delegate.theme floatForKey:@"detailBackgroundNotesTranslationY"];
		CGFloat tableAnimationScale = [app_delegate.theme floatForKey:@"detailBackgroundNotesScale"];
		CGFloat tableAnimationAlpha = [app_delegate.theme floatForKey:@"detailBackgroundNotesAlpha"];
		CGRect rTableAnimation = tableAnimationView.frame;
		rTableAnimation.origin.y += tableAnimationTranslationY;
		tableAnimationView.frame = rTableAnimation;
		
		CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, tableAnimationScale, tableAnimationScale);
		tableAnimationView.transform = transform;
		tableAnimationView.alpha = tableAnimationAlpha;
		
		searchBarImageView.alpha = 0.0f;
		CGFloat searchBarScale = [app_delegate.theme floatForKey:@"detailTransitionSearchBarScale"];
		CGAffineTransform searchBarTransform = CGAffineTransformScale(CGAffineTransformIdentity, searchBarScale, searchBarScale);
		searchBarImageView.transform = searchBarTransform;
		
	} completion:^(BOOL finished) {
		
		[self.timelineViewController performSelector:@selector(cleanupAfterAnimateTableAway) withObject:nil afterDelay:1.0f];
		[tableAnimationView removeFromSuperview];
		[self endAnimationBlock];
	}];
}


- (void)animateSelectedRow {
	
	VSTimelineNote *note = [self.timelineViewController timelineNoteAtIndexPath:self.indexPath];
	if (note == nil)
		return;
	
	[self beginAnimationBlock];
	
	//    BOOL noteHasThumbnail = note.hasThumbnail;
	
	UITableViewCell *cell = [self.timelineViewController.tableView cellForRowAtIndexPath:self.indexPath];
	
	cell.highlighted = NO;
	
	UIImageView *selectedRowImageView = nil;
	UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, [UIScreen mainScreen].scale);
	((VSTimelineCell *)cell).renderingForAnimation = YES;
	((VSTimelineCell *)cell).hideThumbnail = YES;
	[cell.layer renderInContext:UIGraphicsGetCurrentContext()];
	((VSTimelineCell *)cell).renderingForAnimation = NO;
	((VSTimelineCell *)cell).hideThumbnail = NO;
	UIImage *selectedRowImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	selectedRowImageView = [[UIImageView alloc] initWithImage:selectedRowImage];
	CGRect rCell = cell.frame;
	rCell = [self.timelineViewController.tableView convertRect:rCell toView:self.smokescreenView];
	selectedRowImageView.frame = rCell;
	selectedRowImageView.contentMode = UIViewContentModeTop;
	selectedRowImageView.autoresizingMask = UIViewAutoresizingNone;
	
	[self.smokescreenView addSubview:selectedRowImageView];
	
	(void)self.detailViewController.view;
	UIImage *textViewImage = [self.detailViewController.detailView textImageForAnimation];
	
	//    if (!noteHasThumbnail)
	//        textViewImage = [self.detailViewController imageForAnimation];
	//
	//    else
	//        textViewImage = [self.detailViewController.textView rs_snapshotImage:YES];
	
	UIImageView *textImageView = [[UIImageView alloc] initWithImage:textViewImage];
	textImageView.contentMode = UIViewContentModeTop;
	textImageView.autoresizingMask = UIViewAutoresizingNone;
	textImageView.alpha = 0.0f;
	CGRect rTextViewImage = rCell;
	//    if (noteHasThumbnail) {
	rTextViewImage.origin.x = [app_delegate.theme floatForKey:@"detailTextMarginLeft"];
	//		rTextViewImage.origin.y = rCell.origin.y;// + 4.0f; /*fudge*/
	//    }
	//    else {
	//        rTextViewImage.origin.x = 0.0f;
	//    }
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
	
	UIView *selectedRowBackingView = [[UIView alloc] initWithFrame:selectedRowImageView.frame];
	selectedRowBackingView.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	selectedRowBackingView.opaque = NO;
	[self.smokescreenView insertSubview:selectedRowBackingView belowSubview:selectedRowImageView];
	
	UIImageView *tagsView = [UIImageView rs_imageViewWithSnapshotOfView:self.detailViewController.tagsScrollView clearBackground:YES];
	CGRect rTagsView = self.timelineViewController.view.bounds;
	rTagsView.origin.y = rTextViewImage.origin.y;
	rTagsView.origin.y += [self.detailViewController.textView vs_contentSize].height;
	rTagsView.origin.y += [app_delegate.theme floatForKey:@"tagDetailScrollViewMarginTop"];
	rTagsView.origin.x = 0.0f;
	tagsView.alpha = 0.0f;
	tagsView.frame = rTagsView;
	[self.smokescreenView insertSubview:tagsView belowSubview:selectedRowBackingView];
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailSelectedNote" animations:^{
		
		CGRect rDetailImageView = CGRectZero;
		rDetailImageView.origin.y = RSNavbarPlusStatusBarHeight();
		CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
		rDetailImageView.size.width = screenWidth;//[app_delegate.theme floatForKey:@"detailImageViewWidth"];
		rDetailImageView.size.height = screenWidth;//[app_delegate.theme floatForKey:@"detailImageViewHeight"];
		
		CGRect r = selectedRowImageView.frame;
		r.origin.y = RSNavbarPlusStatusBarHeight();
		if (detailImageView != nil)
			r.origin.y += rDetailImageView.size.height;
		//        if (noteHasThumbnail)
		//            r.origin.y -= 4.0f; /*fudge*/
		//		r.origin.y += 4.0f; /*more fudge*/
		selectedRowImageView.frame = r;
		selectedRowImageView.alpha = 0.0f;
		selectedRowBackingView.frame = r;
		
		r = textImageView.frame;
		r.origin.y = RSNavbarPlusStatusBarHeight();
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


- (void)animateNavbar {
	
	[self beginAnimationBlock];
	
	VSDetailTransitionView *smokescreenView = (VSDetailTransitionView *)(self.smokescreenView);
	
	BOOL plusButtonOnBothViews = (self.note != nil); /*If there's a note, we'll have a keyboard/done button*/
	if (self.note.archived)
		plusButtonOnBothViews = NO; /*Archived screen doesn't have a plus button*/
	
	if (plusButtonOnBothViews) {
		UIImageView *plusButtonImageView = [UIImageView rs_imageViewWithSnapshotOfView:self.smokescreenView.navbar.composeButton clearBackground:NO];
		plusButtonImageView.frame = self.smokescreenView.navbar.composeButton.frame;
		[smokescreenView.navbar addSubview:plusButtonImageView];
	}
	smokescreenView.navbar.sidebarButton.hidden = YES;
	smokescreenView.navbar.composeButton.hidden = YES;
	smokescreenView.navbar.titleField.hidden = YES;
	
	UIImage *imageOut = [self.timelineViewController.navbar imageForAnimation:!plusButtonOnBothViews];
	UIImageView *imageOutView = [[UIImageView alloc] initWithImage:imageOut];
	imageOutView.frame = CGRectMake(0.0f, 0.0f, imageOut.size.width, imageOut.size.height);
	imageOutView.contentMode = UIViewContentModeTop;
	[smokescreenView.navbar addSubview:imageOutView];
	
	UIImage *imageIn = [(VSDetailNavbarView *)(self.detailViewController.navbar) imageForAnimation:!plusButtonOnBothViews];
	UIImageView *imageInView = [[UIImageView alloc] initWithImage:imageIn];
	[smokescreenView.navbar addSubview:imageInView];
	CGRect rImageIn = CGRectMake(0.0f, 0.0f, imageIn.size.width, imageIn.size.height);
	imageInView.frame = rImageIn;
	imageInView.contentMode = UIViewContentModeTop;
	imageInView.alpha = [app_delegate.theme floatForKey:@"detailNavbarAlpha"];
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailNavbar" animations:^{
		
		imageOutView.alpha = [app_delegate.theme floatForKey:@"detailNavbarAlpha"];
		imageInView.alpha = 1.0f;
		
	} completion:^(BOOL finished) {
		
		[self endAnimationBlock];
	}];
}


- (void)animateDetailToolbarIn {
	
	[self beginAnimationBlock];
	
	VSDetailTransitionView *smokescreenView = (VSDetailTransitionView *)(self.smokescreenView);
	
	VSDetailToolbar *toolbar = self.detailViewController.detailView.toolbar;
	UIImageView *toolbarImageView = [toolbar imageViewForAnimation];
	
	CGRect rToolbar = toolbar.frame;
	rToolbar = [self.timelineViewController.view convertRect:rToolbar fromView:self.detailViewController.detailView];
	rToolbar = [self.timelineViewController.view convertRect:rToolbar toView:self.smokescreenView];
	toolbarImageView.frame = rToolbar;
	
	toolbarImageView.alpha = 0.0f;
	[smokescreenView addSubview:toolbarImageView];
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailNavbar" animations:^{
		
		toolbarImageView.alpha = 1.0f;
		
	} completion:^(BOOL finished) {
		
		[self endAnimationBlock];
		
	}];
}


- (void)runDetailViewAnimations {
	
	[self animateTableAway];
	[self animateSelectedRow];
	[self animateNavbar];
	[self animateDetailToolbarIn];
	
}


#pragma mark - API

- (void)animate:(QSVoidCompletionBlock)completion {
	
	self.completion = completion;
	
	self.smokescreenView = (VSDetailTransitionView *)[self.timelineViewController addSmokescreenViewOfClass:[VSDetailTransitionView class]];
	[self runDetailViewAnimations];
}


@end
