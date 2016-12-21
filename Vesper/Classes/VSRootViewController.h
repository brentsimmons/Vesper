//
//  VSRootViewController.h
//  Vesper
//
//  Created by Brent Simmons on 11/18/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSBaseViewController.h"
#import "VSRootViewManager.h"


/*Manages two child controllers:

 1. Sidebar - VSSidebarViewController
 2. Main view - VSListViewController, usually

 */


@interface VSRootViewController : VSBaseViewController <VSRootViewManager>


@property (nonatomic, strong, readonly) UIViewController *dataViewController; /*the non-sidebar view controller: timeline or credits etc.; may have other views on top by z-axis*/


@end
