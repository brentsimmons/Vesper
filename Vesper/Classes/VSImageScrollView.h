//
//  VSImageScrollView.h
//  Vesper
//
//  Created by Brent Simmons on 4/16/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/*Displays image initially as aspect-fill, so we don't show the background.*/

@interface VSImageScrollView : UIScrollView <UIScrollViewDelegate>

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image;

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, assign) BOOL closing; /*For animation*/

@end
