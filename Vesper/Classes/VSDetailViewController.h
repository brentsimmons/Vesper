//
//  VSDetailViewController.h
//  Vesper
//
//  Created by Brent Simmons on 11/18/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "VSBaseViewController.h"



@class VSNote;
@class VSTag;
@class VSNavbarView;
@class VSDetailView;
@class VSDetailTextView;
@class VSTimelineViewController;
@class VSTagDetailScrollView;
@class VSSearchResultsViewController;


@interface VSDetailViewController : VSBaseViewController


/*If note is nil, then we're creating a new note.*/

- (id)initWithNote:(VSNote *)note tag:(VSTag *)tag backButtonTitle:(NSString *)backButtonTitle;

@property (nonatomic, strong, readonly) VSNavbarView *navbar;
@property (nonatomic, strong, readonly) VSDetailTextView *textView;
@property (nonatomic, assign, readonly) BOOL editing;

- (void)setInitialFullSizeImage:(UIImage *)image;

@property (nonatomic, strong, readonly) VSNote *note;

@property (nonatomic, strong, readonly) VSTagDetailScrollView *tagsScrollView;
@property (nonatomic, strong, readonly) VSDetailView *detailView;
@property (nonatomic, weak) VSNavbarView *parentNavbarView;
@property (nonatomic, weak) VSTimelineViewController *parentTimelineViewController;
@property (nonatomic, weak) VSSearchResultsViewController *parentSearchResultsViewController;

@end
