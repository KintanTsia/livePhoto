//
//  WFFixedGLRenderer.m
//  WecutFace
//
//  Created by kintan on 2017/8/2.
//  Copyright © 2017年 Wecut. All rights reserved.
//

#import "WFFixedGLRenderer.h"
#import "WFGLProgram.h"

#define STRINGIZEVAL(x) #x
#define STRINGIZEVAL2(x) STRINGIZEVAL(x)
#define SHADER_STRING(text) @ STRINGIZEVAL2(text)

NSString *const kVertexShaderString = SHADER_STRING
(
 
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 
 );

NSString *const kFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 uniform sampler2D photoTexture;
 uniform sampler2D inputImageTexture;
 varying lowp vec2 textureCoordinate;
 
 uniform int ctype;
 uniform int stype;
 uniform float time;
 
 uniform vec2 resolution;
 
 vec3 mod289(vec3 x) {
     return x - floor(x * (1.0 / 289.0)) * 289.0;
 }
 
 vec4 mod289(vec4 x) {
     return x - floor(x * (1.0 / 289.0)) * 289.0;
 }
 
 vec4 permute(vec4 x) {
     return mod289(((x*34.0)+1.0)*x);
 }
 
 vec4 taylorInvSqrt(vec4 r)
{
    return 1.79284291400159 - 0.85373472095314 * r;
}
 
 float snoise(vec3 v)
{
    const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
    const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);
    
    // First corner
    vec3 i  = floor(v + dot(v, C.yyy) );
    vec3 x0 =   v - i + dot(i, C.xxx) ;
    
    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );
    
    //   x0 = x0 - 0.0 + 0.0 * C.xxx;
    //   x1 = x0 - i1  + 1.0 * C.xxx;
    //   x2 = x0 - i2  + 2.0 * C.xxx;
    //   x3 = x0 - 1.0 + 3.0 * C.xxx;
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
    vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y
    
    // Permutations
    i = mod289(i);
    vec4 p = permute( permute( permute(
                                       i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
                              + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
                     + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));
    
    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float n_ = 0.142857142857; // 1.0/7.0
    vec3  ns = n_ * D.wyz - D.xzx;
    
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)
    
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)
    
    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    
    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );
    
    //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
    //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    
    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
    
    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);
    
    //Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    
    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
                                 dot(p2,x2), dot(p3,x3) ) );
}
 
 float fBm(vec3 coords)
{
    const int octaves = 2;
    
    float smoothness = 2.0; // should be between 0.0 and 1.0?
    float lacunarity = 2.0;
    
    float result = 0.0;
    float totalAmplitude = 0.0;
    
    for (int o = 0; o != octaves; ++o)
    {
        float amplitude = pow(lacunarity, -smoothness * float(o));
        
        result += snoise(coords) * amplitude;
        totalAmplitude += amplitude;
        
        coords *= lacunarity;
    }
    
    return result / totalAmplitude;
}
 
 float turbulence(vec3 coords)
{
    const float f_low = 1.0;
    const int octaves = 8;
    
    float t = 0.0;
    
    for (int o = 0; o != octaves; ++o)
    {
        float f = f_low * pow(2.0, float(o));
        
        t += abs(snoise(coords)) / f;
        
        coords *= 2.0;
    }
    
    return t; // - 0.3;
}
 
 //normal
 vec4 blendNormal(vec4 c1, vec4 c2)
{
    vec4 outputColor;
    outputColor.r = c1.r + c2.r * c2.a * (1.0 - c1.a);
    outputColor.g = c1.g + c2.g * c2.a * (1.0 - c1.a);
    outputColor.b = c1.b + c2.b * c2.a * (1.0 - c1.a);
    outputColor.a = c1.a + c2.a * (1.0 - c1.a);
    return outputColor;
}
 
 
//水波纹
#define F cos(x-y)*cos(y),sin(x+y)*sin(y)
  vec2 ripple(vec2 point)
{
    //d 水波纹的剧烈程度
    float d=sin(time)*0.98;
    float x=10.*(point.x+d);
    float y=3.*(point.y+d);
    return vec2(F);
}
 
 
 void main() {
     
     gl_FragColor = vec4(vec3(0.0), 1.0);
     
     if (ctype == 2) {  // 2 slide show
         if (stype == 1) { //zoom
             
             int test =1;
             
             //放大缩小
             if (test == 0){
                 vec2 uv = textureCoordinate;
                 uv -= vec2(0.5);
                 uv = uv*abs(sin(time));
                 uv += vec2(0.5);
                 vec3 bg = texture2D(photoTexture, uv).rgb;
                 gl_FragColor = vec4(vec3(bg), 1.0);
             }
             //循环混合显示
             else if(test == 1){
                 
                 vec2 uv = textureCoordinate;

                 float count = 3.0;
                 for (float i = 0.0;i != count; i++)
                 {
                     
                     float w = 1.0 - i / count;
                     w = w + mod(time, 1.0) / count;
                     //w = w * abs(sin(iTime));
                     float minOffset = (1.0 - w) / 2.0;
                     float maxOffset = 1.0 - minOffset;
                     
                     if ((uv.x >= minOffset && uv.x <= maxOffset) && (uv.y >= minOffset && uv.y <= maxOffset))
                     {
                         uv = vec2 (uv - vec2(minOffset)) / w;
                     }
                 }
                 gl_FragColor = texture2D(photoTexture,uv);
             }
             
             
         } else if (stype == 2) {
             //水波纹
             vec2 uv = textureCoordinate;
             float iResolutionX = resolution.x;
             vec4 textureColor1 = texture2D(photoTexture,uv);
             vec2 q = uv+2./iResolutionX*(ripple(uv)-ripple(uv+resolution.xy));
             gl_FragColor = texture2D(photoTexture, q);

         }
         
     } else if (ctype == 1) {
         
         vec4 bg = texture2D(photoTexture, textureCoordinate);
         vec4 fg = texture2D(inputImageTexture, textureCoordinate);
         gl_FragColor = blendNormal(fg, bg);
         
     }
 }
 );

@interface WFFixedGLRenderer ()
{
    GLuint _framebuffer;
    CVOpenGLESTextureCacheRef _coreVideoTextureCache;
    
    CVPixelBufferRef _renderTarget;
    CVOpenGLESTextureRef _renderTexture;
    
    CGSize _viewportSize;
    
    GLuint _photoTexture;
}

@property (nonatomic, strong) WFGLProgram *program;
@property (nonatomic, strong) EAGLContext *glContext;

@end

@implementation WFFixedGLRenderer

- (instancetype)initWithContext:(EAGLContext *)context
{
    self = [super init];
    if (self) {
        
        self.glContext = context;
        
        [self prepareRenderingWithVertexShaderSource:kVertexShaderString fragmentShaderSource:kFragmentShaderString];
        
    }
    return self;
}

- (void)dealloc
{
    if (_photoTexture) {
        glDeleteTextures(1, &_photoTexture);
    }
    
    if (_coreVideoTextureCache) {
        CFRelease(_coreVideoTextureCache);
        _coreVideoTextureCache = NULL;
    }
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderTarget) {
        CFRelease(_renderTarget);
        _renderTarget = NULL;
    }
    
    if (_renderTexture) {
        CFRelease(_renderTexture);
        _renderTexture = NULL;
    }
    
    if (_glContext) {
        [EAGLContext setCurrentContext:nil];
        _glContext = nil;
    }
    
}

#pragma mark - Private Methods
- (CVOpenGLESTextureCacheRef)coreVideoTextureCache;
{
    if (_coreVideoTextureCache == NULL) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                                    NULL,
                                                    self.glContext,
                                                    NULL,
                                                    &_coreVideoTextureCache);
        if (err) {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
    
    return _coreVideoTextureCache;
}

- (GLuint)textureFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    double t1 = CFAbsoluteTimeGetCurrent();
    
    GLuint texture = 0;
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 (GLsizei)width,
                 (GLsizei)height,
                 0,
                 GL_BGRA,
                 GL_UNSIGNED_BYTE,
                 CVPixelBufferGetBaseAddress(pixelBuffer));
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    NSLog(@"cast: %f", CFAbsoluteTimeGetCurrent() - t1);
    
    return texture;
}

- (GLuint)textureFromCGImage:(CGImageRef)image
{
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    GLubyte *imageData = (GLubyte *)malloc((int)width * (int)height * 4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)width, (int)height, 8,
                                                      (int)width * 4, genericRGBColorspace,
                                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, width, height), image);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    GLuint texture = 0;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    free(imageData);
    
    return texture;
}

#pragma mark - Public Methods
- (EAGLContext *)renderContext
{
    return _glContext;
}

- (void)prepareRenderingWithVertexShaderSource:(NSString *)vertexShaderSource
                          fragmentShaderSource:(NSString *)fragmentShaderSource
{
    [EAGLContext setCurrentContext:_glContext];
    
    self.program = [[WFGLProgram alloc] initWithVertexShaderString:vertexShaderSource
                                              fragmentShaderString:fragmentShaderSource];
    
    [self.program addAttribute:@"position"];
    [self.program addAttribute:@"inputTextureCoordinate"];
    
    if (![self.program link]) {
        self.program = nil;
        NSAssert(NO, @"Filter shader link failed");
    }
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat squareTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    GLuint positionAttribute = [self.program attributeIndex:@"position"];
    GLuint textureCoordinateAttribute = [self.program attributeIndex:@"inputTextureCoordinate"];
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, GL_FALSE, 0, squareVertices);
    glVertexAttribPointer(textureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, 0, squareTextureCoordinates);
    
    glEnableVertexAttribArray(positionAttribute);
    glEnableVertexAttribArray(textureCoordinateAttribute);
    
    [EAGLContext setCurrentContext:nil];
}

#pragma mark - FBO
- (void)createFBOWithSize:(CGSize)fboSize;
{
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderTarget) {
        CFRelease(_renderTarget);
        _renderTarget = NULL;
    }
    
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    CVOpenGLESTextureCacheRef coreVideoTextureCache = [self coreVideoTextureCache];
    
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)fboSize.width, (int)fboSize.height,
                                       kCVPixelFormatType_32BGRA, attrs, &_renderTarget);
    if (err) {
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }
    
    if (_renderTexture) {
        CFRelease(_renderTexture);
        _renderTexture = NULL;
    }
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                        coreVideoTextureCache,
                                                        _renderTarget,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA, // opengl format
                                                        (int)fboSize.width,
                                                        (int)fboSize.height,
                                                        GL_BGRA, // native iOS format
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &_renderTexture);
    if (err) {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
    glBindTexture(CVOpenGLESTextureGetTarget(_renderTexture), CVOpenGLESTextureGetName(_renderTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_renderTexture), 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)setupFBOWithSize:(CGSize)fboSize;
{
    if (!_framebuffer || fboSize.width != _viewportSize.width || fboSize.height != _viewportSize.height) {
        [self createFBOWithSize:fboSize];
    }
    
    _viewportSize = fboSize;
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, (int)fboSize.width, (int)fboSize.height);
}

- (void)preparePhotoPixelBuffer:(CVPixelBufferRef)photoPixelBuffer
{
    if (photoPixelBuffer) {
        
        [EAGLContext setCurrentContext:_glContext];
        
        size_t width = CVPixelBufferGetWidth(photoPixelBuffer);
        size_t height = CVPixelBufferGetHeight(photoPixelBuffer);
        [self setupFBOWithSize:CGSizeMake(width, height)];
        
        [self.program use];

        glActiveTexture(GL_TEXTURE2);
        _photoTexture = [self textureFromPixelBuffer:photoPixelBuffer];
        glBindTexture(GL_TEXTURE_2D, _photoTexture);
        GLuint photoTextureUniform = [self.program uniformIndex:@"photoTexture"];
        glUniform1i(photoTextureUniform, 2);

        GLfloat sizeArray[2];
        sizeArray[0] = width;
        sizeArray[1] = height;

        GLuint resolutionUniform = [self.program uniformIndex:@"resolution"];  //resolution
        glUniform2fv(resolutionUniform, 1, sizeArray);
        
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)preparePhotoCGImage:(CGImageRef)cgImage
{
    if (cgImage) {
        
        [EAGLContext setCurrentContext:_glContext];
        
        size_t width = CGImageGetWidth(cgImage);
        size_t height = CGImageGetHeight(cgImage);
        [self setupFBOWithSize:CGSizeMake(width, height)];
        
        [self.program use];
        
        glActiveTexture(GL_TEXTURE2);
        _photoTexture = [self textureFromCGImage:cgImage];
        glBindTexture(GL_TEXTURE_2D, _photoTexture);
        GLuint photoTextureUniform = [self.program uniformIndex:@"photoTexture"];
        glUniform1i(photoTextureUniform, 2);
        
        GLfloat sizeArray[2];
        sizeArray[0] = width;
        sizeArray[1] = height;
        
        GLuint resolutionUniform = [self.program uniformIndex:@"resolution"];  //resolution
        glUniform2fv(resolutionUniform, 1, sizeArray);
        
        [EAGLContext setCurrentContext:nil];
    }
}

#pragma mark - Rendering
- (CVPixelBufferRef)renderCompositingPixelBuffer:(CVPixelBufferRef)compositingPixelBuffer
                                 compositingType:(CompositingType)compositingType
                                   slideShowType:(SlideShowType)slideShowType
                                            time:(float)time
{
    if (_photoTexture) {
        [EAGLContext setCurrentContext:_glContext];
        
        [self.program use];
        
        //clear
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, _photoTexture);
        GLuint photoTextureUniform = [self.program uniformIndex:@"photoTexture"];
        glUniform1i(photoTextureUniform, 2);
        
        //overlay texture
        GLuint overlayTexture = 0;
        if (compositingPixelBuffer) {
            glActiveTexture(GL_TEXTURE3);
            overlayTexture = [self textureFromPixelBuffer:compositingPixelBuffer];
            glBindTexture(GL_TEXTURE_2D, overlayTexture);
            GLuint inputTextureUniform = [self.program uniformIndex:@"inputImageTexture"];
            glUniform1i(inputTextureUniform, 3);
        }
        
        //input params
        GLuint cTypeUniform = [self.program uniformIndex:@"ctype"];  //compositing type
        glUniform1i(cTypeUniform, compositingType);
        
        GLuint sTypeUniform = [self.program uniformIndex:@"stype"];  //slideshow type
        glUniform1i(sTypeUniform, slideShowType);
        
        GLuint timeUniform = [self.program uniformIndex:@"time"];  //slideshow type
        glUniform1f(timeUniform, time);
        
        //Draw
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glFinish();
        
    bail:
        
        if (overlayTexture) {
            glDeleteTextures(1, &overlayTexture);
        }
        
        [EAGLContext setCurrentContext:nil];
    }
    
    return _renderTarget;
}

- (CVPixelBufferRef)renderCompositingCGImage:(CGImageRef)image
                             compositingType:(CompositingType)compositingType
                               slideShowType:(SlideShowType)slideShowType
                                        time:(float)time
{
    if (_photoTexture) {
        [EAGLContext setCurrentContext:_glContext];
        
        [self.program use];
        
        //clear
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, _photoTexture);
        GLuint photoTextureUniform = [self.program uniformIndex:@"photoTexture"];
        glUniform1i(photoTextureUniform, 2);
        
        //overlay texture
        GLuint overlayTexture = 0;
        if (image) {
            glActiveTexture(GL_TEXTURE3);
            overlayTexture = [self textureFromCGImage:image];
            glBindTexture(GL_TEXTURE_2D, overlayTexture);
            GLuint inputTextureUniform = [self.program uniformIndex:@"inputImageTexture"];
            glUniform1i(inputTextureUniform, 3);
        }
        
        //input params
        GLuint cTypeUniform = [self.program uniformIndex:@"ctype"];  //compositing type
        glUniform1i(cTypeUniform, compositingType);
        
        GLuint sTypeUniform = [self.program uniformIndex:@"stype"];  //slideshow type
        glUniform1i(sTypeUniform, slideShowType);
        
        GLuint timeUniform = [self.program uniformIndex:@"time"];  //slideshow type
        glUniform1f(timeUniform, time);
        
        //Draw
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glFinish();
        
    bail:
        
        if (overlayTexture) {
            glDeleteTextures(1, &overlayTexture);
        }
        [EAGLContext setCurrentContext:nil];
    }
    
    return _renderTarget;
}

@end
