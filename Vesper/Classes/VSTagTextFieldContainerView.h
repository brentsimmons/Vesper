//
//  VSTagTextFieldContainerView.h
//  Vesper
//
//  Created by Brent Simmons on 4/12/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VSTagProxy;

extern NSString *VSTagDidBeginEditingNotification;
extern NSString *VSTagKey;

@interface VSTagTextFieldContainerView : UIView <UITextFieldDelegate>


+ (CGSize)initialSize;
+ (instancetype)tagTextFieldContainerViewWithTagProxy:(VSTagProxy *)tagProxy;

- (instancetype)initWithFrame:(CGRect)frame tagProxy:(VSTagProxy *)tagProxy;

@property (nonatomic, strong, readonly) VSTagProxy *tagProxy;

@property (nonatomic, assign, readonly) BOOL editing;
@property (nonatomic, strong, readonly) NSString *text;
@property (nonatomic, strong) NSString *userAcceptedSuggestedTag; /*Setting this changes the text*/

- (void)beginEditing; /*text field becomes first responder*/
- (void)updateTextForTagProxy;


@end
