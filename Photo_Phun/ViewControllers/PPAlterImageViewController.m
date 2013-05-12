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
#import "PPSaveOptions.h"

static CGFloat kImageViewSize = 560.0;

@interface PPAlterImageViewController ()

@property (strong, nonatomic) NSArray *filterPreviewsInfo;
@property (strong, nonatomic) NSMutableDictionary *filters;
@property (strong, nonatomic) UINavigationBar *navBar;

@property (strong,nonatomic) CIContext *context;
@property (strong,nonatomic) CIFilter *filter;
@property (strong,nonatomic) CIImage *beginImage;

@property BOOL shouldMerge;
@property (strong, nonatomic) PPPaintView *paintView;
@property (strong, nonatomic) UIView *blackBottomFrame;

@property (strong, nonatomic) NSMutableAttributedString *onDrawString;
@property (strong, nonatomic) NSMutableAttributedString *offDrawString;
@property BOOL blinkStatus;

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
    
    [self.filterPreviewCollectionView setHidden:YES]; //hide filter options until image is loaded
    self.doneButton.enabled = NO; //disable done button until picture properly loads
    [self configureImageViewBorder:10.0];
    self.context = [CIContext contextWithOptions:nil];
    
    self.filterPreviewsInfo = [NSArray arrayWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"filterPreviewsTemplate" withExtension:@"plist"]];
    
    self.shouldMerge = YES; //for drawing functionality
}

//Choosing to freeze the filter controls until the high quality image loads
-(void)viewDidAppear:(BOOL)animated
{
    [self createBlackBottomFrame];
    
    if(self.flickrPhoto.largeImage) {

        self.largeImage.image = self.flickrPhoto.largeImage;
        [self.filterPreviewCollectionView setHidden:NO];
        self.doneButton.enabled = YES;
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;
    }
    else {
        
        self.largeImage.image = [self resizeImageToView:self.flickrPhoto.thumbnail];

        [PPDataFetcher loadImageForPhoto:self.flickrPhoto thumbnail:NO completionBlock:^(UIImage *photoImage, NSError *error) {
            if(!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.filterPreviewCollectionView setHidden:NO];
                    [self.filterPreviewCollectionView setNeedsDisplay];
                    
                    self.flickrPhoto.largeImage = [self resizeImageToView:photoImage];
                    self.largeImage.image = self.flickrPhoto.largeImage;
                    self.doneButton.enabled = YES;
                    [self.activityIndicator removeFromSuperview];
                    self.activityIndicator = nil;
                });
            }
            else{
                self.largeImage.image = [UIImage imageNamed:@"image_download_error"];
            }
        }];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createBlackBottomFrame
{
    CGFloat x = self.filterPreviewCollectionView.frame.origin.x;
    CGFloat y = self.filterPreviewCollectionView.frame.origin.y;
    CGFloat width = self.filterPreviewCollectionView.frame.size.width;
    CGFloat height = self.filterPreviewCollectionView.frame.size.height;
    
    CGRect collectionViewFrame = CGRectMake(x, y, width, height);
    self.blackBottomFrame = [[UIView alloc] initWithFrame:collectionViewFrame];
    self.blackBottomFrame.userInteractionEnabled = NO;
    self.blackBottomFrame.backgroundColor = [UIColor blackColor];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.center = CGPointMake(150.0, y+(height/2));
    
    [self.view addSubview:self.activityIndicator];
    [self.view sendSubviewToBack:self.activityIndicator];
    [self.view addSubview:self.blackBottomFrame];
    [self.view sendSubviewToBack:self.blackBottomFrame];
    
    [self.activityIndicator startAnimating];
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
    cell.filterName.text = filterName;
    cell.previewImage.image = [UIImage imageNamed:filterName];
    return cell;
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    PPFilterPreviewCell *cell = (PPFilterPreviewCell*)[collectionView cellForItemAtIndexPath:indexPath];
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

#pragma mark - Filter Methods

-(void)buildFilters
{
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

-(IBAction)cancelButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)doneButtonPressed:(id)sender {
    
    if([self.doneButton.title isEqualToString:@"Draw"]) {
        NSLog(@"done button pressed");
        self.navigationBar.title = @"Deface Photo";
        self.doneButton.title = @"Save";
        
        //remove filter options
        [UIView animateWithDuration:0.9 animations:^{
            self.filterPreviewCollectionView.alpha = 0.0;
            self.filterPreviewCollectionView.center = CGPointMake(160, 490);
        } completion:^(BOOL finished) {
            [self.filterPreviewCollectionView removeFromSuperview];
            self.filterPreviewCollectionView = nil;
        }];
        
        //show paintview
        self.paintView = [[PPPaintView alloc] initWithFrame:self.largeImage.bounds];
        self.paintView.lineColor = [UIColor grayColor];
        self.paintView.delegate = self;
        [self.largeImage addSubview:self.paintView];
        
        //allow touches on imageView
        self.largeImage.userInteractionEnabled = YES;
        
        //start blinking text
        [self buildAttributedStrings];
        NSTimer *blinkTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)1.0 target:self selector:@selector(blink:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer: blinkTimer forMode:NSRunLoopCommonModes];
        self.blinkStatus = YES;
        
    }
    else if([self.doneButton.title isEqualToString:@"Save"]){
        NSLog(@"save button pressed");
        self.navigationBar.title = @"Save Photo";
        self.doneButton.title = @"Done";
        
        [self.paintView removeFromSuperview];
        self.paintView = nil;
        
        [self.attributedStringLabel removeFromSuperview];
        self.attributedStringLabel = nil;
        
        PPSaveOptions *saveOptions = [[[NSBundle mainBundle] loadNibNamed:@"PPSaveOptions" owner:self options:nil] objectAtIndex:0];
        saveOptions.image = self.largeImage.image;
        saveOptions.center = CGPointMake(self.blackBottomFrame.center.x, self.blackBottomFrame.center.y+self.blackBottomFrame.frame.size.height);
        [self.view addSubview:saveOptions];
        
        [UIView animateWithDuration:0.9 animations:^{
            saveOptions.center = CGPointMake(self.blackBottomFrame.center.x, self.blackBottomFrame.center.y);
        }];
        
        //[self saveImageToPhotoLibrary:self.largeImage.image];
        //TODO: prompt user to ask if ok to save in photo directory
        //TODO: save photo to NSUserDefaults
        //TODO: figure out how you want to transition to a "share photo" prompt
    }
    //btn says "Done"
    else{
        //TODO: make search vc a delegate for this VC
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }

}

-(void)buildAttributedStrings
{
    self.onDrawString = [[NSMutableAttributedString alloc] initWithString:@"DRAW"];
    NSInteger _stringLength=[self.onDrawString length];
    
    UIColor *_red=[UIColor redColor];
    UIFont *font=[UIFont fontWithName:@"Helvetica-Bold" size:30.0f];

    //TODO: center the text    
    [self.onDrawString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, _stringLength)];
    [self.onDrawString addAttribute:NSStrokeColorAttributeName value:_red range:NSMakeRange(0, _stringLength)];
    [self.onDrawString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-3.0] range:NSMakeRange(0, _stringLength)];

    self.offDrawString = [[NSMutableAttributedString alloc] initWithString:@"DRAW"];
    UIColor *_green=[UIColor greenColor];
    [self.offDrawString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, _stringLength)];
    [self.offDrawString addAttribute:NSForegroundColorAttributeName value:_green range:NSMakeRange(0, _stringLength)];
    [self.offDrawString addAttribute:NSStrokeColorAttributeName value:_red range:NSMakeRange(0, _stringLength)];
    [self.offDrawString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-3.0] range:NSMakeRange(0, _stringLength)];
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

#pragma mark - Paint View Delegagte Protocol Methods
/*******************************************************************************
 * @method          paintView:
 * @abstract
 * @description
 *******************************************************************************/
- (void)paintView:(PPPaintView*)paintView finishedTrackingPath:(CGPathRef)path inRect:(CGRect)painted
{
    if (self.shouldMerge) {
        [self mergePaintToImageView:painted];
    }
}

/*******************************************************************************
 * @method          mergePaintTolargeImage
 * @abstract        Combine the last painted image into the current background image
 * @description
 *******************************************************************************/
- (void)mergePaintToImageView:(CGRect)painted
{
    // Create a new offscreen buffer that will be the UIImageView's image
    CGRect bounds = self.largeImage.bounds;
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, self.largeImage.contentScaleFactor);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Copy the previous background into that buffer.  Calling CALayer's renderInContext: will redraw the view if necessary
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    [self.largeImage.layer renderInContext:context];
    
    // Now copy the painted contect from the paint view into our background image
    // and clear the paint view.  as an optimization we set the clip area so that we only copy the area of paint view
    // that was actually painted
    CGContextClipToRect(context, painted);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    [self.paintView.layer renderInContext:context];
    [self.paintView erase];
    
    // Create UIImage from the context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    self.largeImage.image = image;
    UIGraphicsEndImageContext();
    
}

@end
