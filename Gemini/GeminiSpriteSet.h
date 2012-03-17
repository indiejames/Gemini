//
//  GeminiSpriteSet.h
//  Gemini
//
//  Created by James Norton on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeminiSpriteSheet.h"

@interface GeminiSpriteSet : NSObject {
    GeminiSpriteSheet *spriteSheet;
    int startFrame;
    int frameCount;
    NSMutableDictionary *animations;
}


-(id) initWithSpriteSheet:(GeminiSpriteSheet *)sheet StartFrame:(int)start NumFrames:(int)nFrames;

-(void) addAnimation:(NSString *)name WithStartFrame:(int)start NumFrames:(int)nFrames FrameDuration:(float)duration LoopCount:(int)loopCount;

@end
