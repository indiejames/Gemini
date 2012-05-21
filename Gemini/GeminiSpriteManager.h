//
//  GeminiSpriteManager.h
//  Gemini
//
//  Created by James Norton on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeminiSprite.h"

@interface GeminiSpriteManager : NSObject {
    NSMutableArray *sprites;
}

-(void)update:(double)currentTime;
-(void)addSprite:(GeminiSprite *)sprite;
-(void)removeSprite:(GeminiSprite *)sprite;

@end
