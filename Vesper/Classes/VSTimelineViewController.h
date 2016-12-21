//
//  VSTimelineViewController.h
//  Vesper
//
//  Created by Brent Simmons on 11/18/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//


#import "VSBaseViewController.h"


@class VSDetailViewController;
@class VSSearchBarContainerView;
@class VSSearchResultsViewController;
@class VSTag;
@class VSNote;
@class VSNavbarView;
@class VSListViewConfiguration;
@class VSTimelineContext;
@class VSTimelineDataSource;


@interface VSTimelineViewController : VSBaseViewController


- (instancetype)initWithContext:(VSTimelineContext *)context;


/*VSSearchResultsViewController support.*/

- (VSDetailViewController *)searchResultsViewController:(VSSearchResultsViewController *)searchResultsViewController showComposeViewWithNote:(VSNote *)note timelineNote:(VSTimelineNote *)timelineNote indexPath:(NSIndexPath *)indexPath;

- (void)searchResultsViewController:(VSSearchResultsViewController *)searchResultsViewController popDetailViewController:(VSDetailViewController *)detailViewController indexPath:(NSIndexPath *)indexPath note:(VSNote *)note animated:(BOOL)animated;

/*Detail pan-back animation support.*/

- (void)prepareForPanBackAnimationWithNote:(VSNote *)note;
- (UIImage *)dragImageForNote:(VSNote *)note;
- (CGRect)frameOfCellForNote:(VSNote *)note;

@property (nonatomic, strong) VSTimelineNote *draggedNote;
@property (nonatomic, strong, readonly) VSSearchBarContainerView *searchBarContainerView;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) VSNavbarView *navbar;


/*Animation support.*/

- (void)prepareForAnimation;
- (void)finishAnimation;

- (UIView *)tableAnimationView:(BOOL)clearBackground;
- (VSTimelineNote *)timelineNoteAtIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;

@property (nonatomic, readonly) VSTimelineContext *context;
@property (nonatomic, readonly) UIView *searchOverlay;


@end
