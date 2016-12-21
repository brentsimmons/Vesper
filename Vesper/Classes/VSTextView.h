//
//  VSTextView.h
//  Vesper
//
//  Created by Brent Simmons on 2/8/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@class VSNoteTextRenderer;

@interface VSTextView : UIView

@property (nonatomic, strong) UIColor *highlightedLinkBackgroundColor;
@property (nonatomic, strong) VSNoteTextRenderer *textRenderer;
@property (nonatomic, assign, readonly) BOOL truncated;
@property (nonatomic, assign, readonly) CGFloat widthOfTruncatedLine; /*return is undefined if not truncated*/
@property (nonatomic, assign, readonly) UIEdgeInsets edgeInsets; /*Make room for drawing outside text for rounded corners for links*/

+ (CGRect)fullRectForApparentRect:(CGRect)apparentRect; /*Adds edgeInsets*/

@end
