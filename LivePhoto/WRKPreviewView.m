//
//  WRKPreviewView.m
//  WeRenderKit
//
//  Created by kintan on 2017/6/5.
//  Copyright © 2017年 Wecut. All rights reserved.
//

#import "WRKPreviewView.h"

@interface WRKPreviewView ()
{
    CIImage *_displayImage;
}

@property (nonatomic, strong) CIContext *ciContext;

@end

@implementation WRKPreviewView

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context
{
    self = [super initWithFrame:frame context:context];
    if (self) {
        
        self.ciContext = [CIContext contextWithEAGLContext:self.context];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [self setNeedsDisplay];
}

- (void)renderWithTexture:(unsigned int)name
                     size:(CGSize)size
                  flipped:(BOOL)flipped
               colorSpace:(CGColorSpaceRef)colorSpace
      applyingOrientation:(int)orientation
{
    CIImage *image = [CIImage imageWithTexture:name size:size flipped:flipped colorSpace:colorSpace];
    if (colorSpace) {
        CGColorSpaceRelease(colorSpace);
    }
    
    image = [image imageByApplyingOrientation:orientation];
    if (image) {
        [self renderWithCImage:image];
    } else{
        NSLog(@"create image with texture failed.");
    }
}

- (void)renderWithCImage:(CIImage *)image
{
    _displayImage = image;
    [self setNeedsDisplay];
}

- (void)renderWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    if (image) {
        [self renderWithCImage:image];
    }
}

- (UIImage *)displayedImage
{
    if (_displayImage) {
        UIImage *uiImage = [[UIImage alloc] initWithCIImage:_displayImage];
        return uiImage;
    }
    
    return nil;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if (_displayImage) {
        
        CGAffineTransform scale = CGAffineTransformMakeScale(self.contentScaleFactor,
                                                             self.contentScaleFactor);
        CGRect rectDraw = CGRectApplyAffineTransform(self.bounds, scale);
        
        CGRect imageRect = [_displayImage extent];
        CGFloat ratio = rectDraw.size.width/rectDraw.size.height;
        
        CGFloat x = 0;
        CGFloat y = 0;
        CGFloat expectWidth = imageRect.size.width;
        CGFloat expectHeight = expectWidth/ratio;
        if (expectHeight > imageRect.size.height) {
            expectHeight = imageRect.size.height;
            expectWidth = expectHeight*ratio;
            
            y = 0;
            x = (imageRect.size.width - expectWidth)*0.5;
        } else {
            
            x = 0;
            y = (imageRect.size.height - expectHeight)*0.5;
        }
        
        imageRect.origin.x = x;
        imageRect.origin.y = y;
        imageRect.size.width = expectWidth;
        imageRect.size.height = expectHeight;
        
        [self.ciContext drawImage:_displayImage inRect:rectDraw fromRect:imageRect];
        
        glFlush();
    }
}

@end
