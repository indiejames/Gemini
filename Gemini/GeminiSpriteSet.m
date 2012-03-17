//
//  GeminiSpriteSet.m
//  Gemini
//
//  Created by James Norton on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiSpriteSet.h"
#import "GeminiSpriteAnimation.h"

@implementation GeminiSpriteSet

-(id) initWithSpriteSheet:(GeminiSpriteSheet *)sheet StartFrame:(int)start NumFrames:(int)nFrames {
    self = [super init];
    
    if (self) {
        startFrame = start;
        frameCount = nFrames;
        animations = [[NSMutableDictionary alloc] initWithCapacity:1];
        // add a default animation
        GeminiSpriteAnimation *animation = [[[GeminiSpriteAnimation alloc] init] autorelease];
        animation.startFrame = start;
        animation.frameCount = nFrames;
        animation.frameDuration = 0.1; // 10 frames per sec
        animation.loopCount = 0; // no loop
        [animations setObject:animation forKey:@"default"];
    }
    
    return self;
}

-(void) addAnimation:(NSString *)name WithStartFrame:(int)start NumFrames:(int)nFrames FrameDuration:(float)duration LoopCount:(int)loopCount {
    GeminiSpriteAnimation *animation = [[[GeminiSpriteAnimation alloc] init] autorelease];
    animation.startFrame = start;
    animation.frameCount = nFrames;
    animation.frameDuration = duration;
    animation.loopCount = loopCount;
    [animations setObject:animation forKey:name];
}

@end
