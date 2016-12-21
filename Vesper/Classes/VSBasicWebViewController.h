//
//  VSBasicWebViewController.h
//  Vesper
//
//  Created by Brent Simmons on 4/23/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@interface VSBasicWebViewController : UIViewController

- (instancetype)initWithURL:(NSURL *)URL fallbackResourceName:(NSString *)fallbackResourceName title:(NSString *)title;

@property (nonatomic) BOOL hasCloseButton; /*Set YES if it's modal*/


@end
