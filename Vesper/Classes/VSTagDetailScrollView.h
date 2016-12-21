//
//  VSTagDetailScrollView.h
//  Vesper
//
//  Created by Brent Simmons on 4/10/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


extern NSString *VSEditingTagViewOriginXDidChangeNotification;
extern NSString *VSEditingTagViewOriginXKey;
extern NSString *VSNewTagShouldStartNotification;
extern NSString *VSTagsDidEndEditingNotification;


@class VSTagButton;


@interface VSTagDetailScrollView : UIScrollView


- (instancetype)initWithFrame:(CGRect)frame tagProxies:(NSArray *)tagProxies;

@property (nonatomic, strong, readonly) NSArray *tagProxies;
@property (nonatomic, strong, readonly) NSArray *nonEditingTagProxies; /*Skips textField and ghost tag proxies*/

@property (nonatomic, assign) BOOL readonly;

- (void)userChoseSuggestedTagName:(NSString *)tagName;

- (void)deleteTagButton:(VSTagButton *)tagButton;

- (void)updateWithTagProxies:(NSArray *)tagProxies;


@end
