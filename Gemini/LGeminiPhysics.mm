//
//  LGeminiPhysics.m
//  Gemini
//
//  Created by James Norton on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LGeminiPhysics.h"

int luaopen_physics_lib(lua_State *L);

static b2World *world;


static int newBody(lua_State *L){
    // TODO - implement this
    
    return 1;
}

static int newIndex(lua_State *L){
    return genericIndex(L);
}

// the mappings for the library functions
static const struct luaL_Reg physicsLib_f [] = {
    {"newBody", newBody},
    {NULL, NULL}
};

// mappings for the layer methods
static const struct luaL_Reg physics_m [] = {
    {"__index", genericIndex},
    {"__newindex", newIndex},
    {NULL, NULL}
};


int luaopen_physics_lib (lua_State *L){
    // create meta table for our physics type /////////
    createMetatable(L, GEMINI_PHYSICS_LUA_KEY, physics_m);
       
    // create the table for this library and popuplate it with our functions
    luaL_newlib(L, physicsLib_f);
    
    b2Vec2 gravity(0.0f, -10.0f); 
    bool doSleep = true;
    world = new b2World(gravity);
    world->SetAllowSleeping(doSleep);
    
    b2BodyDef groundBodyDef; 
    groundBodyDef.position.Set(0.0f, -10.0f);
    
    b2Body* groundBody = world->CreateBody(&groundBodyDef);
    
    b2PolygonShape groundBox; 
    groundBox.SetAsBox(50.0f, 10.0f);
    
    groundBody->CreateFixture(&groundBox, 0.0f);
    
    return 1;
}

