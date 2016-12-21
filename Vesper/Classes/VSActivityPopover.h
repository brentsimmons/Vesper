//
//  VSActivityPopover.h
//  Vesper
//
//  Created by Brent Simmons on 8/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VSMenuPopover.h"


/*Doesn't inherit from VSMenuPopover because we need UIToolbar for translucency and blurring.*/


@interface VSActivityPopover : UIToolbar

- (instancetype)initWithPopoverSpecifier:(NSString *)popoverSpecifier;

- (void)addItemWithTitle:(NSString *)title image:(UIImage *)image target:(id)target action:(SEL)action;

- (void)showInView:(UIView *)view fromBehindBar:(UIView *)bar animationDirection:(VSDirection)direction;

- (void)dismiss:(VSPopoverDidDismissCallback)completion;

@property (nonatomic, assign) BOOL showing;

@end
