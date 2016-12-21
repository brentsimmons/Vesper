//
//  VSInputTextTableViewCell.h
//  Vesper
//
//  Created by Brent Simmons on 4/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@protocol VSInputTextTableViewCellDelegate <NSObject>

/*This table view cell is a delegate for its UITextField.
 But the view controller needs to handle this,
 so the cell passes it on.*/

@required
- (BOOL)textFieldShouldReturn:(UITextField *)textField;

@end


@interface VSInputTextTableViewCell : UITableViewCell


- (id)initWithLabelWidth:(CGFloat)labelWidth label:(NSString *)labelText placeholder:(NSString *)placeholder secure:(BOOL)secure delegate:(id<VSInputTextTableViewCellDelegate>)delegate;

@property (nonatomic, readonly) UITextField *textField;

- (void)updateShowHideButtonVisibility;

@end
