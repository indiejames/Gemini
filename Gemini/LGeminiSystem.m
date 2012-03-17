//
//  LGeminiSystem.m
//  Gemini
//
//  Created by James Norton on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LGeminiSystem.h"
#import "Gemini.h"

// prototype for library loading function
int luaopen_system_lib (lua_State *L);

static int getTimer(lua_State *L){
    double time = [NSDate timeIntervalSinceReferenceDate];
    time = 1000.0 * (time - [Gemini shared].initTime);
    lua_pushnumber(L, time);
    return 1;
}

static const struct luaL_Reg system_f [] = {
    {"getTimer", getTimer},
    {NULL, NULL}
};


static const struct luaL_Reg system_m [] = {
    {NULL, NULL}
};


int luaopen_system_lib (lua_State *L){
    
    luaL_newmetatable(L, GEMINI_SYSTEM_LUA_KEY);
    
    lua_pushvalue(L, -1); // duplicates the metatable
    
    lua_setfield(L, -2, "__index"); // make the metatable use itself for __index
    
    luaL_setfuncs(L, system_m, 0);
    
    //lua_pushstring(L,"__gc");
    //lua_pushcfunction(L, systemGC); // don't know why the __gc funciton is registered separately
    //lua_settable(L, -3);
    
    
    /////// finished with metatable ///////////
    
    // create the table for this library
    luaL_newlib(L, system_f);
    
    return 1;
}