//
//  GeminiSpriteBatch.m
//  Gemini
//
//  Created by James Norton on 5/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiSpriteBatch.h"

@implementation GeminiSpriteBatch

@synthesize vertexBuffer;

-(id)initWithCapacity:(unsigned int)cap {
    self = [super init];
    
    if (self) {
        vertexBuffer = (TexturedVertex *)malloc(cap * sizeof(TexturedVertex));
        capacity = cap;
        bufferOffset = 0;
    }
    
    return self;
}

/*-(void)dealloc {
    free(vertexBuffer);
    
    [super dealloc];
}*/

- (void)dealloc
{
    bufferOffset = 0;
    capacity = 0;
    free(vertexBuffer);
    [super dealloc];
}


// !!! IMPORTANT !!! - calling this method will increment to insertion pointer, possibly
// allocating more memory, so ONLY call this when actually about to insert data
-(TexturedVertex *)getPointerForInsertion {
    
    unsigned int newBufferOffset = bufferOffset + 4;
    if (newBufferOffset > (capacity - 1) * 4) {
        capacity = 2 * capacity;
        vertexBuffer = (TexturedVertex *)realloc(vertexBuffer, capacity * 4 * sizeof(TexturedVertex));
    }
    
    TexturedVertex * rval = vertexBuffer + bufferOffset;
    bufferOffset = newBufferOffset;
    
    return rval;
}

// the number of sprites stored currently
-(unsigned int)count {
    return bufferOffset / 4;
}

@end
