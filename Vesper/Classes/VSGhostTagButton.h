//
//  VSGhostTagButton.h
//  Vesper
//
//  Created by Brent Simmons on 4/10/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VSEditableTagView.h"


/*On tap, sends ghostTagButtonTapped:(id)sender via responder chain.*/

@interface VSGhostTagButton : UIButton <VSEditableTagView>

+ (instancetype)button;

@end
