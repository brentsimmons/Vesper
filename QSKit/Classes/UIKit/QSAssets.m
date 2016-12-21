//
//  QSAssets.m
//  Q Branch Standard Kit
//
//  Created by Brent Simmons on 10/31/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "QSAssets.h"


static UIImage *mostRecentPhotoInAssetsGroup(ALAssetsGroup *group);


void QSAssetsMostRecentPhoto(QSImageResultBlock imageResultBlock) {

	ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];

	[assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

		UIImage *image = mostRecentPhotoInAssetsGroup(group);
		if (image != nil) {
			*stop = YES;

			dispatch_async(dispatch_get_main_queue(), ^{
				imageResultBlock(image);
			});
		}

	} failureBlock:^(NSError *error) {
		NSLog(@"QSMostRecentPhoto error: %@", error);
	}];
}


static UIImage *mostRecentPhotoInAssetsGroup(ALAssetsGroup *group) {

	if (group == nil) {
		return nil;
	}

	[group setAssetsFilter:[ALAssetsFilter allPhotos]];

	__block UIImage *image = nil;

	[group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {

		if (asset != nil) {

			ALAssetRepresentation *representation = [asset defaultRepresentation];
			image = [UIImage imageWithCGImage:[representation fullScreenImage]];
			if (image != nil) {
				*stop = YES;
			}
		}
	}];

	return image;
}


static void addAssetURLToGroup(ALAssetsLibrary *assetsLibrary, NSURL *assetURL, ALAssetsGroup *group, ALAssetsLibraryAccessFailureBlock completionBlock) {

	[assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {

		[group addAsset:asset];
		completionBlock(nil);

	} failureBlock:completionBlock];
}


void QSSaveImageToAlbum(UIImage *image, NSString *albumName, ALAssetsLibraryAccessFailureBlock completionBlock) {

	ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];

	[assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {

		if (error) {
			completionBlock(error);
			return;
		}

		__block BOOL didAddToGroup = NO;

		[assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

			if (didAddToGroup) {
				return;
			}

			if ([albumName isEqualToString:[group valueForProperty:ALAssetsGroupPropertyName]]) {

				*stop = YES;
				addAssetURLToGroup(assetsLibrary, assetURL, group, completionBlock);
				didAddToGroup = YES;
				}

			else if (!group) {

				*stop = YES;
				didAddToGroup = YES;

				__weak ALAssetsLibrary *weakAssetsLibrary = assetsLibrary;

				[assetsLibrary addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *createdGroup) {

					addAssetURLToGroup(weakAssetsLibrary, assetURL, createdGroup, completionBlock);

				} failureBlock:completionBlock];
			}

		} failureBlock:^(NSError *error2) {

			completionBlock(error2);
		}];
	}];
}

