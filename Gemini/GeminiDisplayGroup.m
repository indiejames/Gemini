//
//  GeminiDisplayGroup.m
//  Gemini
//
//  Created by James Norton on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiDisplayGroup.h"

@implementation GeminiDisplayGroup

@synthesize objects;

-(id)initWithLuaState:(lua_State *)luaState {
    self = [super initWithLuaState:luaState];
    if (self) {
        objects = [[NSMutableArray alloc] initWithCapacity:1];
        
    }
    
    return self;
}

-(void)dealloc {
    [objects release];
    [super dealloc];
}

-(void)setLayer:(GeminiLayer *)_layer {
    layer = _layer;
    for (int i=0; i<[objects count]; i++) {
        GeminiDisplayObject *child = (GeminiDisplayObject *)[objects objectAtIndex:i];
        child.layer = layer;
    }
}

-(void)insert:(GeminiDisplayObject *)obj {
    NSLog(@"Calling insert for GeminiDisplayGroup");
    if (obj.parent != nil) {
        [(GeminiDisplayGroup *)(obj.parent) remove:obj];
    }
    [objects addObject:obj];
    obj.parent = self;
    GeminiLayer *parentLayer;
    if (self.layer == nil) {
        // this must be a layer
        parentLayer = (GeminiLayer *)self;
    } else {
        parentLayer = self.layer;
    }
    
    obj.layer = parentLayer;
}

-(void)remove:(GeminiDisplayObject *)obj {
    NSLog(@"Calling remove for GeminiDisplayGroup");
    [objects removeObject:obj];
    obj.parent = nil;
}

// compute the height and width of this group based on the object within it
-(void)recomputeWidthHeight {
    
}

@end
