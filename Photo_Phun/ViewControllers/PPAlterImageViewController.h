//
//  PPAlterImageViewController.h
//  Photo_Phun
//
//  Created by Alex Silva on 5/7/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPPaintView.h"

@class FlickrPhoto;

@interface PPAlterImageViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, PaintViewDelegate>

- (void)paintView:(PPPaintView*)paintView finishedTrackingPath:(CGPathRef)path inRect:(CGRect)painted;

@property(nonatomic, strong) FlickrPhoto *flickrPhoto;
@property (weak, nonatomic) IBOutlet UIImageView *largeImage;
@property (weak, nonatomic) IBOutlet UICollectionView *filterPreviewCollectionView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBar;
@property (weak, nonatomic) IBOutlet UILabel *attributedStringLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)doneButtonPressed:(id)sender;

@end
