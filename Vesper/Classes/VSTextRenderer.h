//
//  VSTextRenderer.h
//  Vesper
//
//  Created by Brent Simmons on 2/8/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>


extern NSString *VSLinkAttributeName;
extern NSString *VSLinkUniqueIDAttributeName;
extern NSString *VSLinkHighlightedColorAttributeName;


@interface VSTextRenderer : NSObject


/*punchoutRect makes space for an image (or other rectangle) that the text wraps around.
 Coordinates for punchoutRect should be based on top-left.
 If it's CGRectZero, it's ignored.
 If maximumNumberOfLines is 0, that means there's no limit.*/

- (id)initWithText:(NSString *)text links:(NSArray *)links textColor:(UIColor *)textColor linkColor:(UIColor *)linkColor linkHighlightedColor:(UIColor *)linkHighlightedColor font:(UIFont *)font linkFont:(UIFont *)linkFont width:(CGFloat)width punchoutRect:(CGRect)punchoutRect maximumNumberOfLines:(NSUInteger)maximumNumberOfLines lineSpacing:(CGFloat)lineSpacing;


@property (nonatomic, assign, readonly) CGFloat height;
@property (nonatomic, assign, readonly) BOOL truncated;
@property (nonatomic, strong, readonly) NSString *text;
@property (nonatomic, strong, readonly) NSArray *links;
@property (nonatomic, assign, readonly) CGRect punchoutRect;
@property (nonatomic, assign, readonly) NSUInteger maximumNumberOfLines;

/*These may be nil if links is empty. There's no need to keep these around once the renderedImage has been created, and you don't need to refer to these to figure out where links are placed.*/

@property (nonatomic, strong, readonly) NSAttributedString *attributedText;
@property (nonatomic, assign, readonly) CTFramesetterRef framesetter;
@property (nonatomic, assign, readonly) CTFrameRef frameref;

- (void)renderTextInRect:(CGRect)r;
- (void)renderTextInRect:(CGRect)r highlightedLinkID:(id)linkUniqueID;

@end
