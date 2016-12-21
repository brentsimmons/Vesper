//
//  VSDetailToTimelineAnimator.h
//  Vesper
//
//  Created by Brent Simmons on 3/17/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//



@class VSTimelineViewController;
@class VSDetailViewController;


@interface VSDetailToTimelineAnimator : NSObject


- (instancetype)initWithNote:(VSNote *)note indexPath:(NSIndexPath *)indexPath timelineViewController:(VSTimelineViewController *)timelineViewController detailViewController:(VSDetailViewController *)detailViewController;

- (void)animate:(QSVoidCompletionBlock)completion;


@end
