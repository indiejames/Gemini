//
//  GeminiSprite.h
//  Gemini
//
//  Created by James Norton on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiDisplayObject.h"
#import "GeminiSpriteSet.h"

@interface GeminiSprite : GeminiDisplayObject {
    GeminiSpriteSet *spriteSet;
}

-(id) initWithLuaState:(lua_State *)luaState SpriteSet:(GeminiSpriteSet *)ss;

@end
