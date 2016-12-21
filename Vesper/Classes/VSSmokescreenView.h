//
//  VSSmokescreenView.h
//  Vesper
//
//  Created by Brent Simmons on 4/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface VSSmokescreenView : UIView


- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor;


- (void)incrementUseCount;
- (void)decrementUseCount;

@property (nonatomic, assign, readonly) NSUInteger useCount;

@end
