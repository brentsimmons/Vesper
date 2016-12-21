//
//  VSLinkButtonFooterView.h
//  Vesper
//
//  Created by Brent Simmons on 4/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@class VSLinkButtonFooterView;


@protocol VSLinkButtonFooterViewDelegate <NSObject>

@required

- (void)linkButtonFooterViewTapped:(VSLinkButtonFooterView *)linkButtonFooterView;

@end


@interface VSLinkButtonFooterView : UIView


- (instancetype)initWithText:(NSString *)text delegate:(id<VSLinkButtonFooterViewDelegate>)delegate;


@end
