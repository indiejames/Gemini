//
//  GeminiLine.m
//  Gemini
//
//  Created by James Norton on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiLine.h"
#import "GeminiDisplayGroup.h"

@implementation GeminiLine

@synthesize points;
@synthesize numPoints;
@synthesize color;

-(id)initWithLuaState:(lua_State *)luaState X1:(GLfloat)x1 Y1:(GLfloat)y1 X2:(GLfloat)x2 Y2:(GLfloat)y2 {
    self = [super initWithLuaState:luaState];
    if (self) {
        points = (GLfloat *)malloc(4 * sizeof(GLfloat));
        points[0] = x1;
        points[1] = y1;
        points[2] = x2;
        points[3] = y2;
        numPoints = 2;
    }
    
    return self;
    
}

-(id)initWithLuaState:(lua_State *)luaState Parent:(GeminiDisplayGroup *)prt X1:(GLfloat)x1 Y1:(GLfloat)y1 X2:(GLfloat)x2 Y2:(GLfloat)y2 {
    self = [super initWithLuaState:luaState];
    
    if (self) {
        [prt insert:self]; 
        points = (GLfloat *)malloc(4 * sizeof(GLfloat));
        points[0] = x1;
        points[1] = y1;
        points[2] = x2;
        points[3] = y2;
        numPoints = 2;
        
    }
    
    return self;
}

-(void)dealloc {
    free(points);
    [parent remove:self];
    [super dealloc];
}

-(void)append:(int)count Points:(const GLfloat *)newPoints {
    points = (GLfloat *)realloc(points, (numPoints + count) * 2 * sizeof(GLfloat));
    memcpy(points + numPoints * 2, newPoints, count);
    numPoints = numPoints + count;
}

@end
