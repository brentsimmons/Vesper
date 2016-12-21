//
//  VSPullToRefreshView.h
//  Vesper
//
//  Created by Brent Simmons on 3/2/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
	VSPullToRefreshIdle,
	VSPullToRefreshPulling,
	VSPullToRefreshLoading,
} VSPullToRefreshState;


@class VSPullToRefreshView;


@protocol VSPullToRefreshDelegate

- (void)refreshViewDidTriggerRefresh:(VSPullToRefreshView *)view;
- (BOOL)refreshViewIsRefreshing:(VSPullToRefreshView *)view;

@end


@interface VSPullToRefreshView : UIView <UIScrollViewDelegate>

- (id)initWithFrame:(CGRect)frame scrollView:(UIScrollView *)scrollView delegate:(id<VSPullToRefreshDelegate>)delegate;

@property (nonatomic, assign) BOOL refreshInProgress;

@end
