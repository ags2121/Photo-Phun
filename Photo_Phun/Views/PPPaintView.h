//
//  PPPaintView.h
//  Photo_Phun
//
//  Created by Alex Silva on 5/10/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPPaintView;

////////////////////////////////////////////////////////////////////////////////
@protocol PaintViewDelegate <NSObject>
@required
- (void)paintView:(PPPaintView*)paintView finishedTrackingPath:(CGPathRef)path inRect:(CGRect)painted;
@end

////////////////////////////////////////////////////////////////////////////////
@interface PPPaintView : UIView
@property (nonatomic, assign) id <PaintViewDelegate> delegate;
@property (strong, nonatomic) UIColor *lineColor;

- (void)erase;
@end