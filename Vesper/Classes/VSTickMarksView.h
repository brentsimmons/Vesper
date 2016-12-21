//
//  VSTickMarksView.h
//  Vesper
//
//  Created by Brent Simmons on 8/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VSTickMarksView : UIView

- (instancetype)initWithSlider:(UISlider *)slider;

- (void)refresh;

@end
