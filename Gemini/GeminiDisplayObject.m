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


-(id)initWithLuaState:(lua_State *)luaState {
    self = [super initWithLuaState:luaState];
    
    if (self) {
        
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
    return [super getDoubleForKey:"height" withDefault:0];
}

-(void)setHeight:(GLfloat)ht {
    [super setDouble:ht forKey:"height"];
}

-(GLfloat) width {
    return [super getDoubleForKey:"width" withDefault:1.0];
}

-(void)setWidth:(GLfloat)width {
    [super setDouble:width forKey:"width"];
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
    return [super getDoubleForKey:"rotation" withDefault:0];
}

-(void)setRotation:(GLfloat)rotation {
    [super setDouble:rotation forKey:"rotation"];
}

-(GLfloat)x {
    return [super getDoubleForKey:"x" withDefault:0];
}

-(void)setX:(GLfloat)x {
    [super setDouble:x forKey:"x"];
}

-(GLfloat)y {
    return [super getDoubleForKey:"y" withDefault:0];
}

-(void)setY:(GLfloat)y {
    [super setDouble:y forKey:"y"];
}

-(GLfloat)xOrigin {
    return [super getDoubleForKey:"xOrigin" withDefault:0];
}

-(void)setXOrigin:(GLfloat)xOrigin {
    [super setDouble:xOrigin forKey:"xOrigin"];
}

-(GLfloat)yOrigin {
    return [super getDoubleForKey:"yOrigin" withDefault:0];
}

-(void)setYOrigin:(GLfloat)yOrigin {
    [super setDouble:yOrigin forKey:"yOrigin"];
}

-(GLfloat)xReference {
    return [super getDoubleForKey:"xReference" withDefault:0];
}

-(void)setXReference:(GLfloat)xReference {
    [super setDouble:xReference forKey:"xReference"];
}

-(GLfloat)yReference {
    return [super getDoubleForKey:"yReference" withDefault:0];
}

-(void)setYReference:(GLfloat)yReference {
    [super setDouble:yReference forKey:"yReference"];
}

-(GLfloat)xScale {
    return [super getDoubleForKey:"xScale" withDefault:1.0];
}

-(void)setXScale:(GLfloat)xScale {
    [super setDouble:xScale forKey:"xScale"];
}

-(GLfloat)yScale {
    return [super getDoubleForKey:"yScale" withDefault:1.0];
}

-(void)setYScale:(GLfloat)yScale {
    [super setDouble:yScale forKey:"yScale"];
}

-(GLKMatrix4) transform {
    GLKMatrix4 rval = GLKMatrix4Identity;
    
    if (self.xScale != 1.0 || self.yScale != 1.0) {
        rval = GLKMatrix4Scale(rval, self.xScale, self.yScale, 1.0);
    }
    
    if (self.rotation != 0) {
        rval = GLKMatrix4Rotate(rval, self.rotation, 0, 0, 1.0);
    }
    
    return rval;
}

@end
