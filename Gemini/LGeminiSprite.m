//
//  LGeminiSprite.m
//  Gemini
//
//  Created by James Norton on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LGeminiSprite.h"
#import "Gemini.h"
#import "GeminiSprite.h"
#import "GeminiSpriteSheet.h"
#import "GeminiSpriteSet.h"
#import "GeminiSpriteAnimation.h"
#import "GeminiGLKViewController.h"
#import "LGeminiLuaSupport.h"

// prototype for library init function
int luaopen_spritelib (lua_State *L);



////////// Sprites //////////////////////
static int newSprite(lua_State *L){
    GeminiSpriteSet  **ss = (GeminiSpriteSet **)luaL_checkudata(L, 1, GEMINI_SPRITE_SET_LUA_KEY);
    GeminiSprite *sprite = [[GeminiSprite alloc] initWithLuaState:L SpriteSet:*ss];
    [((GeminiGLKViewController *)([Gemini shared].viewController)).spriteManager addSprite:sprite];
    GeminiSprite **lSprite = (GeminiSprite **)lua_newuserdata(L, sizeof(GeminiSprite *));
    *lSprite = sprite;
    
    
    luaL_getmetatable(L, GEMINI_SPRITE_LUA_KEY);
    lua_setmetatable(L, -2);
    
    // append a lua table to this user data to allow the user to store values in it
    lua_newtable(L);
    lua_pushvalue(L, -1); // make a copy of the table becaue the next line pops the top value
    // store a reference to this table so our sprite methods can access it
    sprite.propertyTableRef = luaL_ref(L, LUA_REGISTRYINDEX);
    // set the table as the user value for the Lua object
    lua_setuservalue(L, -2);
    
    lua_pushvalue(L, -1); // make another copy of the userdata since the next line will pop it off
    sprite.selfRef = luaL_ref(L, LUA_REGISTRYINDEX);
    
    return 1;
}

static int spriteGC (lua_State *L){
    GeminiSprite  **s = (GeminiSprite **)luaL_checkudata(L, 1, GEMINI_SPRITE_LUA_KEY);
    
    [*s release];
    
    return 0;
}

static int spriteIndex( lua_State* L )
{
    NSLog(@"Calling spriteIndex()");
    /* object, key */
    /* first check the environment */ 
    lua_getuservalue( L, -2 );
    if(lua_isnil(L,-1)){
        NSLog(@"user value for user data is nil");
    }
    lua_pushvalue( L, -2 );
    
    lua_rawget( L, -2 );
    if( lua_isnoneornil( L, -1 ) == 0 )
    {
        return 1;
    }
    
    lua_pop( L, 2 );
    
    /* second check the metatable */    
    lua_getmetatable( L, -2 );
    lua_pushvalue( L, -2 );
    lua_rawget( L, -2 );
    
    /* nil or otherwise, we return here */
    return 1;
}

static int spriteNewIndex (lua_State *L){
    int rval = 0;
    GeminiSprite  **sprite = (GeminiSprite **)luaL_checkudata(L, 1, GEMINI_SPRITE_LUA_KEY);
    
    if (sprite != NULL) {
        if (lua_isstring(L, 2)) {
            
            
            rval = genericNewIndex(L, sprite);
                        
        }
        
        
    }
    
    
    return rval;
}

static int spritePrepare(lua_State *L){
    GeminiSprite  **sprite = (GeminiSprite **)luaL_checkudata(L, 1, GEMINI_SPRITE_LUA_KEY);
    
    int numargs = lua_gettop(L);
    if (numargs > 1) {
        const char *animation = luaL_checkstring(L, 2);
        NSString *animStr = [NSString stringWithCString:animation encoding:NSUTF8StringEncoding];
        [*sprite prepareAnimation:animStr];
    } else {
        [*sprite prepare];
    }
    
    return 0;
}

static int spritePlay(lua_State *L){
    GeminiSprite  **sprite = (GeminiSprite **)luaL_checkudata(L, 1, GEMINI_SPRITE_LUA_KEY);
    [*sprite play:((GeminiGLKViewController *)([Gemini shared].viewController)).updateTime];
    
    return 0;
}

static int spritePause(lua_State *L){
    GeminiSprite  **sprite = (GeminiSprite **)luaL_checkudata(L, 1, GEMINI_SPRITE_LUA_KEY);
    [*sprite pause:((GeminiGLKViewController *)([Gemini shared].viewController)).updateTime];
    
    return 0;
}

////////// Sprite Sets //////////////////

static int newSpriteSet(lua_State *L){
    GeminiSpriteSheet **ss = (GeminiSpriteSheet **)luaL_checkudata(L, 1, GEMINI_SPRITE_SHEET_LUA_KEY);
    int startFrame = luaL_checkint(L, 2);
    int frameCount = luaL_checkint(L, 3);
    GeminiSpriteSet *spriteSet = [[GeminiSpriteSet alloc] initWithSpriteSheet:*ss StartFrame:startFrame NumFrames:frameCount];
    
    GeminiSpriteSet **lSet = (GeminiSpriteSet **)lua_newuserdata(L, sizeof(GeminiSpriteSet *));
    *lSet = spriteSet;
    
    luaL_getmetatable(L, GEMINI_SPRITE_SET_LUA_KEY);
    lua_setmetatable(L, -2);
    
    return 1;
    
}

// this is a library method not a sprite set object method
static int addAnimation (lua_State *L){
    GeminiSpriteSet  **ss = (GeminiSpriteSet **)luaL_checkudata(L, 1, GEMINI_SPRITE_SET_LUA_KEY);
    const char *name = luaL_checkstring(L, 2);
    int startFrame = luaL_checkint(L, 3);
    int frameCount = luaL_checkint(L, 4);
    double duration = luaL_checknumber(L, 5);
    int loopCount = luaL_checkint(L, 6);
    
    [*ss addAnimation:[NSString stringWithFormat:@"%s",name] WithStartFrame:startFrame NumFrames:frameCount FrameDuration:duration LoopCount:loopCount];
    
    return 1;
}

static int spriteSetGC (lua_State *L){
    GeminiSpriteSet  **ss = (GeminiSpriteSet **)luaL_checkudata(L, 1, GEMINI_SPRITE_SET_LUA_KEY);
    
    [*ss release];
    
    return 0;
}

///////// Sprite Sheets //////////////////

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

// the mappings for the library functions
static const struct luaL_Reg spriteLib_f [] = {
    {"newSpriteSheet", newSpriteSheet},
    {"newSpriteSheetFromData", newSpriteSheetFromData},
    {"newSpriteSet", newSpriteSet},
    {"newSprite", newSprite},
    {"add", addAnimation},
    {NULL, NULL}
};

// mappings for the sprite sheet methods
static const struct luaL_Reg spriteSheet_m [] = {
    {"frameCount", spriteSheetFrameCount},
    {"__gc", spriteSheetGC},
    {NULL, NULL}
};

// mappings for the sprite set methods
static const struct luaL_Reg spriteSet_m [] = {
    {"__gc", spriteSetGC},
    {NULL, NULL}
};

// mappings for the sprite methods
static const struct luaL_Reg sprite_m [] = {
    {"__gc", spriteGC},
    {"__index", spriteIndex},
    {"__newindex", spriteNewIndex},
    {"prepare", spritePrepare},
    {"play", spritePlay},
    {"pause", spritePlay},
    {NULL, NULL}
};


int luaopen_spritelib (lua_State *L){
    // create meta tables for our various types /////////
    
    // sprite sheets
    luaL_newmetatable(L, GEMINI_SPRITE_SHEET_LUA_KEY);
    
    lua_pushvalue(L, -1); // duplicates the metatable
    
    lua_setfield(L, -2, "__index"); // make the metatable use itself for __index
    
    luaL_setfuncs(L, spriteSheet_m, 0);

    
    // sprite sets
    luaL_newmetatable(L, GEMINI_SPRITE_SET_LUA_KEY);
    lua_pushvalue(L, -1); // duplicates the metatable
    
    lua_setfield(L, -2, "__index"); // make the metatable use itself for __index
    luaL_setfuncs(L, spriteSet_m, 0);
    
    //lua_pushstring(L,"__gc");
    //lua_pushcfunction(L, spriteSetGC);
    //lua_settable(L, -3);
    
    // sprites
    luaL_newmetatable(L, GEMINI_SPRITE_LUA_KEY);
    lua_pushvalue(L, -1);
    
    luaL_setfuncs(L, sprite_m, 0);
    
    /////// finished with metatables ///////////
    
    // create the table for this library and popuplate it with our functions
    luaL_newlib(L, spriteLib_f);
    
    return 1;
}
