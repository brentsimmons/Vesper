//
//  VSTableViewDragController.h
//  Vesper
//
//  Created by Brent Simmons on 4/20/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VSTableViewDragController;


@protocol VSTableViewDragControllerDelegate <NSObject>

@required

- (UIImage *)dragController:(VSTableViewDragController *)dragController dragImageForRowAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)dragController:(VSTableViewDragController *)dragController dragShouldBeginForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)dragController:(VSTableViewDragController *)dragController dragDidBeginForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)dragController:(VSTableViewDragController *)dragController dragDidHoverOverRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)dragController:(VSTableViewDragController *)dragController dragDidCompleteAtIndexPath:(NSIndexPath *)indexPath;

- (void)draggingDidCancel:(VSTableViewDragController *)dragController;

- (void)dragControllerDidScroll:(VSTableViewDragController *)dragController;

@end



@interface VSTableViewDragController : NSObject <UIGestureRecognizerDelegate>


- (instancetype)initWithTableView:(UITableView *)tableView delegate:(id<VSTableViewDragControllerDelegate>)delegate;

@property (nonatomic, assign) BOOL enabled; /*Default is YES*/

@end
