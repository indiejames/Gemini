//
//  GeminiGLKViewController.h
//  Gemini
//
//  Created by James Norton on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "GeminiLineShaderManager.h"
#import "GeminiRenderer.h"
#import "GeminiSpriteManager.h"

// Uniform index.
enum {
    UNIFORM_PROJECTION,
    UNIFORM_ROTATION,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};



@interface GeminiGLKViewController : GLKViewController {
    EAGLContext *context;
    SEL preRenderCallback;
    SEL postRenderCallback;
    GeminiShaderManager *lineShaderManager;
    GeminiRenderer *renderer;
    GeminiSpriteManager *spriteManager;
    double updateTime;
}

@property (readonly) GeminiRenderer *renderer;
@property (readonly) GeminiSpriteManager *spriteManager;
@property (readonly) double updateTime;

-(void)setPreRenderCallback:(SEL)callback;
-(void)setPostRenderCallback:(SEL)callback;
-(id)initWithLuaState:(lua_State *)luaState;
@end
