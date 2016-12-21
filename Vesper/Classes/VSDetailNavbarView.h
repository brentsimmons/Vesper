//
//  VSDetailNavbarView.h
//  Vesper
//
//  Created by Brent Simmons on 4/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSNavbarView.h"


@interface VSDetailNavbarView : VSNavbarView

@property (nonatomic, assign) BOOL editMode;

- (id)initWithFrame:(CGRect)frame backButtonTitle:(NSString *)backButtonTitle;

- (UIImage *)imageForAnimation:(BOOL)includePlusButton;

//- (UIImage *)fullWidthImageForAnimation; /*Includes plus button or whatever is rightmost*/

@property (nonatomic, assign) BOOL readonly; /*If YES, hide camera and plus buttons.*/

- (void)displayKeyboardButton; /*forces switch to editMode immediately, without animation*/

@property (nonatomic, strong, readonly) UIButton *activityButton;

/*Pan-back animation/interaction support*/

@property (nonatomic, assign) CGFloat panbackPercent;
@property (nonatomic, strong, readonly) UILabel *panbackLabel;
@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UIImageView *panbackChevron;

@end
