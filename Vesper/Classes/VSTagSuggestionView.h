//
//  VSTagSuggestionView.h
//  Vesper
//
//  Created by Brent Simmons on 4/9/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@class VSTagSuggestionView;

@protocol VSTagSuggestionViewDelegate <NSObject>

@required

- (void)tagSuggestionView:(VSTagSuggestionView *)tagSuggestionView didChooseTagName:(NSString *)tagName;

@end


@interface VSTagSuggestionView : UIView

+ (CGSize)size;

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<VSTagSuggestionViewDelegate>)delegate;


@property (nonatomic, strong) NSSet *tagNamesForNote; /*tag names the note already has*/

/*Setting userTypeTag will animate showing the view if needed -- if there's something to suggest and the view isn't already open. Setting it to nil or @"" will animate closing the view.*/

@property (nonatomic, strong) NSString *userTypedTag;

@end
