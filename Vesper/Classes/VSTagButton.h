//
//  VSTagButton.h
//  Vesper
//
//  Created by Brent Simmons on 4/10/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VSEditableTagView.h"


@class VSTagProxy;
@class VSTagPopover;

@interface VSTagButton : UIButton <VSEditableTagView>

+ (CGSize)sizeWithTitle:(NSString *)title;
+ (instancetype)buttonWithTagProxy:(VSTagProxy *)tagProxy;

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) VSTagProxy *tagProxy;

@end
