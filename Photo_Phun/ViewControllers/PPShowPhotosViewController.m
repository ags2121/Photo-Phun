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
@property BOOL blinkStatus;
@property (strong, nonatomic) NSMutableAttributedString *onDrawString;
@property (strong, nonatomic) NSMutableAttributedString *offDrawString;
@property (strong, nonatomic) NSTimer *blinkTimer;
@property (strong, nonatomic) UIView *blackBottomFrame;

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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

-(void)reloadData:(NSNotification*)notif
{
    [self loadPhotosFromDisk];
    [self.thumbnailView reloadData];
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
        
        [self.blinkTimer invalidate];
    }
}

-(void)addLongPressGestureForDeleting
{
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 2.0; //seconds
    lpgr.delegate = self;
    [self.thumbnailView addGestureRecognizer:lpgr];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.thumbnailView];
    
    NSIndexPath *indexPath = [self.thumbnailView indexPathForItemAtPoint:p];
    if (indexPath == nil)
        NSLog(@"long press on collection view but not on a row");
    else{
        NSLog(@"long press on collection view at row %d", indexPath.row);
        [self deletePhoto];
    }
}

-(void)showNoSavedPhotosView
{
    self.largeImage.image = [UIImage imageNamed:@"noSavedImages"];
    [self buildAttributedStrings];
    
    self.blinkTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)1.0 target:self selector:@selector(blink:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer: self.blinkTimer forMode:NSRunLoopCommonModes];
    self.blinkStatus = YES;
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
        cell.layer.borderWidth = 0.0f; // Default
    
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
    cell.layer.borderWidth = 0.0;
}



@end
