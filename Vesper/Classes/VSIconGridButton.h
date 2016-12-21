//
//  VSIconGridButton.h
//  Vesper
//
//  Created by Brent Simmons on 5/13/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@class VSMenuItem;


@interface VSIconGridButton : UIButton


- (instancetype)initWithFrame:(CGRect)frame menuItem:(VSMenuItem *)menuItem destructive:(BOOL)destructive popoverSpecifier:(NSString *)popoverSpecifier;


@property (nonatomic, weak, readonly) VSMenuItem *menuItem;


@end
