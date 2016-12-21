//
//  UITextView+RSExtras.m
//  Vesper
//
//  Created by Brent Simmons on 4/17/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "UITextView+RSExtras.h"


@implementation UITextView (RSExtras)


static BOOL stringCharacterIsAllowedAsPartOfLink(NSString *s) {
	
	/*[s length] is assumed to be 0 or 1. s may be nil.
	 Totally not a strict check.*/
	
	if (s == nil || [s length] < 1)
		return NO;
	
	unichar ch = [s characterAtIndex:0];
	if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ch])
		return NO;
	return YES;
}


- (NSString *)rs_potentialLinkAtPoint:(CGPoint)point {
	
	/*Grow a string around the tap until hitting a space, cr, lf, or beginning or end of document.*/
	
	/*If we don't check for end of document, then you could tap way below end of text, and it would return a link if the last text was a link. This has the unfortunate side effect that you can't tap on the last character of a link if it appears at the end of a document. I can live with shipping that.*/
	
	UITextRange *textRange = [self characterRangeAtPoint:point];
	UITextPosition *endOfDocumentTextPosition = self.endOfDocument;
	if ([textRange.end isEqual:endOfDocumentTextPosition])
		return nil;
	
	UITextPosition *tapPosition = [self closestPositionToPoint:point];
	if (tapPosition == nil)
		return nil;
	
	NSMutableString *s = [NSMutableString stringWithString:@""];
	
	/*Move right*/
	
	UITextPosition *textPosition = tapPosition;
	
	BOOL isFirstCharacter = YES;
	
	while (true) {
		UITextRange *rangeOfCharacter = [self.tokenizer rangeEnclosingPosition:textPosition withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
		NSString *oneCharacter = [self textInRange:rangeOfCharacter];
		
		if (isFirstCharacter) {
			/*If first character is cr or lf, then we're off the right hand side of the link. Maybe way outside.*/
			if ([oneCharacter isEqualToString:@"\n"] || [oneCharacter isEqualToString:@"\r"])
				return nil;
		}
		
		isFirstCharacter = NO;
		
		if (!stringCharacterIsAllowedAsPartOfLink(oneCharacter))
			break;
		[s appendString:oneCharacter];
		
		textPosition = [self positionFromPosition:textPosition offset:1];
		if (textPosition == nil)
			break;
	}
	
	/*Move left*/
	
	textPosition = [self positionFromPosition:tapPosition offset:-1];
	if (textPosition != nil) {
		
		while (true) {
			UITextRange *rangeOfCharacter = [self.tokenizer rangeEnclosingPosition:textPosition withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
			NSString *oneCharacter = [self textInRange:rangeOfCharacter];
			
			if (!stringCharacterIsAllowedAsPartOfLink(oneCharacter))
				break;
			[s insertString:oneCharacter atIndex:0];
			
			textPosition = [self positionFromPosition:textPosition offset:-1];
			if (textPosition == nil)
				break;
		}
	}
	
	return s;
}


- (NSString *)rs_linkAtPoint:(CGPoint)point {
	
	NSString *potentialLink = [self rs_potentialLinkAtPoint:point];
	if (potentialLink == nil || [potentialLink length] < 1)
		return nil;
	
	NSArray *links = [potentialLink qs_links];
	if (links == nil || [links count] < 1)
		return nil;
	
	NSString *firstLink = links[0];
	return firstLink;
}


@end

