//
//  GeminiObject.h
//  Gemini
//
//  Created by James Norton on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeminiEvent.h"
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

@interface GeminiObject : NSObject {
    NSMutableDictionary *eventHandlers;
    lua_State *L;
}

-(id) initWithLuaState:(lua_State *)luaState;
-(void)addEventListener:(int)callback forEvent:(NSString *)event;
-(void)removeEventListener:(int)callback forEvent:(NSString *)event;
-(BOOL)handleEvent:(GeminiEvent *)event;
@end
