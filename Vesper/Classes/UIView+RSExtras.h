//
//  UIView+RSExtras.h
//  Vesper
//
//  Created by Brent Simmons on 12/6/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


BOOL RSIsRetinaScreen(void);
CGFloat RSStatusBarHeight(void);

CGFloat RSNavbarPlusStatusBarHeight(void); /*Navbar plus *normal* status bar height*/
CGRect RSStatusBarFrame(void); /*Actual status bar frame*/
CGRect RSNormalStatusBarFrame(void); /*Non-extended status bar*/

CGFloat RSContentViewHeight(void); /*normal status bar + rest of screen. Takes extended status bar into account and shrinks height.*/
CGRect RSFullViewRect(void); /*Full screen -- but takes extended status bar into account. Height comes from RSContentViewHeight().*/
CGRect RSRectForMainView(void); /*Rect for the view underneath the navbar. Often a table view.*/
CGRect RSNavbarRect(void); /*0.0f, 0.0f, screen width, navbar + normal status bar height*/


@class VSAnimationSpecifier;

@interface UIView (RSExtras)

- (void)rs_addConstraintsWithThemeKey:(NSString *)themeKey viewName:(NSString *)viewName view:(UIView *)view;

+ (UIViewAnimationOptions)rs_animationOptionsWithAnimationCurve:(UIViewAnimationCurve)animationCurve;

- (UIImage *)rs_snapshotImage:(BOOL)clearBackground; /*Simple renderInContext; if clear, sets background to UIColor clearColor, calls .opaque = NO, then restores*/
- (UIImageView *)rs_snapshotImageView:(BOOL)clearBackground; /*Calls rs_snapshotImage:*/

+ (void)rs_animateWithAnimationSpecifier:(VSAnimationSpecifier *)animationSpecifier animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;


@end
