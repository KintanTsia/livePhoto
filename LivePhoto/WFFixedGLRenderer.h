//
//  WFFixedGLRenderer.h
//  WecutFace
//
//  Created by kintan on 2017/8/2.
//  Copyright © 2017年 Wecut. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM( NSInteger, CompositingType ) {
    CompositingTypeOverlay = 1,
    CompositingTypeSlideShow
};

typedef NS_ENUM( NSInteger, SlideShowType ) {
    SlideShowTypeUnspecify = 0,
    SlideShowTypeZoom,
    SlideShowTypeWave,
    SlideShowTypeAbberation
};

@interface WFFixedGLRenderer : NSObject

- (instancetype)initWithContext:(EAGLContext *)context;


#pragma mark - Preparing
- (void)preparePhotoCGImage:(CGImageRef)cgImage;

#pragma mark - Rendering

- (CVPixelBufferRef)renderCompositingCGImage:(CGImageRef)image
                             compositingType:(CompositingType)compositingType
                               slideShowType:(SlideShowType)slideShowType
                                        time:(float)time;

@end
