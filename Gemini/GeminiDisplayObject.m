//
//  GeminiDisplayObject.m
//  Gemini
//
//  Created by James Norton on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiDisplayObject.h"

@implementation GeminiDisplayObject
@synthesize propertyTableRef;
@synthesize alpha;
@synthesize height;
@synthesize width;
@synthesize isHitTestMasked;
@synthesize isHetTestable;
@synthesize isVisible;
@synthesize maskRotation;
@synthesize maskScaleX;
@synthesize maskScaleY;
@synthesize maskX;
@synthesize maskY;
@synthesize parent;
@synthesize rotation;
@synthesize x;
@synthesize y;
@synthesize xOrigin;
@synthesize yOrigin;
@synthesize xReference;
@synthesize yReference;
@synthesize xScale;
@synthesize yScale;

-(id)init {
    self = [super init];
    
    xScale = 1.0;
    yScale = 1.0;
    
    return self;
}

-(GLKMatrix4) transform {
    GLKMatrix4 rval = [parent transform];
    
    if (xScale != 1.0 || yScale != 1.0) {
        rval = GLKMatrix4Scale(rval, xScale, yScale, 1.0);
    }
    
    if (rotation != 0) {
        rval = GLKMatrix4Rotate(rval, rotation, 0, 0, 1.0);
    }
    
    return rval;
}

@end
