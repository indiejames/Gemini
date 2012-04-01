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

#define DEFAULT_STAGE_NAME @"DEFAULT_STAGE"
#define LINE_SHADER_PROGRAM_KEY @"LINE_SHADER_PROGRAM_KEY"
#define SPRITE_SHADER_PROGRAM_KEY @"SPRITE_SHADER_PROGRAM_KEY"

@interface GeminiRenderer : NSObject {
    
    NSMutableDictionary *stages;
    NSString *activeStage;
    lua_State *L;
    GLuint lineShaderProgram;
    GLuint spriteShaderProgram;
    GeminiLineShaderManager *lineShaderManager;
    GeminiSpriteShaderManager *spriteShaderManager;
    
}

-(id) initWithLuaState:(lua_State *)luaState;

-(void)render;

-(void)setActiveStage:(NSString *)stage;
-(void)addObject:(GeminiDisplayObject *)obj toLayer:(int)layer;
-(void)addCallback:(void (*)(void))callback forLayer:(int)layer;


@end
