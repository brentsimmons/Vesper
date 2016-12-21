//
//  NSString+RSExtras.h
//  Vesper
//
//  Created by Brent Simmons on 12/4/12.
//  Copyright (c) 2012 Ranchero Software. All rights reserved.
//


@import Foundation;


@interface NSString (RSExtras)


- (NSString *)rs_firstLine; /*Text until cr or lf.*/
- (NSUInteger)rs_indexOfCROrLF;

- (BOOL)rs_hasNonWhitespaceAndNewlineCharacters;

@end
