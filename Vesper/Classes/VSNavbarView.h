//
//  VSNavbarView.h
//  Vesper
//
//  Created by Brent Simmons on 2/6/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@class VSTheme;

@interface VSNavbarView : UIView

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) BOOL showComposeButton;

- (void)setupControls; /*Subclasses may override to create and place buttons*/
- (void)commonInit; /*Subclasses should call super first.*/

- (void)setAlphaForSubviews:(CGFloat)alpha; /*For animations*/

/*For subclasses*/

+ (UIImage *)sidebarImage;
+ (UIImage *)sidebarImagePressed;
+ (UIColor *)buttonTintColor;
+ (UIColor *)navbarTitleColor;

@property (nonatomic, strong) UIButton *sidebarButton;
@property (nonatomic, strong) UIButton *composeButton;
@property (nonatomic, strong) UILabel *titleField;

@property (nonatomic, assign, readonly) CGFloat statusBarHeight;
@property (nonatomic, assign, readonly) CGFloat heightMinusStatusBar;

/*Animations*/

- (UIImage *)imageForAnimation:(BOOL)includeRightmostButton;

@property (nonatomic, strong, readonly) UIFont *titleFieldFont;
@property (nonatomic, assign, readonly) CGRect rectForTitleField;

@end
