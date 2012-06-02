//
//  GeminiDisplayObject.h
//  Gemini
//
//  Created by James Norton on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "GeminiObject.h"
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

@class GeminiDisplayGroup;
@class GeminiLayer;

@interface GeminiDisplayObject : GeminiObject {
    GeminiDisplayGroup *parent;
    GeminiLayer *layer;
    GLfloat xReference;
    GLfloat yReference;
    GLfloat xOrigin;
    GLfloat yOrigin;
    GLfloat rotation;
    GLfloat width;
    GLfloat height;
    GLfloat xScale;
    GLfloat yScale;
    GLfloat alpha;
    GLKMatrix4 transform;
    BOOL needsTransformUpdate;
}

@property (nonatomic) GLfloat alpha;
@property (nonatomic) GLfloat height;
@property (nonatomic) GLfloat width;
@property (nonatomic) BOOL isHitTestMasked;
@property (nonatomic) BOOL isHitTestable;
@property (nonatomic) BOOL isVisible;
@property (nonatomic) GLfloat maskRotation;
@property (nonatomic) GLfloat maskScaleX;
@property (nonatomic) GLfloat maskScaleY;
@property (nonatomic) GLfloat maskX;
@property (nonatomic) GLfloat maskY;
@property (nonatomic, retain) GeminiDisplayGroup *parent;
@property (nonatomic, retain) GeminiLayer *layer;
@property (nonatomic) GLfloat rotation;
@property (nonatomic) GLfloat x;
@property (nonatomic) GLfloat y;
@property (nonatomic) GLfloat xOrigin;
@property (nonatomic) GLfloat yOrigin;
@property (nonatomic) GLfloat xReference;
@property (nonatomic) GLfloat yReference;
@property (nonatomic) GLfloat xScale;
@property (nonatomic) GLfloat yScale;

-(GLKMatrix3) transform;

@end
