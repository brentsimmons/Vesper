//
//  VSPopoverBackgroundView.h
//  Vesper
//
//  Created by Brent Simmons on 5/14/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@class VSPopoverBackgroundView;

@protocol VSPopoverBackgroundViewDelegate <NSObject>

@required
- (void)didTapPopoverBackgroundView:(VSPopoverBackgroundView *)popoverBackgroundView;

@end


@interface VSPopoverBackgroundView : UIView

- (id)initWithFrame:(CGRect)frame popoverSpecifier:(NSString *)popoverSpecifier delegate:(id<VSPopoverBackgroundViewDelegate>)delegate;

- (void)restoreInitialAlpha;

@end
