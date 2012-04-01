//
//  GeminiLineShaderManager.h
//  Gemini
//
//  Created by James Norton on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiShaderManager.h"

// Line shader uniform index
enum {
    UNIFORM_PROJECTION_LINE,
    UNIFORM_COLOR_LINE,
    NUM_UNIFORMS_LINE
};

GLint uniforms_line[NUM_UNIFORMS_LINE];

// Line attribute index
enum {
    ATTRIB_VERTEX_LINE,
    NUM_ATTRIBUTES_LINE
};


@interface GeminiLineShaderManager : GeminiShaderManager 

@end
