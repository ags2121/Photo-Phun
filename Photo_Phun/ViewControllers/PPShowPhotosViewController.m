//
//  PPShowPhotosViewController.m
//  Photo_Phun
//
//  Created by Alex Silva on 5/7/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "PPAppDelegate.h"
#import "PPShowPhotosViewController.h"
#import "PPFilterPreviewCell.h"

@interface PPShowPhotosViewController ()

@property (strong, nonatomic) NSMutableDictionary *usersPhotos;
@property (strong, nonatomic) NSArray *largeImageData;
@property (strong, nonatomic) NSArray *usersThumbnails;
@property (strong, nonatomic) NSMutableAttributedString *onDrawString;
@property (strong, nonatomic) NSMutableAttributedString *offDrawString;
@property (strong, nonatomic) NSTimer *blinkTimer;
@property (strong, nonatomic) UIView *blackBottomFrame;
@property (strong, nonatomic) NSIndexPath *cellToDelete;
@property BOOL blinkStatus;
@property BOOL shouldReload;

@end

@implementation PPShowPhotosViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureImageViewBorder:10.0];
    [self loadPhotosFromDisk];
    [self addLongPressGestureForDeleting];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData:)
                                                 name:@"PhotoAdded"
                                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    if (self.usersThumbnails.count > 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Share" style: UIBarButtonItemStyleBordered target:self action:@selector(sharePhotoScreen:)];
    }
    else
        self.navigationItem.rightBarButtonItem = nil;
    
    if(self.shouldReload){
        [self loadPhotosFromDisk];
        [self.thumbnailView reloadData];
        self.shouldReload = NO;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

-(void)reloadData:(NSNotification*)notif
{
    self.shouldReload = YES;
}

-(void)configureImageViewBorder:(CGFloat)borderWidth
{
    CALayer* layer = [self.largeImage layer];
    [layer setBorderWidth:borderWidth];
    [layer setBorderColor:[UIColor whiteColor].CGColor];
    [layer setShadowOffset:CGSizeMake(-3.0, 3.0)];
    [layer setShadowRadius:3.0];
    [layer setShadowOpacity:1.0];
}

-(void)loadPhotosFromDisk
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray* photoData = [defaults arrayForKey:kSavedPhotos];
    
    if (photoData.count==0) {
        [self showNoSavedPhotosView];
    }
    else{
        NSMutableArray *temp = [NSMutableArray array];
        NSMutableArray *dataTemp = [NSMutableArray array];
        for(NSDictionary *photoDict in photoData){
            UIImage *image = [UIImage imageWithData: [photoDict objectForKey:kThumbnailImageKey]];
            [temp addObject:image];
            
            NSData *largeImageData =  [photoDict objectForKey:kImageKey];
            [dataTemp addObject:largeImageData];
        }
        self.usersThumbnails = [NSArray arrayWithArray:temp];
        self.largeImageData = [NSArray arrayWithArray:dataTemp];
        self.usersPhotos = [@{@0: [UIImage imageWithData:dataTemp[0]]} mutableCopy];
        self.largeImage.image = self.usersPhotos[@0];
        
        [self hideNoSavedPhotosView];
    }
}

-(void)addLongPressGestureForDeleting
{
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.delegate = self;
    [self.thumbnailView addGestureRecognizer:lpgr];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.thumbnailView];
    
    NSIndexPath *indexPath = [self.thumbnailView indexPathForItemAtPoint:p];
    if (indexPath == nil)
        NSLog(@"long press on collection view but not on a row");
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        NSLog(@"long press on collection view at row %d", indexPath.row);
        self.cellToDelete = indexPath;
        [self deletePhoto];
    }
}

-(void)showNoSavedPhotosView
{
    self.largeImage.image = [UIImage imageNamed:@"noSavedImages"];
    [self buildAttributedStrings];
    self.attributedStringLabel.hidden = NO;
    self.blinkTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)1.0 target:self selector:@selector(blink:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer: self.blinkTimer forMode:NSRunLoopCommonModes];
    self.blinkStatus = YES;
}

-(void)hideNoSavedPhotosView
{
    self.attributedStringLabel.hidden = YES;
    [self.blinkTimer invalidate];
}

-(void)blink:(NSTimer*)timer
{
    if(self.blinkStatus == NO){
        self.attributedStringLabel.attributedText = self.onDrawString;
        self.blinkStatus = YES;
    }else {
        self.attributedStringLabel.attributedText = self.offDrawString;
        self.blinkStatus = NO;
    }
}

-(void)buildAttributedStrings
{
    self.onDrawString = [[NSMutableAttributedString alloc] initWithString:@"NO IMAGES"];
    NSInteger _stringLength=[self.onDrawString length];
    
    UIColor *_red=[UIColor redColor];
    UIFont *font=[UIFont fontWithName:@"Helvetica-Bold" size:30.0f];
    
    //TODO: center the text
    [self.onDrawString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, _stringLength)];
    [self.onDrawString addAttribute:NSStrokeColorAttributeName value:_red range:NSMakeRange(0, _stringLength)];
    [self.onDrawString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-3.0] range:NSMakeRange(0, _stringLength)];
    
    self.offDrawString = [[NSMutableAttributedString alloc] initWithString:@"NO IMAGES"];
    UIColor *_green=[UIColor greenColor];
    [self.offDrawString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, _stringLength)];
    [self.offDrawString addAttribute:NSForegroundColorAttributeName value:_green range:NSMakeRange(0, _stringLength)];
    [self.offDrawString addAttribute:NSStrokeColorAttributeName value:_red range:NSMakeRange(0, _stringLength)];
    [self.offDrawString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-3.0] range:NSMakeRange(0, _stringLength)];
}

-(void)deletePhoto
{
    //TODO:
    UIAlertView *tmp = [[UIAlertView alloc]
                        initWithTitle:@"Are you sure you want to delete this photo?"
                        message:nil
                        delegate:self
                        cancelButtonTitle:@"No"
                        otherButtonTitles:@"Yes", nil];
    [tmp show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1){
        //update data store
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray* photoData = [[defaults arrayForKey:kSavedPhotos] mutableCopy];
        [photoData removeObjectAtIndex:self.cellToDelete.row];
        [defaults setObject:photoData forKey:kSavedPhotos];
        
        //update collection view data
        [self.usersPhotos removeObjectForKey:@(self.cellToDelete.row)];
        NSMutableArray *mutableThumbnails =  [self.usersThumbnails mutableCopy];
        [mutableThumbnails removeObjectAtIndex:self.cellToDelete.row];
        self.usersThumbnails = [NSArray arrayWithArray:mutableThumbnails];
        
        [self.thumbnailView deleteItemsAtIndexPaths:@[self.cellToDelete]];
        
        if ([self.usersThumbnails count]==0) {
            [self showNoSavedPhotosView];
        }
        else{

            if(self.usersPhotos[@0]){
                self.largeImage.image = self.usersPhotos[@0];
            }
            else{
                self.usersPhotos[@0] = [UIImage imageWithData: self.largeImageData[0]];
                self.largeImage.image = self.usersPhotos[@0];
            }
            
        }
        
        //[self.thumbnailView reloadData];
    }
}

-(void)sharePhotoScreen:(id)sender
{
    if( [self.thumbnailView indexPathsForSelectedItems].count != 0){
        
        UIActivityViewController* activityViewController =
        [[UIActivityViewController alloc] initWithActivityItems:@[@"My new artpiece, made using Dephace™",self.largeImage.image]
                                          applicationActivities:nil];
        [activityViewController setExcludedActivityTypes:@[UIActivityTypeMessage]];
        
        [self presentViewController:activityViewController animated:YES completion:^{}];
    }
    else{
        UIAlertView *tmp = [[UIAlertView alloc]
                           initWithTitle:@"No Photo Selected!"
                           message:@"Select a photo below to share."
                           delegate:self
                           cancelButtonTitle:@"OK"
                            otherButtonTitles:nil];
        [tmp show];
    }
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    
    return [self.usersThumbnails count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    PPFilterPreviewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PPFilterPreviewCell" forIndexPath:indexPath];
    
    if (cell.selected) {
        cell.layer.borderWidth = 3.0f;
        cell.layer.borderColor = [[UIColor magentaColor] CGColor]; // highlight selection
    }
    else
        cell.layer.borderWidth = 3.0f;
        cell.layer.borderColor = [[UIColor whiteColor] CGColor]; // Default
    
    cell.previewImage.image = self.usersThumbnails[indexPath.row];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PPFilterPreviewCell *cell = (PPFilterPreviewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    //give cell a border
    cell.layer.borderWidth = 3.0f;
    cell.layer.borderColor = [[UIColor magentaColor] CGColor];
    
    if(self.usersPhotos[@(indexPath.row)]){
        self.largeImage.image = self.usersPhotos[@(indexPath.row)];
    }
    else{
        self.usersPhotos[@(indexPath.row)] = [UIImage imageWithData: self.largeImageData[indexPath.row]];
        self.largeImage.image = self.usersPhotos[@(indexPath.row)];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PPFilterPreviewCell *cell = (PPFilterPreviewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    cell.layer.borderWidth = 3.0f;
    cell.layer.borderColor = [[UIColor whiteColor] CGColor];
}



@end
