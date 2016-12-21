//
//  VSBrowserPullToRefreshView.h
//  Vesper
//
//  Created by Brent Simmons on 5/19/13.
//  Copyright 2013 Q Branch, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/*Based on https://github.com/enormego/EGOTableViewPullRefresh */


typedef enum{
	VSPullToRefreshNormal,
	VSPullToRefreshPulling,
	VSPullToRefreshLoading,
} VSPullToRefreshState;


@protocol VSPullToRefreshDelegate;


@interface VSBrowserPullToRefreshView : UIView

@property (nonatomic, weak) id<VSPullToRefreshDelegate> delegate;
@property (nonatomic, strong) NSString *lastUpdateFormatString;
@property (nonatomic, assign) VSPullToRefreshState pullToRefreshState;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, strong) NSURL *url;

- (void)refreshScrollViewDidScroll:(UIScrollView *)scrollView;
- (void)refreshScrollViewDidEndDragging:(UIScrollView *)scrollView;

@end


@protocol VSPullToRefreshDelegate

@required
- (void)refreshViewDidTriggerRefresh:(VSBrowserPullToRefreshView *)view;
- (BOOL)refreshViewDataSourceIsLoading:(VSBrowserPullToRefreshView *)view;
- (void)refreshView:(VSBrowserPullToRefreshView *)view willAnimateToContentInset:(UIEdgeInsets)contentInset;
- (void)refreshView:(VSBrowserPullToRefreshView *)view didAnimateToContentInset:(UIEdgeInsets)contentInset;

@end

