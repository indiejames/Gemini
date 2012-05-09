//
//  GeminiRectangle.h
//  Gemini
//
//  Created by James Norton on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiDisplayObject.h"

@interface GeminiRectangle : GeminiDisplayObject {
    GLfloat *verts;
    GLushort *vertIndex;
    GLKVector4 *fillColor;
}

-(id) initWithLuaState:(lua_State *)luaState X:(GLfloat)x Y:(GLfloat)y Width:(GLfloat)width Height:(GLfloat)height;

@end
