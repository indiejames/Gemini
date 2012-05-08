//
//  GeminiLayer.m
//  Gemini
//
//  Created by James Norton on 5/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiLayer.h"

@implementation GeminiLayer
@synthesize index;
@synthesize sourceBlend;
@synthesize destBlend;
@synthesize isBLendingLayer;

-(id)initWithLuaState:(lua_State *)luaState {
    self = [super initWithLuaState:luaState];
    if (self) {
        // default is no blending
        sourceBlend = GL_SRC_ALPHA;
        destBlend = GL_ONE_MINUS_SRC_ALPHA;
        isBLendingLayer = YES;
    }
    
    return self;
}

-(void) setBlendFuncSource:(GLenum)srcBlend Dest:(GLenum)dstBlend {
    sourceBlend = srcBlend;
    destBlend = dstBlend;
    if (srcBlend == GL_ONE && dstBlend == GL_ZERO) {
        isBLendingLayer = NO;
    } else {
        isBLendingLayer = YES;
    }
}

@end
