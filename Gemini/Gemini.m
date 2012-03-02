//
//  Gemini.m
//  Gemini
//
//  Created by James Norton on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Gemini.h"

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#import "ObjectAL.h"
#import "GeminiEvent.h"
#import "GeminiObject.h"
#import "GeminiGLKViewController.h"

Gemini *singleton = nil;

@interface Gemini () {
@private
    lua_State *L;
    GeminiGLKViewController *viewController;
    int x;
}
@end


@implementation Gemini

@synthesize geminiObjects;
@synthesize viewController;

- (id)init
{
    self = [super init];
    if (self) {
        NSLog(@"Start");
        geminiObjects = [[NSMutableArray alloc] initWithCapacity:1];
        viewController = [[GeminiGLKViewController alloc] init];
        L = luaL_newstate();
        luaL_openlibs(L);
        
        x = 4;
        int y = x * 2;
        NSLog(@"Checked %d", y);
        
    }
    
    return self;
}

+(Gemini *)shared {
    NSLog(@"Shared");
    if (singleton == nil) {
        singleton = [[Gemini alloc] init];
    }
    
    return singleton;
}

-(void)fireTimer {
    GeminiEvent *event = [[GeminiEvent alloc] init];
    event.name = @"timer";
    
}

-(void)execute:(NSString *)filename {
    int err;
    
	lua_settop(L, 0);
    
    NSString *luaFilePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"lua"];
    
    err = luaL_loadfile(L, [luaFilePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	
	if (0 != err) {
        luaL_error(L, "cannot compile lua file: %s",
                   lua_tostring(L, -1));
		return;
	}
    
	
    err = lua_pcall(L, 0, 0, 0);
	if (0 != err) {
		luaL_error(L, "cannot run lua file: %s",
                   lua_tostring(L, -1));
		return;
	}
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(fireTimer) userInfo:nil repeats:YES];
    [timer retain];
}

-(BOOL)handleEvent:(NSString *)event {
    NSLog(@"Gemini hangline event %@", event);
    GeminiEvent *ge = [[GeminiEvent alloc] init];
    ge.name = event;
    
    for (id gemObj in geminiObjects) {
        if ([(GeminiObject *)gemObj handleEvent:ge]) {
            [ge release];
            return YES;
        }
    }
    
    [ge release];
    
    return NO;
}



@end
