//
//  PPPaintView.m
//  Photo_Phun
//
//  Created by Alex Silva on 5/10/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "PPPaintView.h"

#import <QuartzCore/QuartzCore.h>

#define BEZIER_TYPE 1

@interface PPPaintView ()

@property CGMutablePathRef trackingPath;

@property (strong, nonatomic) NSMutableArray *strokes;
@property (strong, nonatomic) UIBezierPath *path;

@property CGRect trackingDirty;
@property CGSize shadowSize;
@property CGFloat shadowBlur;
@property CGFloat lineWidth;

@property (strong, nonatomic) NSMutableArray *previousPaths;
@property (strong, nonatomic) NSMutableArray *previousColors;
@end

////////////////////////////////////////////////////////////////////////////////
@implementation PPPaintView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupDefaultPaintStyles];
        self.backgroundColor = [UIColor clearColor];
        _strokes = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    return self;
}

- (void)setupDefaultPaintStyles
{
    self.lineWidth = 20;
    self.lineColor = [UIColor greenColor];
    self.shadowSize = (CGSize) {10,10},
    self.shadowBlur = 5;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    if (_trackingPath == NULL) {
        _trackingPath = CGPathCreateMutable();
    }
    CGPoint point = [[touches anyObject] locationInView:self];
    CGPathMoveToPoint(_trackingPath, NULL, point.x, point.y);
    
    
    ////////////////////////////////////////////////////////////////////////////
    // BezierPath
    UITouch *touch = [touches anyObject];
    
    self.path = [UIBezierPath bezierPath];
	self.path.lineWidth = 10;
    self.path.lineCapStyle = kCGLineCapRound;
    self.path.lineJoinStyle = kCGLineJoinRound;
	[self.path moveToPoint:[touch locationInView:self]];
    
    // Create the arrays to hold the values
    [self.strokes addObject:self.path];
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    // Add the new path to the point
    CGPoint prevPoint = CGPathGetCurrentPoint(_trackingPath);
    CGPoint point = [[touches anyObject] locationInView:self];
    CGPathAddLineToPoint(_trackingPath, NULL, point.x, point.y);
    
    CGRect dirty = [self segmentBoundsFrom:prevPoint to:point];
    
    // Keep track of the cumulative "dirty" rectangle
    _trackingDirty = CGRectUnion(dirty, _trackingDirty);
    
    UITouch *touch = [touches anyObject];
    [[self.strokes lastObject] addLineToPoint:[touch locationInView:self]];
    [self setNeedsDisplayInRect:dirty];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    [_previousPaths addObject:(__bridge id)_trackingPath];
    [_previousColors addObject:self.lineColor];
    CGPathRelease(_trackingPath);
    _trackingPath = NULL;
    
    [self.delegate paintView:self finishedTrackingPath:_trackingPath inRect:_trackingDirty];
    
	UITouch *touch = [touches anyObject];
    // Update the last one
    [[self.strokes lastObject] addLineToPoint:[touch locationInView:self]];
    [self setNeedsDisplay];
    //[self setNeedsDisplayInRect:CGRectUnion(self.firstTouch,self.lastTouch)];
    
    [self.delegate paintView:self finishedTrackingPath:_trackingPath inRect:_trackingDirty];
}


- (void)drawRect:(CGRect)rect
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    /*
     CGContextRef context = UIGraphicsGetCurrentContext();
     CGContextSaveGState(context);
     NSLog(@"rect:%f %f",rect.size.width,rect.size.height);
     
     [_previousPaths enumerateObjectsUsingBlock:^(id obj,NSUInteger idx, BOOL *stop) {
     [self setPaintStyleInContext:context withColor:[_previousColors objectAtIndex:idx]];
     CGContextAddPath(context, (__bridge CGPathRef)obj);
     CGContextDrawPath(context, kCGPathStroke);
     }];
     
     if (_trackingPath) {
     [self setPaintStyleInContext:context withColor:self.lineColor];
     CGContextAddPath(context, _trackingPath);
     CGContextDrawPath(context, kCGPathStroke);
     }
     
     CGContextRestoreGState(context);
     
     */
    
    //
    for (int i=0; i < [self.strokes count]; i++) {
        //for (UIBezierPath *tmp in self.strokes)
        UIBezierPath *tmp = (UIBezierPath*)[self.strokes objectAtIndex:i];
        [[UIColor redColor] set];
        [tmp stroke];
    }
    NSLog(@"%2.2fms", 1000.0*(CFAbsoluteTimeGetCurrent() - startTime));
    
}


/*******************************************************************************
 * @method          <# method #>
 * @abstract        <# abstract #>
 * @description     <# description #>
 *******************************************************************************/
- (void)setPaintStyleInContext:(CGContextRef)context withColor:(UIColor*)color
{
    
    //CGContextSetShadowWithColor(context, self.shadowSize, self.shadowBlur, [color CGColor]);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, self.lineWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    //}
}

- (void)erase {
    //[self imageRepresentation];
    [_previousPaths removeAllObjects];
    [_previousColors removeAllObjects];
    
    if (_trackingPath) {
        CGPathRelease(_trackingPath);
        _trackingPath = NULL;
        _trackingDirty = CGRectNull;
    }
    //[self setNeedsDisplay];
    
    // Bezier Path
    // Remove all the strokes and clear the arrays
    [self.path removeAllPoints];
    [self.strokes removeAllObjects];
    
    [self setNeedsDisplay];
}

- (CGRect)segmentBoundsFrom:(CGPoint)point1 to:(CGPoint)point2
{
    CGRect dirtyPoint1 = CGRectMake(point1.x-10, point1.y-10, 20, 20);
    CGRect dirtyPoint2 = CGRectMake(point2.x-10, point2.y-10, 20, 20);
    return CGRectUnion(dirtyPoint1, dirtyPoint2);
}

/*******************************************************************************
 * @method      imageRepresentation
 * @abstract    Take a screenshot
 * @description
 *******************************************************************************/
/*- (UIImage *)imageRepresentation:(NSString*)theFilePath transparent:(BOOL)makeTranparent saveToLibrary:(BOOL)saveToLibrary
 {
 
 //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 
 //background processing goes here
 NSError *error;
 UIView *original = [[UIView alloc] init];
 if (makeTranparent) {
 original.backgroundColor = self.backgroundColor;
 original.layer.shadowOpacity = self.layer.shadowOpacity;
 self.backgroundColor = [UIColor clearColor];
 self.layer.shadowOpacity = 0;
 }
 
 if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
 UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
 else
 UIGraphicsBeginImageContext(self.bounds.size);
 
 [self.layer renderInContext:UIGraphicsGetCurrentContext()];
 UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
 UIGraphicsEndImageContext();
 NSData *data = UIImagePNGRepresentation(image);
 
 // if save to album
 if (saveToLibrary)
 UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:data], nil, nil, nil);
 
 if (theFilePath != nil) {
 //fileName = [NSString stringWithFormat:@"%@_%@.png",[self class],[NSNumber numberWithBool:makeTranparent]];
 [data writeToFile:theFilePath options:NSDataWritingAtomic error:&error];
 if (error)
 DLog(@">>>>>>>>>>>>>>>>>>>>\n ERROR: %@", [error localizedDescription]);
 }
 
 //
 if (makeTranparent) {
 self.backgroundColor = original.backgroundColor;
 self.layer.shadowOpacity =  original.layer.shadowOpacity;
 }
 
 
 dispatch_async(dispatch_get_main_queue(), ^{
 NSLog(@"\n>>>>> Done saving in background...");//update UI here
 });
 });
 
 return nil;//image;
 }
 */

@end
