//
//  VSSyncForgotPasswordViewController.h
//  Vesper
//
//  Created by Brent Simmons on 5/20/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


NSString *VSSyncForgotPasswordEmailAddressUsedNotification;
NSString *VSSyncForgotPasswordEmailAddress;


@interface VSSyncForgotPasswordViewController : UIViewController


- (instancetype)initWithEmailAddress:(NSString *)emailAddress;

@end
