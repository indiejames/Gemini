//
//  LGeminiSprite.m
//  Gemini
//
//  Created by James Norton on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LGeminiSprite.h"
#import "GeminiSprite.h"
#import "GeminiSpriteSheet.h"

int luaopen_spritelib (lua_State *L);


static int newSpriteSheet(lua_State *L){
    const char *fileName = luaL_checkstring(L, 1);
    NSString *sFileName = [NSString stringWithFormat:@"%s",fileName];
    NSLog(@"Using image file %@", sFileName);
    int frameWidth = luaL_checkint(L, 2);
    int frameHeight = luaL_checkint(L, 3);
    GeminiSpriteSheet *sheet = [[GeminiSpriteSheet alloc] initWithImage:sFileName FrameWidth:frameWidth FrameHeight:frameHeight];
    GeminiSpriteSheet **lSheet = (GeminiSpriteSheet **)lua_newuserdata(L, sizeof(GeminiSpriteSheet *));
    *lSheet = sheet;
    
    luaL_getmetatable(L, GEMINI_SPRITE_SHEET_LUA_KEY);
    lua_setmetatable(L, -2);
    
    return 1;
    
}


static int newSpriteSheetFromData(lua_State *L){
    const char *fileName = luaL_checkstring(L, 1);
    NSString *sFileName = [NSString stringWithFormat:@"%s",fileName];
    NSLog(@"Using image file %@", sFileName);
    // push the key on the stack
    lua_pushstring(L, "frames");
    lua_gettable(L, -2);
    // get the number of frames in the sprite list
    lua_len(L, -1);
    int numFrames = lua_tointeger(L, -1);
    NSLog(@"Numframes = %d", numFrames);
    lua_pop(L, 1);
    // now iterate over the table elements to read the frame data
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:numFrames];
    for (int i=1; i<=numFrames; i++) {
        NSLog(@"i = %d", i);
        lua_pushinteger(L, i);
        lua_gettable(L, -2);
        // current frame is now on top of the stack
        
        // get the rotated flag
        lua_pushstring(L, "textureRotated");
        lua_gettable(L, -2);
        bool isRotated = lua_toboolean(L, -1);
        lua_pop(L, 1);
        // get the texture coords
        lua_pushstring(L, "textureRect");
        lua_gettable(L, -2);
        // texture coord table is now on top of stack
        lua_pushstring(L, "x");
        lua_gettable(L, -2);
        int x = lua_tointeger(L, -1);
        lua_pop(L, 1);
        lua_pushstring(L, "y");
        lua_gettable(L, -2);
        int y = lua_tointeger(L, -1);
        lua_pop(L, 1);
        lua_pushstring(L, "width");
        lua_gettable(L, -2);
        int width = lua_tointeger(L, -1);
        lua_pop(L, 1);
        lua_pushstring(L, "height");
        lua_gettable(L, -2);
        int height = lua_tointeger(L, -1);
        // skip the rest of the fields for now since I have no use for them yet
        
        // pop the current frame, textureRec table, and last value pulled off the stack
        lua_pop(L, 3);
        
        // now create a frame entry and store it
        NSMutableDictionary *frame = [NSMutableDictionary dictionaryWithCapacity:5];
        [frame setObject:[NSNumber numberWithBool:isRotated] forKey:@"textureRotated"];
        [frame setObject:[NSNumber numberWithInt:x] forKey:@"x"];
        [frame setObject:[NSNumber numberWithInt:y] forKey:@"y"];
        [frame setObject:[NSNumber numberWithInt:width] forKey:@"width"];
        [frame setObject:[NSNumber numberWithInt:height] forKey:@"height"];
        
        [frames addObject:frame];

    }
    
    GeminiSpriteSheet *sheet = [[GeminiSpriteSheet alloc] initWithImage:sFileName Data:frames];
    GeminiSpriteSheet **lSheet = (GeminiSpriteSheet **)lua_newuserdata(L, sizeof(GeminiSpriteSheet *));
    *lSheet = sheet;
    
    luaL_getmetatable(L, GEMINI_SPRITE_SHEET_LUA_KEY);
    lua_setmetatable(L, -2);
    
    return 1;
    
}

static int spriteSheetFrameCount (lua_State *L){
    GeminiSpriteSheet  **ss = (GeminiSpriteSheet **)luaL_checkudata(L, 1, GEMINI_SPRITE_SHEET_LUA_KEY);
    lua_pushinteger(L, [(*ss) frameCount]);
     
    return 1;
}

static int spriteSheetGC (lua_State *L){
    GeminiSpriteSheet  **ss = (GeminiSpriteSheet **)luaL_checkudata(L, 1, GEMINI_SPRITE_SHEET_LUA_KEY);
    
    [*ss release];
    
    return 0;
}


static const struct luaL_Reg spriteSheet_f [] = {
    {"newSpriteSheet", newSpriteSheet},
    {"newSpriteSheetFromData", newSpriteSheetFromData},
    {NULL, NULL}
};

static const struct luaL_Reg spriteSheet_m [] = {
    {"frameCount", spriteSheetFrameCount},
    {NULL, NULL}
};

int luaopen_spritelib (lua_State *L){
    // create meta tables for our various types
    
    // sprite sheets
    luaL_newmetatable(L, GEMINI_SPRITE_SHEET_LUA_KEY);
    
    lua_pushvalue(L, -1); // duplicates the metatable
    
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, spriteSheet_m, 0);
    
    lua_pushstring(L,"__gc");
    lua_pushcfunction(L, spriteSheetGC);
    lua_settable(L, -3);
    
    // create the table for this library
    luaL_newlib(L, spriteSheet_f);
    
    return 1;
}
