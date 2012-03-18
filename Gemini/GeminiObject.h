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
    int selfRef;
    int propertyTableRef;
}

@property (nonatomic) int selfRef;
@property (nonatomic) int propertyTableRef;

-(id) initWithLuaState:(lua_State *)luaState;
-(BOOL)getBooleanForKey:(const char*) key withDefault:(BOOL)dflt;
-(double)getDoubleForKey:(const char*) key withDefault:(double)dflt;
-(int)getIntForKey:(const char*) key withDefault:(int)dflt;
-(NSString *)getStringForKey:(const char*) key withDefault:(NSString *)dflt;
-(void)setBOOL:(BOOL)val forKey:(const char*) key;
-(void)setDouble:(double)val forKey:(const char*) key;
-(void)setInt:(int)val forKey:(const char*) key;
-(void)setString:(NSString *)val forKey:(const char*) key;
-(void)addEventListener:(int)callback forEvent:(NSString *)event;
-(void)removeEventListener:(int)callback forEvent:(NSString *)event;
-(BOOL)handleEvent:(GeminiEvent *)event;
@end
