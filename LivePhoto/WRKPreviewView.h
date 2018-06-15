//
//  WRKPreviewView.h
//  WeRenderKit
//
//  Created by kintan on 2017/6/5.
//  Copyright © 2017年 Wecut. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <CoreImage/CoreImage.h>

@interface WRKPreviewView : GLKView

- (void)renderWithTexture:(unsigned int)name
                     size:(CGSize)size
                  flipped:(BOOL)flipped
               colorSpace:(CGColorSpaceRef)colorSpace
      applyingOrientation:(int)orientation;

- (void)renderWithCImage:(CIImage *)image;
- (void)renderWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (UIImage *)displayedImage;

@end
