//
//  LGeminiTransition.m
//  Gemini
//
//  Created by James Norton on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LGeminiTransition.h"
#import "GeminiDisplayObject.h"
#import "GeminiTransistion.h"
#import "GeminiTransitionManager.h"

int luaopen_transition_lib (lua_State *L);

static int createTransition(lua_State *L, BOOL to){
    GeminiDisplayObject **displayObj = (GeminiDisplayObject **)lua_touserdata(L, 1);
    if (!lua_istable(L, 2)) {
        luaL_error(L, "transition.to/from expects second parameter to be a table");
        return 0;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:1];
    
    lua_pushnil(L);  /* first key */
    while (lua_next(L, 2) != 0) {
        /* uses 'key' (at index -2) and 'value' (at index -1) */
        printf("%s - %s\n",
               lua_typename(L, lua_type(L, -2)),
               lua_typename(L, lua_type(L, -1)));
        const char *key = lua_tostring(L, -2);
        double val = lua_tonumber(L, -1);
        
        [params setObject:[NSNumber numberWithDouble:val] forKey:[NSString stringWithUTF8String:key]];
        
        /* removes 'value'; keeps 'key' for next iteration */
        lua_pop(L, 1);
    }
    
    GeminiTransistion *transition = [[GeminiTransistion alloc] initWithObject:*displayObj Data:params To:to];
    
    GeminiTransistion **ltrans = (GeminiTransistion **)lua_newuserdata(L, sizeof(GeminiTransistion *));
    *ltrans = transition;
    
    [[GeminiTransitionManager shared] addTransition:transition];
    
    return 1;
}

static int transitionTo(lua_State *L){
    return createTransition(L, YES);
}

static int transitionFrom(lua_State *L){
    return createTransition(L, NO);
}

static int transitionCancel(lua_State *L){
    
    return 0;
}

static int transitionDissolve(lua_State *L){
    return 0;
}

static int gc(lua_State *L){
    
    return 0;
}

static int newIndex(lua_State *L){
    
    return 0;
}



// the mappings for the library functions
static const struct luaL_Reg transitionLib_f [] = {
    {"to", transitionTo},
    {"from", transitionFrom},
    {NULL, NULL}
};

// mappings for the transition methods
static const struct luaL_Reg transition_m [] = {
    {"cancel", transitionCancel},
    {"dissolve", transitionDissolve},
    {"__gc", gc},
    {"__index", genericIndex},
    {"__newindex", newIndex},
    {NULL, NULL}
};

int luaopen_transition_lib (lua_State *L){
    // create meta table for transition objects /////////
    createMetatable(L, GEMINI_TRANSITION_LUA_KEY, transition_m);
        
    // create the table for this library and popuplate it with our functions
    luaL_newlib(L, transitionLib_f);
    
    return 1;
}