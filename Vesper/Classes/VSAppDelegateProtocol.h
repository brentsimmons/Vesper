//
//  VSAppDelegateProtocol.h
//  Vesper
//
//  Created by Brent Simmons on 2/12/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@import Foundation;


@class VSTheme;
@class VSTypographySettings;


@protocol VSAppDelegate <NSObject>

@required

@property (nonatomic, readonly) VSTheme *theme;
@property (nonatomic, readonly) VSTypographySettings *typographySettings;
@property (nonatomic, assign, readonly) BOOL firstRun;
@property (nonatomic, readonly) NSDate *firstRunDate;

#if USE_SAFARI_VIEW_CONTROLLER
- (void)openURL:(NSURL *)url;
#endif

#if TARGET_OS_IPHONE

@property (nonatomic, assign, readonly) BOOL sidebarShowing;
@property (nonatomic, readonly) UIViewController *rootRightSideViewController; /*timeline or credits; may have other views on top by z axis*/

#endif


@end
