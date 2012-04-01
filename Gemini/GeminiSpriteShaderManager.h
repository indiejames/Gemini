//
//  GeminiSpriteShaderManager.h
//  Gemini
//
//  Created by James Norton on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiShaderManager.h"

// Sprite shader uniform index
enum {
    UNIFORM_PROJECTION_SPRITE,
    NUM_UNIFORMS_SPRITE
};

// Sprite attribute index
enum {
    ATTRIB_VERTEX_SPRITE,
    ATTRIB_TEXCOORD_SPRITE,
    NUM_ATTRIBUTES_SPRITE
};


@interface GeminiSpriteShaderManager : GeminiShaderManager

@end
