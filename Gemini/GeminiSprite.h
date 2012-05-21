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
    GeminiSpriteAnimation *currentAnimation;
    double lastUpdateTime;
    double accumulatedTime;
    unsigned int currentFrame;
    BOOL paused;
}

@property (readonly) GLKTextureInfo *textureInfo;
@property (readonly) GLKVector4 textureCoord;
@property BOOL paused;

-(id) initWithLuaState:(lua_State *)luaState SpriteSet:(GeminiSpriteSet *)ss;
-(void)prepare;
-(void)prepareAnimation:(NSString *)animationName;
-(void)update:(double)currentTime;
-(void)play:(double)currentTime;
-(void)pause:(double)currentTime;

@end
