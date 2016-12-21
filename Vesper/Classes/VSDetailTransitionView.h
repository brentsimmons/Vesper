//
//  VSDetailTransitionView.h
//  Vesper
//
//  Created by Brent Simmons on 4/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSSmokescreenView.h"


@class VSNavbarView;

@interface VSDetailTransitionView : VSSmokescreenView

@property (nonatomic, strong, readonly) VSNavbarView *navbar;
@property (nonatomic, strong, readonly) UIView *tableContainerView;

@end
