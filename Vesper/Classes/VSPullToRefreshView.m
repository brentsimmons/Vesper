//
//  VSPullToRefreshView.m
//  Vesper
//
//  Created by Brent Simmons on 3/2/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSPullToRefreshView.h"
#import "VSTheme.h"
#import "RSGeometry.h"
#import "UIView+RSExtras.h"


@interface VSPullToRefreshView ()

@property (nonatomic, strong) UILabel *refreshLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) id<VSPullToRefreshDelegate> delegate;
@property (nonatomic, assign) BOOL pulling;
@end



@implementation VSPullToRefreshView


#pragma mark Init

- (id)initWithFrame:(CGRect)frame scrollView:(UIScrollView *)scrollView delegate:(id<VSPullToRefreshDelegate>)delegate {

	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;

    _delegate = delegate;

    _scrollView = scrollView;
    _scrollView.delegate = self;

    for (UIView *oneSubview in _scrollView.subviews) { /*Hide shadows*/
        if ([oneSubview isKindOfClass:[UIImageView class]])
            oneSubview.hidden = YES;
    }
    
	self.backgroundColor = [app_delegate.theme colorForKey:@"pullToRefreshBackgroundColor"];
    _scrollView.backgroundColor = self.backgroundColor;
    
    _refreshLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _refreshLabel.text = NSLocalizedString(@"Refresh", @"Refresh");
    _refreshLabel.font = [app_delegate.theme fontForKey:@"pullToRefreshFont"];
    _refreshLabel.textColor = [app_delegate.theme colorForKey:@"pullToRefreshFontColor"];
    _refreshLabel.backgroundColor = self.backgroundColor;
    _refreshLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_refreshLabel];

    _arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"webview-downarrow"]];
    _arrowImageView.contentMode = UIViewContentModeCenter;
    [self addSubview:_arrowImageView];

    _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityView.hidesWhenStopped = YES;
    [_activityView sizeToFit];
    [self addSubview:_activityView];

//	_pullToRefreshState = VSPullToRefreshIdle;

    _height = frame.size.height;
    
    _scrollView.contentInset = UIEdgeInsetsMake(_height, 0.0f, 0.0f, 0.0f);
    [self setNeedsLayout];
    [self updateFrame];

//    [self addObserver:self forKeyPath:@"pullToRefreshState" options:0 context:nil];
    [self addObserver:self forKeyPath:@"refreshInProgress" options:NSKeyValueObservingOptionInitial context:nil];

    return self;
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

//    if ([keyPath isEqualToString:@"pullToRefreshState"] && object == self)
//        [self pullToRefreshStateDidChange];
    /*else */ if ([keyPath isEqualToString:@"refreshInProgress"] && object == self)
        [self refreshInProgressDidChange];
}


#pragma mark Dealloc

- (void)dealloc {
//    [self removeObserver:self forKeyPath:@"pullToRefreshState"];
    [self removeObserver:self forKeyPath:@"refreshInProgress"];
	_delegate = nil;
}


#pragma mark State

//- (void)pullToRefreshStateDidChange {
//
//    switch (self.pullToRefreshState) {
//
//        case VSPullToRefreshIdle:
//            [self.activityView stopAnimating];
//            self.refreshLabel.hidden = NO;
//            self.arrowImageView.hidden = NO;
//            break;
//
//        case VSPullToRefreshPulling:
//            break;
//
//        case VSPullToRefreshLoading:
//            [self.activityView startAnimating];
//            self.refreshLabel.hidden = YES;
//            self.arrowImageView.hidden = YES;
//            break;
//
//        default:
//            break;            
//    }
//
//    [self setNeedsLayout];
//}


- (void)refreshInProgressDidChange {


    if (self.refreshInProgress) {
        [self.activityView startAnimating];
        self.refreshLabel.hidden = YES;
        self.arrowImageView.hidden = YES;
//        self.scrollView.contentInset = UIEdgeInsetsMake(_height, 0.0f, 0.0f, 0.0f);
//        self.frame = CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.height);
    }

    else {
        [self.activityView stopAnimating];
        self.refreshLabel.hidden = NO;
        self.arrowImageView.hidden = NO;
    }
    
//    if (self.refreshInProgress) {
//
//        [self.activityView startAnimating];
//        self.refreshLabel.hidden = YES;
//        self.arrowImageView.hidden = YES;
//
//        self.scrollView.contentInset = UIEdgeInsetsMake(self.height, 0.0f, 0.0f, 0.0f);
////        self.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.height);
//   }
//
//    else {
//        [self.activityView stopAnimating];
//        self.refreshLabel.hidden = NO;
//        self.arrowImageView.hidden = NO;
//
////        [UIView animateWithDuration:0.25f animations:^{
//        self.scrollView.contentInset = UIEdgeInsetsZero;
//            self.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.height);
////        }];
//    }

    [self setNeedsLayout];
}


- (void)updateRefreshInProgress {

    BOOL refreshing = [self.delegate refreshViewIsRefreshing:self];
    if (refreshing)
        NSLog(@"REFRESHING");
    else
        NSLog(@"TOTALLY NOT refreshg");
    if (refreshing != self.refreshInProgress)
        self.refreshInProgress = refreshing;
}


#pragma mark Scroll view

- (void)updateFrame {

    CGRect r = self.frame;
    CGFloat contentOffsetY = -(self.scrollView.contentOffset.y);
    NSLog(@"contentOffsetY: %f", contentOffsetY);
    r.origin.y = 0.0f;
    r.size.height = contentOffsetY;
//    r.origin.y = contentOffsetY - self.height;
    [self rs_setFrameIfNotEqual:r];
}


static const CGFloat dragPadding = 5.0f;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    [self updateRefreshInProgress];

    [self updateFrame];
    if (self.refreshInProgress)
        return;
    
//    if (self.refreshInProgress) {
////		CGFloat offset = MAX(scrollView.contentOffset.y * -1, 0);
////		offset = MIN(offset, self.height);
//		scrollView.contentInset = UIEdgeInsetsMake(self.height, 0.0f, 0.0f, 0.0f);
//        return;
//    }

    
//    CGFloat bottomY = -(self.height + dragPadding);

//    if (scrollView.isDragging) {
//
//		if (self.pullToRefreshState == VSPullToRefreshPulling && scrollView.contentOffset.y > bottomY && scrollView.contentOffset.y < 0.0f)
//			self.pullToRefreshState = VSPullToRefreshIdle;
//        
//		else if (self.pullToRefreshState == VSPullToRefreshIdle && scrollView.contentOffset.y < bottomY)
//			self.pullToRefreshState = VSPullToRefreshPulling;
//
//		if (scrollView.contentInset.top != 0.0f)
//			scrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
//	}
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView {

    [self updateRefreshInProgress];

    [self updateFrame];
    CGFloat bottomY = -(self.height + dragPadding);
	if (scrollView.contentOffset.y <= bottomY) {

		[self.delegate refreshViewDidTriggerRefresh:self];
//        [UIView animateWithDuration:0.25f animations:^{
//            scrollView.contentInset = UIEdgeInsetsMake(self.height, 0.0f, 0.0f, 0.0f);
//        }];
	}
}


#pragma mark Drawing

- (BOOL)isOpaque {
	return YES;
}


#pragma mark Layout

static const CGFloat arrowRefreshPadding = 8.0f;

- (void)layoutSubviews {

    CGSize arrowImageSize = self.arrowImageView.image.size;
    CGSize refreshLabelSize = [self.refreshLabel sizeThatFits:self.bounds.size];

    CGFloat arrowMarginRight = [app_delegate.theme floatForKey:@"pullToRefreshArrowMarginRight"];
    CGRect r = CGRectZero;
    r.size.width = arrowImageSize.width + arrowMarginRight + refreshLabelSize.width;
    r.size.height = MAX(arrowImageSize.height, refreshLabelSize.height);
    r = CGRectCenteredInRect(r, self.bounds);

    CGRect rArrow = r;
    rArrow.size = arrowImageSize;
    [self.arrowImageView rs_setFrameIfNotEqual:rArrow];

    CGRect rActivity = self.activityView.frame;
    rActivity = CGRectCenteredInRect(rActivity, self.bounds);
    [self.activityView rs_setFrameIfNotEqual:rActivity];

    CGRect rRefreshLabel = r;
    rRefreshLabel.origin.x = CGRectGetMaxX(r) - refreshLabelSize.width;
    [self.refreshLabel rs_setFrameIfNotEqual:rRefreshLabel];
}


@end

