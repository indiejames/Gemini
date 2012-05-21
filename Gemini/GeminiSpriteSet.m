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

@synthesize spriteSheet;

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
        animation.loopCount = 0; // loop forever
        [animations setObject:animation forKey:GEMINI_DEFAULT_ANIMATION];
        spriteSheet = sheet;
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

-(GeminiSpriteAnimation *)getAnimation:(NSString *)animation {
    return (GeminiSpriteAnimation *)[animations objectForKey:animation];
}

@end
