//
//  GeminiSprite.m
//  Gemini
//
//  Created by James Norton on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiSprite.h"
#import <GLKit/GLKit.h>


@implementation GeminiSprite


-(id)initWithLuaState:(lua_State *)luaState SpriteSet:(GeminiSpriteSet *)spSet {
    self = [super initWithLuaState:luaState];
    
    if (self) {
        spriteSet = [spSet retain];
    }
    
    return self;
}

@end
