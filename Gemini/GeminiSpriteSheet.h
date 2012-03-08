//
//  GeminiSpriteSheet.h
//  Gemini
//
//  Created by James Norton on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface GeminiSpriteSheet : NSObject {
    NSArray *frames;
    NSString *imageFileName;
    GLKTextureInfo *texInfo;
    int frameWidth;
    int frameHeight;
}

@property (readonly) NSArray *frames;
@property (readonly) NSString *imageFileName;

-(id) initWithImage:(NSString *)imageFileName Data:(NSArray *)data;
-(id)initWithImage:(NSString *)imgFileName FrameWidth:(int)width FrameHeight:(int)height;

-(int) frameCount;

@end
