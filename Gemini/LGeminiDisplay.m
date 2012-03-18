//
//  LGeminiDisplay.m
//  Gemini
//
//  Created by James Norton on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LGeminiDisplay.h"
#import "Gemini.h"
#import "GeminiDisplayGroup.h"

///////////// display groups //////////////////
static int newDisplayGroup(lua_State *L){
    GeminiDisplayGroup *group = [[GeminiDisplayGroup alloc] initWithLuaState:L];
    GeminiDisplayGroup **lGroup = (GeminiDisplayGroup **)lua_newuserdata(L, sizeof(GeminiDisplayGroup *));
    *lGroup = group;
    
    luaL_getmetatable(L, GEMINI_DISPLAY_GROUP_LUA_KEY);
    lua_setmetatable(L, -2);
    lua_pushvalue(L, -1); // make another copy of the userdata since the next line will pop it off
    group.selfRef = luaL_ref(L, LUA_REGISTRYINDEX);
    
    return 1;
}

static int displayGroupGC (lua_State *L){
    GeminiDisplayGroup  **group = (GeminiDisplayGroup **)luaL_checkudata(L, 1, GEMINI_DISPLAY_GROUP_LUA_KEY);
    
    [*group release];
    
    return 0;
}

static int displayGroupInsert(lua_State *L){
     NSLog(@"Calling displayGroupInsert()");
   GeminiDisplayGroup  **group = (GeminiDisplayGroup **)luaL_checkudata(L, 1, GEMINI_DISPLAY_GROUP_LUA_KEY); 
    GeminiDisplayObject **displayObj = (GeminiDisplayObject **)lua_touserdata(L, 2);
    [*group insert:*displayObj];
    
    return 0;
}

// this index uses the meta table itself to handle string keys and the attached display group object for integer keys
static int displayGroupIndex( lua_State* L )
{
    NSLog(@"Calling displayGroupIndex()");
    GeminiDisplayGroup  **group = (GeminiDisplayGroup **)luaL_checkudata(L, 1, GEMINI_DISPLAY_GROUP_LUA_KEY);    
    
    
    int index = lua_tonumber(L, 2) - 1;
    if (index > -1) {
        GeminiObject *obj = (GeminiObject *)[(*group).objects objectAtIndex:index];
        lua_rawgeti(L, LUA_REGISTRYINDEX, obj.selfRef);
        
    } else {
        // not a valid index must be a method name so use the metatable to look it up
        lua_getmetatable(L, 1);
        lua_pushvalue(L, -2);
        lua_gettable(L, -2);
        
        return 1;
        
    }
    
    
    return 1;
}

// the mappings for the library functions
static const struct luaL_Reg displayLib_f [] = {
    {"newGroup", newDisplayGroup},
    {NULL, NULL}
};

// mappings for the display group methods
static const struct luaL_Reg displayGroup_m [] = {
    {"insert", displayGroupInsert},
    {"__gc", displayGroupGC},
    {"__index", displayGroupIndex},
    {NULL, NULL}
};


int luaopen_display_lib (lua_State *L){
    // create meta tables for our various types /////////
    
    // display groups
    luaL_newmetatable(L, GEMINI_DISPLAY_GROUP_LUA_KEY);
    
    lua_pushvalue(L, -1); // duplicates the metatable
    
    luaL_setfuncs(L, displayGroup_m, 0);
    
    
    /////// finished with metatables ///////////
    
    // create the table for this library and popuplate it with our functions
    luaL_newlib(L, displayLib_f);
    
    return 1;
}