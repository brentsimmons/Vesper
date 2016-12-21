//
//  VSTimelineToDetailAnimator.h
//  Vesper
//
//  Created by Brent Simmons on 3/16/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@class VSNote;
@class VSDetailViewController;
@class VSTimelineViewController;


@interface VSTimelineToDetailAnimator : NSObject


- (instancetype)initWithNote:(VSNote *)note indexPath:(NSIndexPath *)indexPath detailAnimationImage:(UIImage *)detailAnimationImage timelineViewController:(VSTimelineViewController *)timelineViewController detailViewController:(VSDetailViewController *)detailViewController;

- (void)animate:(QSVoidCompletionBlock)completion;



@end
