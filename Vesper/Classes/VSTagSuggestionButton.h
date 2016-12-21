//
//  VSTagSuggestionButton.h
//  Vesper
//
//  Created by Brent Simmons on 4/10/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface VSTagSuggestionButton : UIButton

+ (CGSize)sizeWithTitle:(NSString *)title;

+ (instancetype)buttonWithTitle:(NSString *)title;

@property (nonatomic, strong, readonly) NSString *tagName; /*Get this when pressed.*/

@end
