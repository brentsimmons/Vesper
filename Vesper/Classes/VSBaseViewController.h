//
//  VSBaseViewController.h
//  Vesper
//
//  Created by Brent Simmons on 2/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VSSmokescreenView.h"


extern NSString *VSFocusedViewControllerDidChangeNotification;
extern NSString *VSFocusedViewControllerKey;

@class VSBrowserViewController;


@interface VSBaseViewController : UIViewController

- (void)addViewControllerAndItsView:(UIViewController *)viewController;
- (void)removeViewControllerAndItsView:(UIViewController *)viewController;

- (void)pushViewController:(UIViewController *)viewController;
- (void)popViewController:(UIViewController *)viewController;

- (VSSmokescreenView *)addSmokescreenViewOfClass:(Class)viewClass; /*If smokescreen view exists, does nothing; else creates it and puts it on top; does not increment use count*/
- (void)incrementSmokeScreenViewUseCount;
- (void)decrementSmokeScreenViewUseCount; /*Smokescreen view is removed and destroyed when it hits 0.*/

@property (nonatomic, strong, readonly) VSSmokescreenView *smokescreenView;

@property (nonatomic, strong) VSBrowserViewController *browserViewController;

- (void)postFocusedViewControllerDidChangeNotification:(UIViewController *)focusedViewController;

@property (nonatomic, assign) BOOL isFocusedViewController;

- (void)openLinkInBrowser:(NSString *)urlString;

- (void)browserDone:(id)sender; /*For subclasses to call super*/

@end
