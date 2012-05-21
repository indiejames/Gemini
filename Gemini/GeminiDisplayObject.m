//
//  GeminiDisplayObject.m
//  Gemini
//
//  Created by James Norton on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiDisplayObject.h"


@implementation GeminiDisplayObject


@synthesize parent;
@synthesize layer;
@synthesize xScale;
@synthesize yScale;

-(id)initWithLuaState:(lua_State *)luaState {
    self = [super initWithLuaState:luaState];
    
    if (self) {
        xScale = 1.0;
        yScale = 1.0;
    }
    
    return self;
}

-(GLfloat)alpha {
    return [super getDoubleForKey:"alpha" withDefault:1.0];
}

-(void)setAlpha:(GLfloat)alph {
    [super setDouble:alph forKey:"alpha"];
}

-(GLfloat)height {
    return height;
}

-(void)setHeight:(GLfloat)ht {
    //[super setDouble:ht forKey:"height"];
    height = ht;
}

-(GLfloat) width {
    //return [super getDoubleForKey:"width" withDefault:1.0];
    return width;
}

-(void)setWidth:(GLfloat)w {
    width = w;
}

-(BOOL) isHitTestMasked {
    return [super getDoubleForKey:"isHitTestMasked" withDefault:YES];
}

-(void) setIsHitTestMasked:(BOOL)isHitTestMasked {
    [super setBOOL:isHitTestMasked forKey:"isHitTestMasked"];
}

-(BOOL) isHitTestable {
    return [super getBooleanForKey:"isHitTestable" withDefault:YES];
}

-(void) setIsHitTestable:(BOOL)isHitTestable {
    [super setBOOL:isHitTestable forKey:"isHitTestable"];
}

-(BOOL)isVisible {
    return [super getBooleanForKey:"isVisible" withDefault:YES];
}

-(void)setIsVisible:(BOOL)isVisible {
    [super setBOOL:isVisible forKey:"isVisible"];
}

-(GLfloat)maskRotation {
    return [super getDoubleForKey:"maskRotation" withDefault:0];
}

-(void)setMaskRotation:(GLfloat)maskRotation {
    [super setDouble:maskRotation forKey:"maskRotation"];
}

-(GLfloat)maskScaleX {
    return [super getDoubleForKey:"maskScaleX" withDefault:1.0];
}

-(void)setMaskScaleX:(GLfloat)maskScaleX {
    [super setDouble:maskScaleX forKey:"maskScaleX"];
}

-(GLfloat)maskScaleY {
    return [super getDoubleForKey:"maskScaleY" withDefault:1.0];
}

-(void)setMaskScaleY:(GLfloat)maskScaleY {
    [super setDouble:maskScaleY forKey:"maskScaleY"];
}

-(GLfloat)maskX {
    return [super getDoubleForKey:"maskX" withDefault:0];
}

-(void)setMaskX:(GLfloat)maskX {
    [super setDouble:maskX forKey:"maskX"];
}

-(GLfloat)maskY {
    return [super getDoubleForKey:"maskY" withDefault:0];
}

-(void)setMaskY:(GLfloat)maskY {
    [super setDouble:maskY forKey:"maskY"];
}

-(GLfloat)rotation {
    //return [super getDoubleForKey:"rotation" withDefault:0];
    return rotation;
}

-(void)setRotation:(GLfloat)rot {
    //[super setDouble:rotation forKey:"rotation"];
    rotation = rot;
}

-(GLfloat)x {
    //return [super getDoubleForKey:"x" withDefault:0];
    return xOrigin + xReference;
}

-(void)setX:(GLfloat)x {
    //[super setDouble:x forKey:"x"];
    
    // must bypass property setter to avoid infinite recursion
    xOrigin = x - self.xReference;
    //[self setDouble:xOrig forKey:"xOriginal"];
}

-(GLfloat)y {
    //return [super getDoubleForKey:"y" withDefault:0];
    return yOrigin + yReference;
}

-(void)setY:(GLfloat)y {
    //[super setDouble:y forKey:"y"];
    //GLfloat yRef = self.yReference;
    
    // must bypass property setter to avoid infinite recursion
    yOrigin = y - self.yReference;
    //[self setDouble:yOrig forKey:"yOriginal"];
}

-(GLfloat)xOrigin {
    //return [super getDoubleForKey:"xOrigin" withDefault:0];
    return xOrigin;
}

-(void)setXOrigin:(GLfloat)xOrig {
    xOrigin = xOrig;
    //[super setDouble:xOrigin forKey:"xOrigin"];
    //GLfloat x = xOrigin + self.xReference;
    // must bypass property setter to avoid infinite recursion
    //[self setDouble:x forKey:"x"];
}

-(GLfloat)yOrigin {
    //return [super getDoubleForKey:"yOrigin" withDefault:0];
    return yOrigin;
}

-(void)setYOrigin:(GLfloat)yOrig {
    //[super setDouble:yOrigin forKey:"yOrigin"];
    //GLfloat y = yOrigin + self.yReference;
    // must bypass property setter to avoid infinite recursion
    //[self setDouble:y forKey:"y"];
    yOrigin = yOrig;
}

-(GLfloat)xReference {
    //return [super getDoubleForKey:"xReference" withDefault:0];
    return xReference;
}

-(void)setXReference:(GLfloat)xRef{
    //[super setDouble:xReference forKey:"xReference"];
    xReference = xRef;
    //GLfloat x = self.xOrigin + xReference;
    // must bypass property setter to avoid infinite recursion
    //[self setDouble:x forKey:"x"];
}

-(GLfloat)yReference {
    //return [super getDoubleForKey:"yReference" withDefault:0];
    return yReference;
}

-(void)setYReference:(GLfloat)yRef {
    yReference = yRef;
    //[super setDouble:yReference forKey:"yReference"];
    //GLfloat y = self.yOrigin + yReference;
    // must bypass property setter to avoid infinite recursion
    //[self setDouble:y forKey:"y"];
}



-(GLKMatrix4) transform {
    GLKMatrix4 rval = GLKMatrix4Identity;
    
    GLfloat refX = self.xOrigin + self.xReference;
    GLfloat refY = self.yOrigin + self.yReference;
    
    // need to translate reference point to origin for proper rotation scaling about it
    rval = GLKMatrix4Translate(rval, refX, refY, 0);
    
    if (self.xScale != 1.0 || self.yScale != 1.0) {
        rval = GLKMatrix4Scale(rval, self.xScale, self.yScale, 1.0);
    }
    
    if (self.rotation != 0) {
        rval = GLKMatrix4RotateZ(rval, GLKMathDegreesToRadians(self.rotation));
    }
    
    // now translate back
    rval = GLKMatrix4Translate(rval, -refX, -refY, 0);
    
    return rval;
}

@end
