//
//  VSDetailView.h
//  Vesper
//
//  Created by Brent Simmons on 4/18/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VSTagSuggestionView.h"


extern NSString *VSFastSwitchFirstResponderNotification;

@class VSDetailTextView;
@class VSDetailNavbarView;
@class VSNote;
@class VSTagDetailScrollView;
@class VSDetailToolbar;

@interface VSDetailView : UIView <UIGestureRecognizerDelegate, VSTagSuggestionViewDelegate>

- (id)initWithFrame:(CGRect)frame backButtonTitle:(NSString *)backButtonTitle imageSize:(CGSize)imageSize tagProxies:(NSArray *)tagProxies readOnly:(BOOL)readOnly;

@property (nonatomic, strong, readonly) VSDetailTextView *textView;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong, readonly) VSDetailNavbarView *navbar;

@property (nonatomic, assign, readonly) BOOL keyboardShowing;
@property (nonatomic, strong, readonly) VSTagDetailScrollView *tagsScrollView;
@property (nonatomic, strong, readonly) VSTagSuggestionView *tagSuggestionView;
@property (nonatomic, strong, readonly) VSDetailToolbar *toolbar;

- (UIImage *)imageForAnimation; /*Text view; not navbar*/
- (UIImage *)textImageForAnimation; /*Text view, no attachment, no navbar*/

- (CGRect)rectOfTagsView;

@property (nonatomic, assign) BOOL aboutToClose; /*Detail view about to go away*/

/*Animation/interaction support*/

@property (nonatomic, strong, readonly) UIView *backingViewForTextView;
@property (nonatomic, strong, readonly) UIView *leftBorderView;


@end
