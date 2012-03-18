//
//  GeminiDisplayGroup.m
//  Gemini
//
//  Created by James Norton on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiDisplayGroup.h"

@implementation GeminiDisplayGroup

@synthesize layer;
@synthesize objects;

-(id)initWithLuaState:(lua_State *)luaState {
    self = [super initWithLuaState:luaState];
    if (self) {
        objects = [[NSMutableArray alloc] initWithCapacity:1];
        layer = 0;
    }
    
    return self;
}

-(void)dealloc {
    [objects release];
    [super dealloc];
}

-(void)insert:(GeminiDisplayObject *)obj {
    NSLog(@"Calling insert for GeminiDisplayObject");
    if (obj.parent != nil) {
        [(GeminiDisplayGroup *)(obj.parent) remove:obj];
    }
    [objects addObject:obj];
    obj.parent = self;
}

-(void)remove:(GeminiDisplayObject *)obj {
    NSLog(@"Calling remove for GeminiDisplayObject");
    [objects removeObject:obj];
    obj.parent = nil;
}



@end
