//
//  VSRootViewManager.h
//  Vesper
//
//  Created by Brent Simmons on 2/8/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol VSRootViewManager <NSObject>

@required

- (void)showViewController:(UIViewController *)viewController;


@end
