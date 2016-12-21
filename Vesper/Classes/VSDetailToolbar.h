//
//  VSDetailToolbar.h
//  Vesper
//
//  Created by Brent Simmons on 9/3/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@class VSDetailStatusView;


@interface VSDetailToolbar : UIToolbar

@property (nonatomic, assign) BOOL showRestoreButton; /*Default is NO; shows archive button instead*/

- (UIImageView *)imageViewForAnimation;

@property (nonatomic, readonly) VSDetailStatusView *statusView;


@end
