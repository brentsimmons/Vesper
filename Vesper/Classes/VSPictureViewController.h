//
//  VSPictureViewController.h
//  Vesper
//
//  Created by Brent Simmons on 2/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSBaseViewController.h"
#import "VSImageScrollView.h"
#import "VSPictureNavbarView.h"


@interface VSPictureViewController : VSBaseViewController

- (instancetype)initWithImage:(UIImage *)image;

@property (nonatomic, strong, readonly) VSImageScrollView *scrollView;
@property (nonatomic, strong, readonly) VSPictureNavbarView *navbar;

@property (nonatomic, assign) BOOL readonly; /*Hide trash button if readonly*/

@end
