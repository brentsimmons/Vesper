//
//  VSSidebarViewController.h
//  Vesper
//
//  Created by Brent Simmons on 11/18/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSBaseViewController.h"
#import "VSRootViewManager.h"


@class VSTag;
@class VSSidebarView;
@class VSListViewController;


@interface VSSidebarViewController : VSBaseViewController

@property (nonatomic, weak) id<VSRootViewManager> rootViewManager;
@property (nonatomic, strong) VSSidebarView *sidebarView;

- (void)selectRowForTag:(VSTag *)tag; /*Updates selection in table view. Doesn't do anything else.*/

- (void)showInitialViewController;

@end

