//
//  LGeminiLuaSupport.h
//  Gemini
//
//  Created by James Norton on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#import "GemDisplayObject.h"

void createMetatable(lua_State *L, const char *key, const struct luaL_Reg *funcs);
int genericIndex(lua_State *L);
int genericGeminiDisplayObjectIndex(lua_State *L, GemDisplayObject *obj);
int genericNewIndex(lua_State *L, GemDisplayObject **obj);
void setDefaultValues(lua_State *L);
void setupObject(lua_State *L, const char *luaKey, GemDisplayObject *obj);
