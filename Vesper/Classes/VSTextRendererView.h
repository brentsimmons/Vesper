//
//  VSTextRendererView.h
//  Vesper
//
//  Created by Brent Simmons on 5/21/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@class VSNoteTextRenderer;

@interface VSTextRendererView : UIView

@property (nonatomic, assign) BOOL highlightingLink;
@property (nonatomic, strong) id highlightedLinkID;
@property (nonatomic, strong) VSNoteTextRenderer *textRenderer;


@end
