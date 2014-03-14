//
//  WDShader.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDShader.h"
#import "Shaders.h"

@implementation WDShader

@synthesize program = program_;
@synthesize uniforms = uniforms_;

+ (WDShader *) shaderWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
                       attributesNames:(NSArray *)attributeNames uniformNames:(NSArray *)uniformNames
{
    WDShader *shader = [[WDShader alloc] initWithVertexShader:vertexShader
                                               fragmentShader:fragmentShader
                                              attributesNames:attributeNames
                                                 uniformNames:uniformNames];
    
    return shader;
}

- (id) initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
                attributesNames:(NSArray *)attributeNames uniformNames:(NSArray *)uniformNames
{
    self = [super init];
    
    if (!self) {
        return nil;
        
    }
    
    GLuint vertShader = 0, fragShader = 0;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // create shader program
    program_ = glCreateProgram();
    
    // create and compile vertex shader
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:vertexShader ofType:@"vsh"];
    if (!compileShader(&vertShader, GL_VERTEX_SHADER, 1, vertShaderPathname)) {
        destroyShaders(vertShader, fragShader, program_);
        return nil;
    }
    
    // create and compile fragment shader
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShader ofType:@"fsh"];
    if (!compileShader(&fragShader, GL_FRAGMENT_SHADER, 1, fragShaderPathname)) {
        destroyShaders(vertShader, fragShader, program_);
        return nil;
    }
    
    // attach vertex shader to program
    glAttachShader(program_, vertShader);
    
    // attach fragment shader to program
    glAttachShader(program_, fragShader);
    
    // bind attribute locations; this needs to be done prior to linking
    [attributeNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        glBindAttribLocation(program_, (GLuint) idx, [obj cStringUsingEncoding:NSUTF8StringEncoding]);
    }];
    
    // link program
    if (!linkProgram(program_)) {
        destroyShaders(vertShader, fragShader, program_);
        return nil;
    }
    
    NSMutableDictionary *uniformMap = [[NSMutableDictionary alloc] initWithCapacity:uniformNames.count];
    for (NSString *uniformName in uniformNames) {
        GLuint location = glGetUniformLocation(program_, [uniformName cStringUsingEncoding:NSUTF8StringEncoding]);
        uniformMap[uniformName] = @(location);
    }
    uniforms_ = uniformMap;
    
    // release vertex and fragment shaders
    if (vertShader) {
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader) {
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    
    return self;
}

- (void) freeGLResources
{
    glDeleteProgram(program_);
}

- (void) dealloc
{
    glDeleteProgram(program_);
}

- (GLuint) locationForUniform:(NSString *)uniform
{
    NSNumber *number = uniforms_[uniform];
    return [number unsignedIntValue];
}

@end
