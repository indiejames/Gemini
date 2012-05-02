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
@synthesize verts;
@synthesize vertIndex;
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
        verts = NULL;
        vertIndex = NULL;
        //[self computeVertices];
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
    free(verts);
    free(vertIndex);
    [parent remove:self];
    [super dealloc];
}

// add points to this line - expect newPoints to hold 2 * count GLfloats
-(void)append:(int)count Points:(const GLfloat *)newPoints {
    points = (GLfloat *)realloc(points, (numPoints + count) * 2 * sizeof(GLfloat));
    memcpy(points + numPoints * 2, newPoints, count*2*sizeof(GLfloat));
    numPoints = numPoints + count;
}

-(void)computeVertices {
    verts = realloc(verts, 2*2*numPoints*sizeof(GLfloat));
    vertIndex = realloc(vertIndex, 6*(numPoints - 1));
    GLfloat halfWidth = [self getDoubleForKey:"width" withDefault:1.0] / 2.0;
    
    for (int i=0; i<numPoints; i++) {
        
        if (i != 0){
            vertIndex[(i-1)*4] = (i-1)*2;
            vertIndex[(i-1)*4+1] = (i-1)*2+1;
            vertIndex[(i-1)*4+2] = (i-1)*2+2;
            vertIndex[(i-1)*4+3] = (i-1)*2+1;
            vertIndex[(i-1)*4+4] = (i-1)*2+3;
            vertIndex[(i-1)*4+5] = (i-1)*2+2;
            
        }
        
        if (i == 0) { // first point
            
            // compute adjacent points
            GLKVector2 vecA = GLKVector2Make(points[i*2], points[i*2+1]);
            GLKVector2 vecB = GLKVector2Make(points[(i+1)*2], points[(i+1)*2+1]);
            GLKVector2 vecAB = GLKVector2Subtract(vecB, vecA);
            GLKVector2 vecABhat = GLKVector2Normalize(vecAB);
            GLKVector2 vecA0 = GLKVector2Add(GLKVector2MultiplyScalar(GLKVector2Make(-vecABhat.y, vecABhat.x), halfWidth), vecA);
            GLKVector2 vecA1 = GLKVector2Add(GLKVector2MultiplyScalar(GLKVector2Make(vecABhat.y, -vecABhat.x), halfWidth), vecA);
            verts[0] = vecA0.x;
            verts[1] = vecA0.y;
            verts[2] = vecA1.x;
            verts[3] = vecA1.y;
            
        } else if(i == numPoints - 1) { // last point            
            
            // compute adjacent points
            GLKVector2 vecA = GLKVector2Make(points[i*2], points[i*2+1]);
            GLKVector2 vecB = GLKVector2Make(points[(i-1)*2], points[(i-1)*2+1]);
            GLKVector2 vecAB = GLKVector2Subtract(vecB, vecA);
            GLKVector2 vecABhat = GLKVector2Normalize(vecAB);
            GLKVector2 vecA0 = GLKVector2Add(GLKVector2MultiplyScalar(GLKVector2Make(vecABhat.y, -vecABhat.x), halfWidth), vecA);
            GLKVector2 vecA1 = GLKVector2Add(GLKVector2MultiplyScalar(GLKVector2Make(-vecABhat.y, vecABhat.x), halfWidth), vecA);
            verts[i*4] = vecA0.x;
            verts[i*4+1] = vecA0.y;
            verts[i*4+2] = vecA1.x;
            verts[i*4+3] = vecA1.y;
            
            
        } else {
            
            // get the previous computed points
            GLKVector2 vecA = GLKVector2Make(points[(i-1)*2], points[(i-1)*2+1]);
            GLKVector2 vecB = GLKVector2Make(points[i*2], points[i*2+1]);
            GLKVector2 vecC = GLKVector2Make(points[(i+1)*2], points[(i+1)*2+1]);
            
            GLKVector2 vecA0 = GLKVector2Make(verts[(i-1)*4], verts[(i-1)*4+1]);
            GLKVector2 vecA1 = GLKVector2Make(verts[(i-1)*4+2], verts[(i-1)*4+3]);
            
            GLKVector2 vecAB = GLKVector2Subtract(vecB, vecA);
            GLKVector2 vecCB = GLKVector2Subtract(vecC, vecB);
            GLKVector2 vecCBhat = GLKVector2Normalize(vecCB);
            
            GLKVector2 vecC1 = GLKVector2Add(GLKVector2MultiplyScalar(GLKVector2Make(vecCBhat.y, -vecCBhat.x), halfWidth), vecA);
            GLKVector2 vecC0 = GLKVector2Add(GLKVector2MultiplyScalar(GLKVector2Make(-vecCBhat.y, vecCBhat.x), halfWidth), vecA);
           
            
            // find the lines parallel to AB throug A0 and A1 and lines parallel to CB though
            // C0 and C1 - handle infinte slope cases
            if (vecAB.x == 0) {
                // infite slope from A to B
                if (vecCB.x == 0) {
                    // infinite slope from B to C
                    // point B is in the middle of a vertical segment so just offset x for adjacent
                    // points B0 and B1
                    GLfloat B0y = vecB.y;
                    GLfloat B1y = vecB.y;
                    GLfloat B0x;
                    GLfloat B1x;
                    
                    if (vecAB.y < 0) {
                        // point B is below point A
                        B0x = vecB.x + halfWidth;
                        B1x = vecB.x - halfWidth;
                    } else {
                        B0x = vecB.x - halfWidth;
                        B1x = vecB.x + halfWidth;
                    }
                    
                    verts[i*4] = B0x;
                    verts[i*4+1] = B0y;
                    verts[i*4+2] = B1x;
                    verts[i*4+3] = B1y;
                    
                } else {
                    
                }
                
            } else {
                GLfloat slopeAB = vecAB.y / vecAB.x;
                GLfloat bA0 = vecA0.y - slopeAB * vecA0.x;
                GLfloat bA1 = vecA1.y - slopeAB * vecA1.x;
                if (vecCB.x == 0) {
                    // infinite slope from B to C
                   /* if (vecC.y < vecB.y) {
                        C0x = vecC.x + halfWidth;
                        C1x = vecC.x - halfWidth;
                    } else {
                        C0x = vecC.x - halfWidth;
                        C1x = vecC.x + halfWidth;                        
                    }
                    
                    C0y = vecC.y;
                    C1y = vecC.y;
                    */
                    
                    
                } else {
                    
                   /* C0x = -vecCBhat.y;
                    C0y = vecCBhat.x;
                    C1x = vecCBhat.y;
                    C1y = -vecCBhat.x;*/
                    GLfloat slopeBC = -vecCB.y / vecCB.x;
                    GLfloat bC0 = vecC0.y - slopeBC * vecC0.x;
                    GLfloat bC1 = vecC1.y - slopeBC * vecC1.x;
                    
                    // now find intersection
                    GLfloat B0y = slopeAB*(bA0-bC0)/(slopeAB - slopeBC) + bA0;
                    GLfloat B0x = (bC0 - bA0)/(slopeAB - slopeBC);
                    
                    GLfloat B1y = slopeAB*(bA1-bC1)/(slopeAB - slopeBC) + bA1;
                    GLfloat B1x = (bC1 - bA1)/(slopeAB - slopeBC);
                    
                    verts[i*4] = B0x;
                    verts[i*4+1] = B0y;
                    verts[i*4+2] = B1x;
                    verts[i*4+3] = B1y;
                }
   
            }
            
        }
                  
    }
}

@end
