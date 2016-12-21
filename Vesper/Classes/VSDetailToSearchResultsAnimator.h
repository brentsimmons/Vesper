//
//  VSDetailToSearchResultsAnimator.h
//  Vesper
//
//  Created by Brent Simmons on 3/17/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@class VSNote;
@class VSTimelineViewController;
@class VSDetailViewController;
@class VSSearchResultsViewController;


@interface VSDetailToSearchResultsAnimator : NSObject


- (instancetype)initWithNote:(VSNote *)note timelineNote:(VSTimelineNote *)timelineNote indexPath:(NSIndexPath *)indexPath timelineViewController:(VSTimelineViewController *)timelineViewController searchResultsViewController:(VSSearchResultsViewController *)searchResultsViewController detailViewController:(VSDetailViewController *)detailViewController;

- (void)animate:(QSVoidCompletionBlock)completion;


@end
