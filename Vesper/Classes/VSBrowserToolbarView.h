//
//  VSBrowserToolbarView.h
//  Vesper
//
//  Created by Brent Simmons on 4/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VSNavbarView.h"


@class VSBrowserTextButton;

@interface VSBrowserToolbarView : UIToolbar

@property (nonatomic, strong) VSBrowserTextButton *doneButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) UIButton *activityButton;

@end
