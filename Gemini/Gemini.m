//
//  Gemini.m
//  Gemini
//
//  Created by James Norton on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Gemini.h"


#import "ObjectAL.h"
#import "GeminiEvent.h"
#import "GeminiObject.h"
#import "GeminiGLKViewController.h"
#import "GeminiDisplayObject.h"

Gemini *singleton = nil;

@interface Gemini () {
@private
    lua_State *L;
    GeminiGLKViewController *viewController;
    int x;
    double initTime;
}
@end


@implementation Gemini

//@synthesize L;
@synthesize geminiObjects;
@synthesize viewController;
@synthesize initTime;

int setLuaPath(lua_State *L, NSString* path );


- (id)init
{
    
   /* GeminiDisplayObject *dob = [[GeminiDisplayObject alloc] init];
    dob.x = 10.0;
    dob.y = 10.0;
    dob.rotation = M_PI / 2.0;
    GLKVector4 vec = GLKVector4Make(dob.x, dob.y, 0, 1.0);
    GLKVector4 vec2 = GLKMatrix4MultiplyVector4(dob.transform, vec);
    NSLog(@"vec2 = (%f,%f,%f)", vec2.x,vec2.y,vec2.z);*/
    
    self = [super init];
    if (self) {
        initTime = [NSDate timeIntervalSinceReferenceDate];
        geminiObjects = [[NSMutableArray alloc] initWithCapacity:1];
        viewController = [[GeminiGLKViewController alloc] init];
        L = luaL_newstate();
        luaL_openlibs(L);
        
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
  
    setLuaPath(L, [luaFilePath stringByDeletingLastPathComponent]);
    
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
    NSLog(@"Gemini handling event %@", event);
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

// makes it possible for Lua to load files on iOS
int setLuaPath(lua_State *L, NSString* path )  
{
    lua_getglobal( L, "package" );
    lua_getfield( L, -1, "path" ); // get field "path" from table at top of stack (-1)
    NSString * cur_path = [NSString stringWithUTF8String:lua_tostring( L, -1 )]; // grab path string from top of stack
    cur_path = [cur_path stringByAppendingString:@";"]; // do your path magic here
    cur_path = [cur_path stringByAppendingString:path];
    cur_path = [cur_path stringByAppendingString:@"/?.lua"];
    cur_path = [cur_path stringByAppendingString:@";"];
    cur_path = [cur_path stringByAppendingString:path];
    cur_path = [cur_path stringByAppendingString:@"/?"];
    lua_pop( L, 1 ); // get rid of the string on the stack we just pushed on line 5
    lua_pushstring( L, [cur_path UTF8String]); // push the new one
    lua_setfield( L, -2, "path" ); // set the field "path" in table at -2 with value at top of stack
    lua_pop( L, 1 ); // get rid of package table from top of stack
    return 0; // all done!
}



@end
