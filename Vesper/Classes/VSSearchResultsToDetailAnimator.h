//
//  VSSearchResultsToDetailAnimator.h
//  Vesper
//
//  Created by Brent Simmons on 3/17/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//



@class VSNote;
@class VSTimelineViewController;
@class VSDetailViewController;
@class VSSearchResultsViewController;


@interface VSSearchResultsToDetailAnimator : NSObject


- (instancetype)initWithNote:(VSNote *)note timelineNote:(VSTimelineNote *)timelineNote indexPath:(NSIndexPath *)indexPath image:(UIImage *)image searchResultsViewController:(VSSearchResultsViewController *)searchResultsViewController timelineViewController:(VSTimelineViewController *)timelineViewController detailViewController:(VSDetailViewController *)detailViewController;

- (void)animate:(QSVoidCompletionBlock)completion;



@end
