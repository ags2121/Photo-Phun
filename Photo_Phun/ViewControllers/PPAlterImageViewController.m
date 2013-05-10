//
//  PPAlterImageViewController.m
//  Photo_Phun
//
//  Created by Alex Silva on 5/7/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "PPAlterImageViewController.h"
#import "FlickrPhoto.h"
#import "PPDataFetcher.h"
#import "PPFilterPreviewCell.h"

static CGFloat kImageViewSize = 560.0;

@interface PPAlterImageViewController ()

@property (strong, nonatomic) NSArray *filterPreviewsInfo;
@property (strong, nonatomic) NSMutableDictionary *filters;
@property (strong, nonatomic) UINavigationBar *navBar;

@property (strong,nonatomic) CIContext *context;
@property (strong,nonatomic) CIFilter *filter;
@property (strong,nonatomic) CIImage *beginImage;

@property (strong, nonatomic) NSIndexPath *selectedCellIndexPath;

@end

@implementation PPAlterImageViewController


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
    //disable filter options until image is loaded
    [self.filterPreviewCollectionView setHidden:YES];
    [self configureImageViewBorder:10.0];
    [self configureNavBarAndButton];
    [self.activityIndicator startAnimating];
    self.context = [CIContext contextWithOptions:nil];
    
    self.filterPreviewsInfo = [NSArray arrayWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"filterPreviewsTemplate" withExtension:@"plist"]];
}

//Choosing to freeze the filter controls until the high quality image loads
-(void)viewDidAppear:(BOOL)animated
{
    if(self.flickrPhoto.largeImage) {

        self.largeImage.image = self.flickrPhoto.largeImage;
        [self.activityIndicator stopAnimating];
        [self.filterPreviewCollectionView setHidden:NO];
    }
    else {
        
        self.largeImage.image = [self resizeImageToView:self.flickrPhoto.thumbnail];

        [PPDataFetcher loadImageForPhoto:self.flickrPhoto thumbnail:NO completionBlock:^(UIImage *photoImage, NSError *error) {
            if(!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.activityIndicator stopAnimating];
                    [self.filterPreviewCollectionView setHidden:NO];
                    self.flickrPhoto.largeImage = [self resizeImageToView:photoImage];
                    self.largeImage.image = self.flickrPhoto.largeImage;
                    [self.filterPreviewCollectionView setNeedsDisplay];
                });
            }
            else self.largeImage.image = [UIImage imageNamed:@"image_download_error"];
            [self.activityIndicator stopAnimating];
        }];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Image Manipulation methods

-(UIImage*)resizeImageToView:(UIImage*)image
{

    NSArray *faceFeatures = [PPAlterImageViewController detectFace:image];
    if (faceFeatures.count > 0){
        CIFaceFeature *face = faceFeatures[0];
        CGPoint centerOfFace = face.mouthPosition;
        NSLog(@"Center of face %@", NSStringFromCGPoint(centerOfFace));
        NSLog(@"image dimensions %@", NSStringFromCGSize( image.size ));
        
        CGRect newRect;
        if (centerOfFace.x < centerOfFace.y) {

            if(centerOfFace.y >= image.size.width)
                newRect = CGRectMake(0, image.size.height/2, MIN(image.size.height/2, image.size.width), MIN(image.size.height/2, image.size.width));
            else
                newRect = CGRectMake(0, 0, MIN(image.size.height, image.size.width), MIN(image.size.height, image.size.width));
            
            return [PPAlterImageViewController imageByCropping:image toFrame:newRect];
        }

        else if (centerOfFace.y < centerOfFace.x) {

            if(centerOfFace.x >= image.size.height)
                newRect = CGRectMake(image.size.width/2, 0, MIN(image.size.height, image.size.width/2), MIN(image.size.height, image.size.width/2));
            else
                newRect = CGRectMake(0, 0, MIN(image.size.height, image.size.width), MIN(image.size.height, image.size.width));
            return [PPAlterImageViewController imageByCropping:image toFrame:newRect];
        }

        else if (image.size.height != image.size.width) { //and centerOfFace.y == centerOfFace.x
            CGFloat side = MIN(image.size.height, image.size.width);
            return [PPAlterImageViewController imageByCropping:image toFrame:CGRectMake(0.0, 0.0, side, side)];
        }
    }
    //else if no face detection
    return [PPAlterImageViewController cropBiggestCenteredSquareImageFromImage: image withSide:kImageViewSize];
}


+(NSArray*)detectFace:(UIImage*)image
{
    NSDictionary *detectorOptions = [NSDictionary dictionaryWithObject:CIDetectorAccuracyLow
                                                                forKey:CIDetectorAccuracy];
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    return [detector featuresInImage:ciImage];
}

+(UIImage *)imageByCropping:(UIImage *)image toFrame:(CGRect)newRect
{
    NSLog(@"New rect: %@", NSStringFromCGRect(newRect));
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], newRect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    
    NSLog(@"dimensions after first crop: %@", NSStringFromCGSize(cropped.size));
    
    if (cropped.size.width > kImageViewSize){
        cropped = [UIImage imageWithCGImage:cropped.CGImage scale:(cropped.size.width/kImageViewSize) orientation:cropped.imageOrientation];
        NSLog(@"dimensions after second crop: %@", NSStringFromCGSize(cropped.size));
    }
    
    CGImageRelease(imageRef);

    return cropped;
}

+(UIImage*) cropBiggestCenteredSquareImageFromImage:(UIImage*)image withSide:(CGFloat)side
{
    // Get size of current image
    CGSize size = [image size];
    if( size.width == size.height && size.width == side){
        return image;
    }
    
    CGSize newSize = CGSizeMake(side, side);
    double ratio;
    double delta;
    CGPoint offset;
    
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.height / image.size.height;
        delta = ratio*(image.size.width - image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.width;
        delta = ratio*(image.size.height - image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width),
                                 (ratio * image.size.height));
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    
    return [self.filterPreviewsInfo count];
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
    
    NSString *filterName = self.filterPreviewsInfo[indexPath.row];
    NSLog(@"name: %@", filterName);
    cell.filterName.text = filterName;
    cell.previewImage.image = [UIImage imageNamed:filterName];
    return cell;
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    PPFilterPreviewCell *cell = (PPFilterPreviewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    self.selectedCellIndexPath = indexPath;
    NSLog(@"indexpath %@", indexPath);
    //give cell a border
    cell.layer.borderWidth = 3.0f;
    cell.layer.borderColor = [[UIColor magentaColor] CGColor];
    
    //lazy building of filters; we wait until user first taps cell
    if(!self.beginImage){
        [self buildFilters];
    }
    
    if(indexPath.row == 0)
       [self resetImage];
    else{
        NSString *filterName = self.filterPreviewsInfo[indexPath.row];
        CIFilter *filterToApply = self.filters[filterName];
        [self applyFilterToImage:filterToApply];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PPFilterPreviewCell *cell = (PPFilterPreviewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    cell.layer.borderWidth = 0.0;    
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}


#pragma mark - Filter Methods

-(void)buildFilters
{
    [self.activityIndicator stopAnimating];
    //MAKE SURE FILTER NAMES MATCH THE NAMES IN THE PLIST TEMPLATE
    
    self.beginImage = [[CIImage alloc] initWithImage:self.largeImage.image];
    
    self.filters = [@{} mutableCopy];
    
    //sepia
    CIFilter *sepiaFilter = [CIFilter filterWithName:@"CISepiaTone"
               keysAndValues:kCIInputImageKey, self.beginImage, @"inputIntensity",
     @0.8, nil];
    [self.filters setObject:sepiaFilter forKey:@"Sepia"];
    
    //brighten
    CIFilter *brightnesContrastFilter = [CIFilter filterWithName:@"CIColorControls"
                                       keysAndValues:kCIInputImageKey, self.beginImage, @"inputBrightness", @0.5, @"inputContrast", @2.0, nil];
    [self.filters setObject:brightnesContrastFilter forKey:@"Brighten"];
    
    //invert
    CIFilter *invertFilter = [CIFilter filterWithName:@"CIColorInvert"];
    [invertFilter setDefaults];
    [invertFilter setValue: self.beginImage forKey: kCIInputImageKey];
    [self.filters setObject:invertFilter forKey:@"Invert"];
    
    //hue
    CIFilter *hueFilter = [CIFilter filterWithName:@"CIHueAdjust"];
    [hueFilter setDefaults];
    [hueFilter setValue: self.beginImage forKey: kCIInputImageKey];
    [hueFilter setValue: [NSNumber numberWithFloat: 3.0f] forKey: @"inputAngle"];
    [self.filters setObject:hueFilter forKey:@"Hue"];
    
    
    //blur
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:kCIInputImageKey, self.beginImage, @"inputRadius", @10.0, nil];
    
    CIVector *point0 =[CIVector vectorWithX:0.0 Y:(0.75 * 4.0)];
    CIVector *point1 =[CIVector vectorWithX:0.0 Y:(0.5*4.0)];
    CIColor *color0 = [CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    CIColor *color1 = [CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.0];
    CIFilter *gradient1 = [CIFilter filterWithName:@"CILinearGradient" keysAndValues:@"inputPoint0", point0, @"inputColor0", color0, @"inputPoint1", point1, @"inputColor1", color1, nil];
    
    point0 =[CIVector vectorWithX:0.0 Y:(0.25 * 4.0)];
    CIFilter *gradient2 = [CIFilter filterWithName:@"CILinearGradient" keysAndValues:@"inputPoint0", point0, @"inputColor0", color0, @"inputPoint1", point1, @"inputColor1", color1, nil];
    
    CIFilter *mask = [CIFilter filterWithName:@"CIAdditionCompositing" keysAndValues:kCIInputImageKey, gradient1.outputImage, kCIInputBackgroundImageKey, gradient2.outputImage, nil];
    
    CIFilter *blendMask = [CIFilter filterWithName:@"CIBlendWithMask" keysAndValues:kCIInputImageKey, blurFilter.outputImage, kCIInputBackgroundImageKey, self.beginImage, @"inputMaskImage", mask.outputImage, nil];
    [self.filters setObject:blendMask forKey:@"Blur"];
    
    //shadow
    CIFilter *highlightShadowAdjustFilter = [CIFilter filterWithName:@"CIHighlightShadowAdjust"];
    [highlightShadowAdjustFilter setDefaults];
    [highlightShadowAdjustFilter setValue: self.beginImage forKey: kCIInputImageKey];
    [highlightShadowAdjustFilter setValue: @1.0 forKey:@"inputHighlightAmount"];
    [highlightShadowAdjustFilter setValue:@8.5 forKey:@"inputShadowAmount"];
    [self.filters setObject:highlightShadowAdjustFilter forKey:@"Lighten"];
    
    //bump
    CIFilter *bumpDistortion = [CIFilter filterWithName:@"CIBumpDistortion"];
    [bumpDistortion setValue:self.beginImage forKey:kCIInputImageKey];
    [bumpDistortion setValue:[CIVector vectorWithX:kImageViewSize/2 Y:kImageViewSize/2] forKey:@"inputCenter"];
    [bumpDistortion setValue:[NSNumber numberWithFloat:kImageViewSize/2] forKey:@"inputRadius"];
    [bumpDistortion setValue:[NSNumber numberWithFloat:0.5] forKey:@"inputScale"];
    [self.filters setObject:bumpDistortion forKey:@"Bump"];
    
}

-(void)applyFilterToImage:(CIFilter*)filter
{
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgimg = [self.context createCGImage:outputImage fromRect:[outputImage extent]];
    UIImage *newImage = [UIImage imageWithCGImage:cgimg];
    self.largeImage.image = newImage;
    
    CGImageRelease(cgimg);
}

-(void)resetImage
{
    self.largeImage.image = self.flickrPhoto.largeImage;
}

#pragma mark - View Set Up Methods

-(void)configureImageViewBorder:(CGFloat)borderWidth
{
    CALayer* layer = [self.largeImage layer];
    [layer setBorderWidth:borderWidth];
    [layer setBorderColor:[UIColor whiteColor].CGColor];
    [layer setShadowOffset:CGSizeMake(-3.0, 3.0)];
    [layer setShadowRadius:3.0];
    [layer setShadowOpacity:1.0];
}

-(void)configureNavBarAndButton
{
    _navBar = [[UINavigationBar alloc] init];
    [_navBar setFrame:CGRectMake(0,0,self.view.bounds.size.width,52)];
    [self.view addSubview:_navBar];
    UINavigationItem *navItem = [[UINavigationItem alloc]initWithTitle:@"Edit Photo"];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.userInteractionEnabled = YES;
    [cancelButton setBackgroundImage:[UIImage imageNamed:@"bar_button"] forState:UIControlStateNormal];
//    [cancelButton setBackgroundImage:[UIImage imageNamed:@"bar_button_selected"] forState:UIControlStateSelected | UIControlStateHighlighted];
    [cancelButton setShowsTouchWhenHighlighted:YES];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton.layer setCornerRadius:4.0f];
    [cancelButton.layer setMasksToBounds:YES];
    [cancelButton.layer setBorderWidth:1.0f];
    [cancelButton.layer setBorderColor: [[UIColor grayColor] CGColor]];
    cancelButton.frame = CGRectMake(0.0, 100.0, 60.0, 30.0);
    [cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    [navItem setLeftBarButtonItem:cancelBtn];
    [_navBar setItems:@[navItem]];
}

@end
