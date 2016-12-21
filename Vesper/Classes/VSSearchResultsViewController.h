//
//  VSSearchResultsViewController.h
//  Vesper
//
//  Created by Brent Simmons on 3/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSBaseViewController.h"


@class VSTimelineViewController;
@class VSNote;
@class VSTag;
@class VSTimelineContext;


@interface VSSearchResultsViewController : VSBaseViewController <UITableViewDataSource, UITableViewDelegate>


- (instancetype)initWithContext:(VSTimelineContext *)context includeArchivedNotes:(BOOL)includeArchivedNotes archivedNotesOnly:(BOOL)archivedNotesOnly timelineViewController:(VSTimelineViewController *)timelineViewController;

@property (nonatomic, strong) NSString *searchString; /*Setting searchString causes it to run the search.*/
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong) VSTimelineNote *draggedNote;

- (void)detailViewDone:(id)sender;
- (void)detailViewDoneViaPanBackAnimation:(id)sender;

/*Pan-back animation support.*/

- (UIImage *)dragImageForNote:(VSNote *)note;
- (CGRect)frameOfCellForNote:(VSNote *)note;
- (void)prepareForPanBackAnimationWithNote:(VSNote *)note;
- (UIView *)tableAnimationView;

@end
