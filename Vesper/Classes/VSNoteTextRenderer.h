//
//  VSNoteTextRenderer.h
//  Vesper
//
//  Created by Brent Simmons on 5/9/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>


extern NSString *VSLinkAttributeName;
extern NSString *VSLinkUniqueIDAttributeName;
extern NSString *VSLinkHighlightedColorAttributeName;


@interface VSNoteTextRenderer : NSObject


- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text links:(NSArray *)links width:(CGFloat)textWidth useItalicFonts:(BOOL)useItalicFonts truncateIfNeeded:(BOOL)truncateIfNeeded;


@property (nonatomic, assign, readonly) CGFloat height;
@property (nonatomic, assign, readonly) BOOL truncated;

@property (nonatomic, strong, readonly) NSArray *links;
@property (nonatomic, strong, readonly) NSString *fullText;
@property (nonatomic, assign, readonly) NSUInteger maximumNumberOfLines;

/*These may be nil if links is empty.*/

@property (nonatomic, strong, readonly) NSAttributedString *attributedText;
@property (nonatomic, assign, readonly) CTFramesetterRef framesetter;
@property (nonatomic, assign, readonly) CTFrameRef frameref;

- (void)renderTextInRect:(CGRect)r;
- (void)renderTextInRect:(CGRect)r highlightedLinkID:(id)linkUniqueID;


@end
