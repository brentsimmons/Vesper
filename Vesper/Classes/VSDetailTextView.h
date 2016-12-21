//
//  VSDetailTextView.h
//  Vesper
//
//  Created by Brent Simmons on 4/17/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface VSDetailTextView : UITextView


- (instancetype)initWithFrame:(CGRect)frame imageSize:(CGSize)imageSize tagProxies:(NSArray *)tagProxies readonly:(BOOL)readonly;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, assign) BOOL readonly;
@property (nonatomic, assign) CGRect keyboardFrame;
@property (nonatomic, assign, readonly) BOOL editing;


- (CGSize)vs_contentSize; /*contentSize is apparently not working. As of iOS 7.0b5. Does ceilf on height and width.*/
- (void)setContentOffSetAnimatedForReal:(CGPoint)contentOffset;

- (UIView *)viewForAnimation:(BOOL)clearBackground;


@end


//void VSDoContentOffsetHack(void); /*Use this only if you don't have a reference to the VSDetailTextView.*/
