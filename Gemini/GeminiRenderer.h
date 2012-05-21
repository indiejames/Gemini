//
//  GeminiRenderer.h
//  Gemini
//
//  Created by James Norton on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeminiDisplayGroup.h"
#import "GeminiLineShaderManager.h"
#import "GeminiSpriteShaderManager.h"
#import "GeminiRectangleShaderManager.h"
#include "GeminiTypes.h"

#define DEFAULT_STAGE_NAME @"DEFAULT_STAGE"
#define LINE_SHADER_PROGRAM_KEY @"LINE_SHADER_PROGRAM_KEY"
#define SPRITE_SHADER_PROGRAM_KEY @"SPRITE_SHADER_PROGRAM_KEY"


@interface GeminiRenderer : NSObject {
    
    NSMutableDictionary *stages;
    NSString *activeStage;
    NSMutableDictionary *spriteBatches;
    //lua_State *L;
    GLuint lineShaderProgram;
    GLuint spriteShaderProgram;
    GLuint vertexBuffer;
    GLuint colorBuffer;
    GLuint indexBuffer;
    GLuint lineVAO;
    GLuint rectangleVAO;
    GLuint spriteVAO;
    GeminiLineShaderManager *lineShaderManager;
    GeminiSpriteShaderManager *spriteShaderManager;
    GeminiRectangleShaderManager *rectangleShaderManager;
}

-(id) initWithLuaState:(lua_State *)luaState;

-(void)render;

-(void)setActiveStage:(NSString *)stage;
-(void)addLayer:(GeminiLayer *)layer;
-(void)addObject:(GeminiDisplayObject *)obj;
-(void)addObject:(GeminiDisplayObject *)obj toLayer:(int)layer;
-(void)addCallback:(void (*)(void))callback forLayer:(int)layer;


@end
