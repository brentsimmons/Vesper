//
//  VSStatusBarNotification.h
//  Vesper
//
//  Created by Brent Simmons on 5/3/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//



@interface VSStatusBarNotification : NSObject


- (instancetype)initWithView:(UIView *)view;

- (void)show;
- (void)hide;


@end
