//
//  VSTimelineCellButtonContainer.h
//  Vesper
//
//  Created by Brent Simmons on 8/11/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface VSTimelineCellButtonContainer : UIView


- (id)initWithFrame:(CGRect)frame buttons:(NSArray *)buttons themeSpecifier:(NSString *)themeSpecifier;

@property (nonatomic, assign, readonly) CGFloat widthOfButtons;


@end
