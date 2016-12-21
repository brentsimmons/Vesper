//
//  VSDescriptionView.h
//  Vesper
//
//  Created by Brent Simmons on 4/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@interface VSDescriptionView : UIView


- (instancetype)initWithText:(NSString *)text edgeInsets:(UIEdgeInsets)edgeInsets;

@property (nonatomic, readonly) UILabel *label;

- (void)updateText:(NSString *)s color:(UIColor *)color;

@end
