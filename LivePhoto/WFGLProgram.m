//
//  WFGLProgram.m
//  WecutFace
//
//  Created by kintan on 2017/8/2.
//  Copyright © 2017年 Wecut. All rights reserved.
//

#import "WFGLProgram.h"

@interface WFGLProgram ()
{
    NSMutableArray  *_attributes;
    GLuint          _program;
    GLuint          _vertShader;
    GLuint          _fragShader;
}

@end

@implementation WFGLProgram

- (instancetype)initWithVertexShaderString:(NSString *)vShaderString
                      fragmentShaderString:(NSString *)fShaderString;
{
    self = [super init];
    if (self) {
        _attributes = [NSMutableArray array];
        _program = glCreateProgram();
        
        if (![self compileShader:&_vertShader
                            type:GL_VERTEX_SHADER
                          string:vShaderString]) {
            NSLog(@"Failed to compile vertex shader");
        }
        
        if (![self compileShader:&_fragShader
                            type:GL_FRAGMENT_SHADER
                          string:fShaderString]) {
            NSLog(@"Failed to compile fragment shader");
        }
        
        glAttachShader(_program, _vertShader);
        glAttachShader(_program, _fragShader);
    }
    
    return self;
}

- (void)dealloc
{
    glDeleteShader(_vertShader);
    glDeleteShader(_fragShader);
    glDeleteProgram(_program);
}

- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
               string:(NSString *)shaderString
{
    GLint status;
    const GLchar *source;
    
    source =
    (GLchar *)[shaderString UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
    if (status != GL_TRUE) {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            NSLog(@"Shader compile log:\n%s", log);
            free(log);
        }
        
        glDeleteShader(*shader);
    }
    
    return status == GL_TRUE;
}

- (void)addAttribute:(NSString *)attributeName
{
    if (![_attributes containsObject:attributeName])
    {
        [_attributes addObject:attributeName];
        glBindAttribLocation(_program,
                             (GLuint)[_attributes indexOfObject:attributeName],
                             [attributeName UTF8String]);
    }
}

- (GLuint)attributeIndex:(NSString *)attributeName
{
    return (GLuint)[_attributes indexOfObject:attributeName];
}

- (GLuint)uniformIndex:(NSString *)uniformName
{
    return glGetUniformLocation(_program, [uniformName UTF8String]);
}

- (BOOL)link
{
    GLint status;
    
    glLinkProgram(_program);
    
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        
        GLint maxLength = 0;
        glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &maxLength);
        
        //The maxLength includes the NULL character
        char* log = (char *)malloc(maxLength);
        glGetProgramInfoLog(_program, maxLength, &maxLength, log);
        printf("glshader link error : %s", log);
        
        free(log);
        
        glDeleteShader(_vertShader);
        glDeleteShader(_fragShader);
        glDeleteProgram(_program);
        
        return NO;
    }
    
    glDeleteShader(_vertShader);
    glDeleteShader(_fragShader);
    
    return YES;
}

- (void)use
{
    glUseProgram(_program);
}

@end
