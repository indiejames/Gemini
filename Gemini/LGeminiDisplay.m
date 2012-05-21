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

#import "GeminiLine.h"
#import "GeminiRectangle.h"
#import "GeminiGLKViewController.h"


// used to set common defaults for all display objects
// this function expects a table to be the top item on the stack
static void setDefaultValues(lua_State *L) {
    assert(lua_type(L, -1) == LUA_TTABLE);
    lua_pushstring(L, "x");
    lua_pushnumber(L, 0);
    lua_settable(L, -3);

    lua_pushstring(L, "y");
    lua_pushnumber(L, 0);
    lua_settable(L, -3);
    
    lua_pushstring(L, "xOrigin");
    lua_pushnumber(L, 0);
    lua_settable(L, -3);
    
    lua_pushstring(L, "yOrigin");
    lua_pushnumber(L, 0);
    lua_settable(L, -3);
    
    lua_pushstring(L, "xReference");
    lua_pushnumber(L, 0);
    lua_settable(L, -3);
    
    lua_pushstring(L, "yReference");
    lua_pushnumber(L, 0);
    lua_settable(L, -3);
    
}

// generic init method
static void setupObject(lua_State *L, const char *luaKey, GeminiDisplayObject *obj){
    
    luaL_getmetatable(L, luaKey);
    lua_setmetatable(L, -2);
    
    // append a lua table to this user data to allow the user to store values in it
    lua_newtable(L);
    lua_pushvalue(L, -1); // make a copy of the table becaue the next line pops the top value
    // store a reference to this table so our sprite methods can access it
    obj.propertyTableRef = luaL_ref(L, LUA_REGISTRYINDEX);
    
    // add in some default values
    setDefaultValues(L);
    
    // set the table as the user value for the Lua object
    lua_setuservalue(L, -2);
    
    lua_pushvalue(L, -1); // make another copy of the userdata since the next line will pop it off
    obj.selfRef = luaL_ref(L, LUA_REGISTRYINDEX);
}

// generic index method for userdata types
static int genericIndex(lua_State *L){
    /* first check the environment */ 
    lua_getuservalue( L, -2 );
    if(lua_isnil(L,-1)){
        // NSLog(@"user value for user data is nil");
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

// generic indexing for GeminiObjects
static int genericGeminiDisplayObjectIndex(lua_State *L, GeminiDisplayObject *obj){
    if (lua_isstring(L, -1)) {
        
        
        const char *key = lua_tostring(L, -1);
        if (strcmp("xReference", key) == 0) {
            
            GLfloat xRef = obj.xReference;
            lua_pushnumber(L, xRef);
            return 1;
        } else if (strcmp("yReference", key) == 0) {
            
            GLfloat yref = obj.yReference;
            lua_pushnumber(L, yref);
            return 1;
            
        } else if (strcmp("xOrigin", key) == 0) {
            
            GLfloat xOrig = obj.xOrigin;
            lua_pushnumber(L, xOrig);
            return 1;
        } else if (strcmp("yOrigin", key) == 0) {
            
            GLfloat yOrig = obj.yOrigin;
            lua_pushnumber(L, yOrig);
            return 1;
            
        } else if (strcmp("x", key) == 0) {
            
            GLfloat x = obj.x;
            lua_pushnumber(L, x);
            return 1;
            
        } else if (strcmp("y", key) == 0) {
            
            GLfloat y = obj.y;
            lua_pushnumber(L, y);
            return 1;
            
        } else if (strcmp("rotation", key) == 0) {
            
            GLfloat rot = obj.rotation;
            lua_pushnumber(L, rot);
            return 1;
            
        } else {
            return genericIndex(L);
        }
        
    }
    
    return 0;
    
}

// generic new index method for userdata types
static int genericNewIndex(lua_State *L, GeminiDisplayObject **obj){
    
    if (lua_isstring(L, 2)) {
        
        if (obj != NULL) {
            const char *key = lua_tostring(L, 2);
            if (strcmp("xReference", key) == 0) {
                
                GLfloat xref = luaL_checknumber(L, 3);
                [*obj setXReference:xref];
                return 0;
                
            } else if (strcmp("yReference", key) == 0) {
                
                GLfloat yref = luaL_checknumber(L, 3);
                [*obj setYReference:yref];
                return 0;
                
            } else if (strcmp("x", key) == 0) {
                
                GLfloat x = luaL_checknumber(L, 3);
                [*obj setX:x];
                return 0;
                
            } else if (strcmp("y", key) == 0) {
                
                GLfloat yref = luaL_checknumber(L, 3);
                [*obj setYReference:yref];
                return 0;
                
            } else if (strcmp("rotation", key) == 0) {
                
                GLfloat rot = luaL_checknumber(L, 3);
                [*obj setRotation:rot];
                return 0;
                
            } else if (strcmp("xScale", key) == 0){
                GLfloat xScale = luaL_checknumber(L, 3);
                [*obj setXScale:xScale];
                
                return 0;
                
            } else if (strcmp("yScale", key) == 0){
                GLfloat yScale = luaL_checknumber(L, 3);
                [*obj setYScale:yScale];
                return 0;
                
            }
            
        }
    } 
    
    lua_getuservalue( L, -3 );
    /* object, key, value */
    lua_pushvalue(L, -3);
    lua_pushvalue(L,-3);
    lua_rawset( L, -3 );
    
    return 0;

}


///////////// rectangles //////////////////////
static int newRectangle(lua_State *L){
    NSLog(@"Creating new rectangle");
    GLfloat x = luaL_checknumber(L, 1);
    GLfloat y = luaL_checknumber(L, 2);
    GLfloat width = luaL_checknumber(L, 3);
    GLfloat height = luaL_checknumber(L, 4);

    GeminiRectangle *rect = [[GeminiRectangle alloc] initWithLuaState:L X:x Y:y Width:width Height:height];
    [((GeminiGLKViewController *)([Gemini shared].viewController)).renderer addObject:rect];
    GeminiRectangle **lRect = (GeminiRectangle **)lua_newuserdata(L, sizeof(GeminiRectangle *));
    *lRect = rect;
    
    setupObject(L, GEMINI_RECTANGLE_LUA_KEY, rect);
    
    //rect.x = width / 2.0;
    //rect.y = height / 2.0;
    rect.width = width;
    rect.height = height;
    
    return 1;
}

static int rectangleGC (lua_State *L){
    NSLog(@"rectangleGC called");
    GeminiRectangle  **rect = (GeminiRectangle **)luaL_checkudata(L, 1, GEMINI_RECTANGLE_LUA_KEY);
    [(*rect).parent remove:*rect];
    //[*rect release];
    
    return 0;
}

static int rectangleIndex(lua_State *L){
    int rval = 0;
    GeminiRectangle  **rect = (GeminiRectangle **)luaL_checkudata(L, 1, GEMINI_RECTANGLE_LUA_KEY);
    if (rect != NULL) {
        if (lua_isstring(L, -1)) {
            
            
            const char *key = lua_tostring(L, -1);
            if (strcmp("strokeWidth", key) == 0) {
                
                GLfloat w = (*rect).strokeWidth;
                lua_pushnumber(L, w);
                return 1;
            } else {
                rval = genericGeminiDisplayObjectIndex(L, *rect);
            }
        }
        
        
    }
    
    return rval;
}

static int rectangleNewIndex (lua_State *L){
    int rval = 0;
    GeminiRectangle  **rect = (GeminiRectangle **)luaL_checkudata(L, 1, GEMINI_RECTANGLE_LUA_KEY);
    
    if (rect != NULL) {
        if (lua_isstring(L, 2)) {
            
            
            const char *key = lua_tostring(L, 2);
            if (strcmp("strokeWidth", key) == 0) {
                GLfloat w = luaL_checknumber(L, 3);
                (*rect).strokeWidth = w;
                rval = 0;
            } else {
                //lua_pushstring(L, key);
                rval = genericNewIndex(L, rect);
            }

        }
        
        
    }
    
    
    return rval;
}

static int rectangleSetFillColor(lua_State *L){
    NSLog(@"Setting rectangle fill color");
    int numargs = lua_gettop(L);
    
    GeminiRectangle  **rect = (GeminiRectangle **)luaL_checkudata(L, 1, GEMINI_RECTANGLE_LUA_KEY);
    
    GLfloat red = luaL_checknumber(L, 2);
    GLfloat green = luaL_checknumber(L, 3);
    GLfloat blue = luaL_checknumber(L, 4);
    GLfloat alpha = 1.0;
    if (numargs == 5) {
        alpha = luaL_checknumber(L, 5);
    }
    
    (*rect).fillColor = GLKVector4Make(red, green, blue, alpha);
    
    
    return 0;
}

static int rectangleSetStrokeColor(lua_State *L){
    NSLog(@"Setting rectangle stroke color");
    int numargs = lua_gettop(L);
    
    GeminiRectangle  **rect = (GeminiRectangle **)luaL_checkudata(L, 1, GEMINI_RECTANGLE_LUA_KEY);
    
    GLfloat red = luaL_checknumber(L, 2);
    GLfloat green = luaL_checknumber(L, 3);
    GLfloat blue = luaL_checknumber(L, 4);
    GLfloat alpha = 1.0;
    if (numargs == 5) {
        alpha = luaL_checknumber(L, 5);
    }
    
    (*rect).strokeColor = GLKVector4Make(red, green, blue, alpha);
    
    
    return 0;
}

static int rectangleSetStrokeWidth(lua_State *L){
    NSLog(@"Setting rectangle stroke width");
   
    GeminiRectangle  **rect = (GeminiRectangle **)luaL_checkudata(L, 1, GEMINI_RECTANGLE_LUA_KEY);
    
    GLfloat w = luaL_checknumber(L, 2);
        
    (*rect).strokeWidth = w;
    
    
    return 0;
}

///////////// lines ///////////////////////////
static int newLine(lua_State *L){
    NSLog(@"Creating new line...");
    GLfloat x1 = luaL_checknumber(L, 1);
    GLfloat y1 = luaL_checknumber(L, 2);
    GLfloat x2 = luaL_checknumber(L, 3);
    GLfloat y2 = luaL_checknumber(L, 4);
    NSLog(@"(x1,y1,x2,y2)=(%f,%f,%f,%f)",x1,y1,x2,y2);
    GeminiLine *line = [[GeminiLine alloc] initWithLuaState:L X1:x1 Y1:y1 X2:x2 Y2:y2];
    [((GeminiGLKViewController *)([Gemini shared].viewController)).renderer addObject:line];
    GeminiLine **lLine = (GeminiLine **)lua_newuserdata(L, sizeof(GeminiLine *)); 
    *lLine = line;
    
    setupObject(L, GEMINI_LINE_LUA_KEY, line);
    
    line.xOrigin = x1;
    line.yOrigin = y1;

    
    return 1;
}

static int lineGC (lua_State *L){
    NSLog(@"lineGC called");
    GeminiLine  **line = (GeminiLine **)luaL_checkudata(L, 1, GEMINI_LINE_LUA_KEY);
    [(*line).parent remove:*line];
    //[*line release];
    
    return 0;
}

static int lineIndex(lua_State *L){
    int rval = 0;
    GeminiLine  **line = (GeminiLine **)luaL_checkudata(L, 1, GEMINI_LINE_LUA_KEY);
    if (line != NULL) {
        
        rval = genericGeminiDisplayObjectIndex(L, *line);
        
    }
    
    return rval;
}

static int lineNewIndex (lua_State *L){
    GeminiLine  **line = (GeminiLine **)luaL_checkudata(L, 1, GEMINI_LINE_LUA_KEY);
    return genericNewIndex(L, line);
}

static int lineSetColor(lua_State *L){
    NSLog(@"Setting line color");
    int numargs = lua_gettop(L);
    
    GeminiLine  **line = (GeminiLine **)luaL_checkudata(L, 1, GEMINI_LINE_LUA_KEY);
    
    GLfloat red = luaL_checknumber(L, 2);
    GLfloat green = luaL_checknumber(L, 3);
    GLfloat blue = luaL_checknumber(L, 4);
    GLfloat alpha = 1.0;
    if (numargs == 5) {
        alpha = luaL_checknumber(L, 5);
    }
    (*line).color = GLKVector4Make(red, green, blue, alpha);
    
    return 0;
}

static int lineAppendPoints(lua_State *L){
    NSLog(@"Appending points to line");
    int numargs = lua_gettop(L);
    
    GeminiLine  **line = (GeminiLine **)luaL_checkudata(L, 1, GEMINI_LINE_LUA_KEY);
    
    GLfloat *newPoints = (GLfloat *)malloc((numargs - 1)*sizeof(GLfloat));
    
    for (int i=0; i<(numargs - 1)/2; i++) {
        *(newPoints + i*2) = luaL_checknumber(L, i*2 + 2);
        *(newPoints + i*2 + 1) = luaL_checknumber(L, i*2 + 3);
    }
    
    [*line append:(numargs - 1)/2 Points:newPoints];
    
    free(newPoints);
    
    return 0;
}

///////////// layers //////////////////
static int newLayer(lua_State *L){
    int index = luaL_checkinteger(L, 1);
    
    GeminiLayer *layer = [[GeminiLayer alloc] initWithLuaState:L];
    layer.index = index;
    GeminiLayer **lLayer = (GeminiLayer **)lua_newuserdata(L, sizeof(GeminiLayer *));
    *lLayer = layer;
    GeminiRenderer *renderer = ((GeminiGLKViewController *)([Gemini shared].viewController)).renderer;
    [renderer addLayer:layer];

    setupObject(L, GEMINI_LAYER_LUA_KEY, layer);
    
    return 1;
}

static int layerGC (lua_State *L){
    GeminiLayer  **layer = (GeminiLayer **)luaL_checkudata(L, 1, GEMINI_LAYER_LUA_KEY);
    
    [*layer release];
    
    return 0;
}

GeminiLayer *createLayerZero(lua_State *L) {
    GeminiLayer *layer = [[GeminiLayer alloc] initWithLuaState:L];
    layer.index = 0;
    GeminiLayer **lLayer = (GeminiLayer **)lua_newuserdata(L, sizeof(GeminiLayer *));
    *lLayer = layer;
    
    //GeminiRenderer *renderer = ((GeminiGLKViewController *)([Gemini shared].viewController)).renderer;
    //[renderer addLayer:layer];

    setupObject(L, GEMINI_LAYER_LUA_KEY, layer);
    
    // add layer zero to the global vars for Lua
    lua_setglobal(L, "GEMINI_LAYER0");
    
    return layer;
}

static int layerNewIndex (lua_State *L){
    GeminiLayer  **layer = (GeminiLayer **)luaL_checkudata(L, 1, GEMINI_LAYER_LUA_KEY);
    return genericNewIndex(L, layer);
}


static int layerInsert(lua_State *L){
    NSLog(@"Calling layerInsert()");
    GeminiLayer  **layer = (GeminiLayer **)luaL_checkudata(L, 1, GEMINI_LAYER_LUA_KEY); 
    GeminiDisplayObject **displayObj = (GeminiDisplayObject **)lua_touserdata(L, 2);
    [*layer insert:*displayObj];
    
    return 0;
}

static int layerSetBlendFunc(lua_State *L){
    NSLog(@"Calling layerSetBlendFunc()");
    GeminiLayer  **layer = (GeminiLayer **)luaL_checkudata(L, 1, GEMINI_LAYER_LUA_KEY); 
    GLenum srcBlend = luaL_checkinteger(L, 2);
    GLenum destBlend = luaL_checkinteger(L, 3);
    [*layer setBlendFuncSource:srcBlend Dest:destBlend];
    
    return 0;
}

///////////// display groups //////////////////
static int newDisplayGroup(lua_State *L){
    GeminiDisplayGroup *group = [[GeminiDisplayGroup alloc] initWithLuaState:L];
    GeminiDisplayGroup **lGroup = (GeminiDisplayGroup **)lua_newuserdata(L, sizeof(GeminiDisplayGroup *));
    *lGroup = group;
   [((GeminiGLKViewController *)([Gemini shared].viewController)).renderer addObject:group];

    setupObject(L, GEMINI_DISPLAY_GROUP_LUA_KEY, group);
    
    return 1;
}

static int displayGroupGC (lua_State *L){
    GeminiDisplayGroup  **group = (GeminiDisplayGroup **)luaL_checkudata(L, 1, GEMINI_DISPLAY_GROUP_LUA_KEY);
    
    [*group release];
    
    return 0;
}

static int displayGroupNewIndex (lua_State *L){
    GeminiDisplayGroup  **dg = (GeminiDisplayGroup **)luaL_checkudata(L, 1, GEMINI_DISPLAY_GROUP_LUA_KEY);
    return genericNewIndex(L, dg);
}

static int displayGroupInsert(lua_State *L){
     NSLog(@"Calling displayGroupInsert()");
   GeminiDisplayGroup  **group = (GeminiDisplayGroup **)luaL_checkudata(L, 1, GEMINI_DISPLAY_GROUP_LUA_KEY); 
    GeminiDisplayObject **displayObj = (GeminiDisplayObject **)lua_touserdata(L, 2);
    [*group insert:*displayObj];
    
    return 0;
}



// the mappings for the library functions
static const struct luaL_Reg displayLib_f [] = {
    {"newLayer", newLayer},
    {"newGroup", newDisplayGroup},
    {"newLine", newLine},
    {"newRect", newRectangle},
    {NULL, NULL}
};

// mappings for the layer methods
static const struct luaL_Reg layer_m [] = {
    {"insert", layerInsert},
    {"setBlendFunc", layerSetBlendFunc},
    {"__gc", layerGC},
    {"__index", genericIndex},
    {"__newindex", layerNewIndex},
    {NULL, NULL}
};

// mappings for the display group methods
static const struct luaL_Reg displayGroup_m [] = {
    {"insert", displayGroupInsert},
    {"__gc", displayGroupGC},
    {"__index", genericIndex},
    {"__newindex", displayGroupNewIndex},
    {NULL, NULL}
};

// mappings for the line methods
static const struct luaL_Reg line_m [] = {
    {"__gc", lineGC},
    {"__index", lineIndex},
    {"__newindex", lineNewIndex},
    {"setColor", lineSetColor},
    {"append", lineAppendPoints},
    {NULL, NULL}
};

// mappings for the rectangle methods
static const struct luaL_Reg rectangle_m [] = {
    {"__gc", rectangleGC},
    {"__index", rectangleIndex},
    {"__newindex", rectangleNewIndex},
    {"setFillColor", rectangleSetFillColor},
    {"setStrokeColor", rectangleSetStrokeColor},
    {"setStrokeWidth", rectangleSetStrokeWidth},
    {NULL, NULL}
};


static void createMetatable(lua_State *L, const char *key, const struct luaL_Reg *funcs){
    luaL_newmetatable(L, key);    
    lua_pushvalue(L, -1); // duplicates the metatable
    luaL_setfuncs(L, funcs, 0);
}

int luaopen_display_lib (lua_State *L){
    // create meta tables for our various types /////////
    
    // layers
    createMetatable(L, GEMINI_LAYER_LUA_KEY, layer_m);
    
    // display groups
    createMetatable(L, GEMINI_DISPLAY_GROUP_LUA_KEY, displayGroup_m);
   
    
    // lines
    createMetatable(L, GEMINI_LINE_LUA_KEY, line_m);
   
    // rectangles
    createMetatable(L, GEMINI_RECTANGLE_LUA_KEY, rectangle_m);
    
    /////// finished with metatables ///////////
    
    // create the table for this library and popuplate it with our functions
    luaL_newlib(L, displayLib_f);
    
    return 1;
}