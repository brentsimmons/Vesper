//
//  NSString+RSExtras.m
//  Vesper
//
//  Created by Brent Simmons on 12/4/12.
//  Copyright (c) 2012 Ranchero Software. All rights reserved.
//

#import "NSString+RSExtras.h"


@implementation NSString (RSExtras)


- (NSString *)rs_firstLine {
	
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCharactersToBeSkipped:nil];
	NSString *title = nil;
	[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"] intoString:&title];
	return title;
}


- (BOOL)rs_hasNonWhitespaceAndNewlineCharacters {
	
	NSUInteger lengthOfText = [self length];
	NSUInteger i = 0;
	
	for (i = 0; i < lengthOfText; i++) {
		unichar ch = [self characterAtIndex:i];
		if (![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ch])
			return YES;
	}
	
	return NO;
}


- (NSUInteger)rs_indexOfCROrLF {
	
	NSRange rangeOfCR = [self rangeOfString:@"\r"];
	NSRange rangeOfLF = [self rangeOfString:@"\n"];
	
	if (rangeOfCR.length == 0 && rangeOfLF.length == 0)
		return NSNotFound;
	NSUInteger index = MIN(rangeOfCR.location, rangeOfLF.location);
	return index;
}


@end

