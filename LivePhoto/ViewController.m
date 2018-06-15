//
//  ViewController.m
//  LivePhoto
//
//  Created by kintan on 11/01/2018.
//  Copyright © 2018 Wecut. All rights reserved.
//

#import "ViewController.h"
#import "WRKPreviewView.h"
#import "WFFixedGLRenderer.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    double _startTime;
    
    CompositingType _compositingType;
    SlideShowType _slideShowType;
    
    NSInteger _overlayTextureAssetIndex;
}

@property (nonatomic, strong) WRKPreviewView *previewView;
@property (nonatomic, strong) WFFixedGLRenderer *renderer;

@property (nonatomic, strong) CADisplayLink *timer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _compositingType = CompositingTypeSlideShow;
    _slideShowType = SlideShowTypeZoom;
    
    _overlayTextureAssetIndex = 0;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.renderer = [[WFFixedGLRenderer alloc] initWithContext:glContext];
    
    self.previewView = [[WRKPreviewView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)
                                                     context:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    self.previewView.center = CGPointMake(self.view.frame.size.width*0.5, self.view.frame.size.height*0.5);
    [self.view addSubview:self.previewView];
    
    UIButton *loadPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    loadPhotoButton.frame = CGRectMake(20, 20, 84, 44);
    [loadPhotoButton setTitle:@"选图片" forState:UIControlStateNormal];
    [loadPhotoButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [loadPhotoButton addTarget:self action:@selector(photoLibAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loadPhotoButton];
    
    UIButton *overlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    overlayButton.frame = CGRectMake(104, 20, 84, 44);
    [overlayButton setTitle:@"叠加效果" forState:UIControlStateNormal];
    [overlayButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [overlayButton addTarget:self action:@selector(overlayAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:overlayButton];
    
    UIButton *simpleTransformButton = [UIButton buttonWithType:UIButtonTypeCustom];
    simpleTransformButton.frame = CGRectMake(188, 20, 84, 44);
    [simpleTransformButton setTitle:@"简单变换" forState:UIControlStateNormal];
    [simpleTransformButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [simpleTransformButton addTarget:self action:@selector(simpleTransformAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:simpleTransformButton];
    
    UIButton *advanceTransformButton = [UIButton buttonWithType:UIButtonTypeCustom];
    advanceTransformButton.frame = CGRectMake(282, 20, 84, 44);
    [advanceTransformButton setTitle:@"高级变换" forState:UIControlStateNormal];
    [advanceTransformButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [advanceTransformButton addTarget:self action:@selector(advanceTransformAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:advanceTransformButton];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)photoLibAction
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)overlayAction
{
    _compositingType = CompositingTypeOverlay;
    _slideShowType = SlideShowTypeUnspecify;
    
    _overlayTextureAssetIndex = 0;
}

- (void)simpleTransformAction
{
    _compositingType = CompositingTypeSlideShow;
    _slideShowType = SlideShowTypeZoom;
    
    _overlayTextureAssetIndex = 0;
}

- (void)advanceTransformAction
{
    _compositingType = CompositingTypeSlideShow;
    _slideShowType = SlideShowTypeWave;
    
    _overlayTextureAssetIndex = 0;
}

- (void)startTimerWithFPS:(NSInteger)fps
{
    _timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(process)];
    _timer.frameInterval = 1.0/(float)fps;
    [_timer addToRunLoop:[NSRunLoop mainRunLoop]
                 forMode:NSDefaultRunLoopMode];
    
    _startTime = CFAbsoluteTimeGetCurrent();
    
    _overlayTextureAssetIndex = 0;
}

- (void)process
{
    float time =  CFAbsoluteTimeGetCurrent() - _startTime;
    
    double t1 = CFAbsoluteTimeGetCurrent();
    
    CGImageRef overlayImage = NULL;
    if (_compositingType == CompositingTypeOverlay) {
        
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"test%ld", _overlayTextureAssetIndex]];
        overlayImage = image.CGImage;
    }

    CVPixelBufferRef resultPixelBuffer = [self.renderer renderCompositingCGImage:overlayImage
                                                                     compositingType:_compositingType
                                                                       slideShowType:_slideShowType
                                                                                time:time];
    
    [self.previewView renderWithCVPixelBuffer:resultPixelBuffer];
    
    NSLog(@"perf: %f", CFAbsoluteTimeGetCurrent() - t1);
    
    _overlayTextureAssetIndex++;
    
    if (_overlayTextureAssetIndex > 5) {
        _overlayTextureAssetIndex = 0;
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:NO completion:nil];
    
    NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if (CFStringCompare((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        UIImage* img = [info objectForKey:UIImagePickerControllerEditedImage];
        if (!img)
            img = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.renderer preparePhotoCGImage:img.CGImage];
            
            //25帧每秒
            [self startTimerWithFPS:25];
            
        });
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end
