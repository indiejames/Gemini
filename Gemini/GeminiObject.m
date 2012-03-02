//
//  GeminiObject.m
//  Gemini
//
//  Created by James Norton on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiObject.h"

@implementation GeminiObject

-(id) initWithLuaState:(lua_State *)luaState {
    self = [super init];
    if (self) {
        eventHandlers = [[NSMutableDictionary alloc] initWithCapacity:1];
        L = luaState;
    }
    
    NSLog(@"New GeminiObject inited");
    
    return self;
}

-(void) dealloc {
    NSArray *keys = [eventHandlers allKeys];
    for (NSString *key in keys) {
        NSArray *callbacks = (NSArray *)[eventHandlers objectForKey:key];
        [callbacks release];
    }
    
    [eventHandlers release];
    
    [super dealloc];
}

-(BOOL)handleEvent:(GeminiEvent *)event {
    NSLog(@"GeminiObject checking for event handelr");
    NSArray *callbacks = (NSMutableArray *)[eventHandlers objectForKey:event.name];
    int count = [callbacks count];
    NSLog(@"Found %d callbacks", count);
    
    if ([callbacks count] > 0) {
        for (int i=0; i<[callbacks count]; i++) {
            
            NSNumber *callback = (NSNumber *)[callbacks objectAtIndex:i];
            int registryKey = [callback intValue];
            lua_rawgeti(L, LUA_REGISTRYINDEX, registryKey);
            
            if (lua_isfunction(L, -1)) {
                NSLog(@"Event handler is a function");
                lua_pcall(L, 0, 0, 0);
                
            } else { // table or user data
                const char *ename = [event.name UTF8String];
                NSLog(@"Event handler is a table");
                lua_getfield(L, -1, ename);
                if(lua_isnil(L, -1)){
                    NSLog(@"lua_getfield for %s returned nil", ename);
                }
                lua_insert(L, -2);
                // TODO: we should insert the event as an argument here
                lua_pcall(L, 1, 0, 0);
            }
            
            
        }
        NSLog(@"GemniObject handled event %@", event.name);
        return YES;
    }
    
    return NO;
}

// add an event listener to this object
-(void)addEventListener:(int)callback forEvent:(NSString *)event {
    NSLog(@"GeminiObject adding event listener for %@", event);
    NSMutableArray *handler = (NSMutableArray *)[eventHandlers objectForKey:event];
    if (handler == nil) {
        handler = [[NSMutableArray alloc] initWithCapacity:1];
        [eventHandlers setObject:handler forKey:event];
    }
    
    [handler addObject:[NSNumber numberWithInt:callback]];
}

// remove an event listener for this object
-(void)removeEventListener:(int)callback forEvent:(NSString *)event {
    NSMutableArray *handler = (NSMutableArray *)[eventHandlers objectForKey:event];
    if (handler != nil) {
        [handler removeObjectIdenticalTo:[NSNumber numberWithInt:callback]];
    }
}


@end

