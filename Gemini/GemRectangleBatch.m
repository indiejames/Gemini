//
//  GemRectangleBatch.m
//  Gemini
//
//  Created by James Norton on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GemRectangleBatch.h"

@implementation GemRectangleBatch

@synthesize vertexBuffer;

-(id)initWithCapacity:(unsigned int)cap {
    self = [super init];
    
    if (self) {
        vertexBuffer = (GemColoredVertex *)malloc(cap * sizeof(GemColoredVertex));
        capacity = cap;
        bufferOffset = 0;
    }
    
    return self;
}

- (void)dealloc
{
    bufferOffset = 0;
    capacity = 0;
    free(vertexBuffer);
    [super dealloc];
}


// !!! IMPORTANT !!! - calling this method will increment the insertion pointer, possibly
// allocating more memory, so ONLY call this when actually about to insert data
-(GemColoredVertex *)getPointerForInsertion {
    
    unsigned int newBufferOffset = bufferOffset + 4;
    if (newBufferOffset > (capacity - 1) * 4) {
        capacity = 2 * capacity;
        vertexBuffer = (GemColoredVertex *)realloc(vertexBuffer, capacity * 4 * sizeof(GemColoredVertex));
    }
    
    GemColoredVertex * rval = vertexBuffer + bufferOffset;
    bufferOffset = newBufferOffset;
    
    return rval;
}

// the number of sprites stored currently
-(unsigned int)count {
    return bufferOffset / 4;
}


@end
