//
//  VSDetailStatusView.h
//  Vesper
//
//  Created by Brent Simmons on 7/17/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

@import UIKit;


@interface VSDetailStatusView : UIView


/*Setting these updates the display appropriately.*/

@property (nonatomic) NSUInteger characterCount;
@property (nonatomic) NSUInteger wordCount;
@property (nonatomic) NSDate *creationDate;
@property (nonatomic) NSDate *modificationDate;


@end
