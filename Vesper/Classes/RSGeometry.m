//
//  RSGeometry.m
//  Vesper
//
//  Created by Brent Simmons on 12/4/12.
//  Copyright (c) 2012 Ranchero Software. All rights reserved.
//

#import "RSGeometry.h"


CGRect CGRectCenteredHorizontallyInRect(CGRect rectToCenter, CGRect containingRect) {

	rectToCenter.origin.x = QSFloor(CGRectGetMidX(containingRect)) - QSFloor(rectToCenter.size.width / 2);
	return rectToCenter;
}


CGRect CGRectCenteredVerticallyInRect(CGRect rectToCenter, CGRect containingRect) {

 	rectToCenter.origin.y = QSFloor(CGRectGetMidY(containingRect)) - QSFloor(rectToCenter.size.height / 2);
	return rectToCenter;
}


CGRect CGRectCenteredInRect(CGRect rectToCenter, CGRect containingRect) {

	rectToCenter = CGRectCenteredHorizontallyInRect(rectToCenter, containingRect);
	return CGRectCenteredVerticallyInRect(rectToCenter, containingRect);
}

