//
//  VSGroupedTableButtonViewCell.h
//  Vesper
//
//  Created by Brent Simmons on 5/2/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//



@interface VSGroupedTableButtonViewCell : UITableViewCell


- (instancetype)initWithLabelText:(NSString *)labelText destructive:(BOOL)destructive textAlignment:(NSTextAlignment)textAlignment;

- (void)startProgress;
- (void)stopProgress:(BOOL)success imageViewAnimationBlock:(QSVoidBlock)imageViewAnimationBlock;
- (void)clearProgressViews:(BOOL)animated;


@end
