//
//  VSMenuButton.h
//  Vesper
//
//  Created by Brent Simmons on 5/6/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef struct {
	CGFloat cornerRadius;
	CGFloat borderWidth;
	VSTextCaseTransform textCaseTransform;
} VSMenuButtonLayoutBits;


@class VSMenuItem;

@interface VSMenuButton : UIButton


- (instancetype)initWithFrame:(CGRect)frame menuItem:(VSMenuItem *)menuItem destructive:(BOOL)destructive popoverSpecifier:(NSString *)popoverSpecifier;


@property (nonatomic, weak, readonly) VSMenuItem *menuItem;
@property (nonatomic, assign) VSMenuButtonLayoutBits layoutBits;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) BOOL destructive;

- (NSAttributedString *)attributedTitleStringWithColor:(UIColor *)color;
- (NSAttributedString *)attributedTitle;
- (NSAttributedString *)attributedTitlePressed;


@end
