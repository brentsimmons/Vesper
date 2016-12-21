//
//  VSMenuPopover.h
//  Vesper
//
//  Created by Brent Simmons on 5/6/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@class VSMenuPopover;

typedef void (^VSPopoverDidDismissCallback)(id popover);


extern NSString *VSPopoverDidDismissNotification;

@class VSPopoverBackgroundView;


/*Use init instead of initWithFrame. showFromPoint will take care of sizing.*/


typedef struct {
	UIEdgeInsets padding;
	CGSize chevronSize;
	CGFloat borderCornerRadius;
	CGFloat borderWidth;
	CGFloat backgroundAlpha;
	CGFloat marginLeft;
	CGFloat marginRight;
	CGFloat buttonHeight;
	CGFloat buttonWidth;
	CGFloat interButtonSpace;
	CGFloat fadeInDuration;
	CGFloat fadeOutDuration;
	CGFloat dividerWidth;
} VSMenuPopoverLayoutBits;



@interface VSMenuPopover : UIView

- (instancetype)initWithPopoverSpecifier:(NSString *)popoverSpecifier;

- (void)addItemWithTitle:(NSString *)title image:(UIImage *)image target:(id)target action:(SEL)action;

@property (nonatomic, assign) NSUInteger destructiveButtonIndex;
@property (nonatomic, assign) CGFloat width; /*It will be inset by padding specified in DB5; if not specified, uses width from view passed to showFromPoint:inView:*/
@property (nonatomic, assign) BOOL arrowOnTop; /*Default is YES*/
@property (nonatomic, assign) BOOL hasArrow; /*Default is YES*/

- (void)showFromPoint:(CGPoint)point inView:(UIView *)view backgroundViewRect:(CGRect)backgroundViewRect;

- (void)dismiss:(VSPopoverDidDismissCallback)completion;



/*For subclasses*/

- (void)removeButtons;
- (void)fadeIn;
- (void)addBackgroundView:(CGRect)backgroundViewRect view:(UIView *)view;

@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, assign) VSMenuPopoverLayoutBits layoutBits;
@property (nonatomic, strong) NSString *popoverSpecifier;
@property (nonatomic, strong) NSMutableArray *menuItems;
@property (nonatomic, assign) BOOL showing;
@property (nonatomic, assign) CGPoint chevronPoint; /*In superview coordinate space*/
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) VSPopoverBackgroundView *backgroundView;

- (UIBezierPath *)popoverPath;
- (void)addShadow;
- (void)layoutButtons;

@end
