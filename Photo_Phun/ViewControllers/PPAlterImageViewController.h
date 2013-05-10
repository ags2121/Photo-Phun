//
//  PPAlterImageViewController.h
//  Photo_Phun
//
//  Created by Alex Silva on 5/7/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FlickrPhoto;

@interface PPAlterImageViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property(nonatomic, strong) FlickrPhoto *flickrPhoto;
@property (weak, nonatomic) IBOutlet UIImageView *largeImage;
@property (weak, nonatomic) IBOutlet UICollectionView *filterPreviewCollectionView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)cancelButtonPressed:(id)sender;

@end
