//
//  GeminiDisplayObject.h
//  Gemini
//
//  Created by James Norton on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface GeminiDisplayObject : NSObject {
    int propertyTableRef;
    GLfloat alpha;
    GLfloat height;
    GLfloat width;
    BOOL isHitTestMasked;
    BOOL isHetTestable;
    BOOL isVisible;
    GLfloat maskRotation;
    GLfloat maskScaleX;
    GLfloat maskScaleY;
    GLfloat maskX;
    GLfloat maskY;
    GeminiDisplayObject *parent;
    GLfloat rotation; // radians
    GLfloat x;
    GLfloat y;
    GLfloat xOrigin;
    GLfloat yOrigin;
    GLfloat xReference;
    GLfloat yReference;
    GLfloat xScale;
    GLfloat yScale;
    
}

@property (nonatomic) int propertyTableRef;
@property (nonatomic) GLfloat alpha;
@property (nonatomic) GLfloat height;
@property (nonatomic) GLfloat width;
@property (nonatomic) BOOL isHitTestMasked;
@property (nonatomic) BOOL isHetTestable;
@property (nonatomic) BOOL isVisible;
@property (nonatomic) GLfloat maskRotation;
@property (nonatomic) GLfloat maskScaleX;
@property (nonatomic) GLfloat maskScaleY;
@property (nonatomic) GLfloat maskX;
@property (nonatomic) GLfloat maskY;
@property (nonatomic, retain) GeminiDisplayObject *parent;
@property (nonatomic) GLfloat rotation;
@property (nonatomic) GLfloat x;
@property (nonatomic) GLfloat y;
@property (nonatomic) GLfloat xOrigin;
@property (nonatomic) GLfloat yOrigin;
@property (nonatomic) GLfloat xReference;
@property (nonatomic) GLfloat yReference;
@property (nonatomic) GLfloat xScale;
@property (nonatomic) GLfloat yScale;

-(GLKMatrix4) transform;

@end
