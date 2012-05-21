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
    GLKTextureInfo *textureInfo;
    GLfloat frameWidth;
    GLfloat frameHeight;
    int framesPerRow;
    int numRows;
}

@property (readonly) NSArray *frames;
@property (readonly) NSString *imageFileName;
@property (readonly) GLKTextureInfo *textureInfo;
@property (readonly) GLfloat frameWidth;
@property (readonly) GLfloat frameHeight;

-(id) initWithImage:(NSString *)imageFileName Data:(NSArray *)data;
-(id)initWithImage:(NSString *)imgFileName FrameWidth:(int)width FrameHeight:(int)height;
-(GLKVector4)texCoordsForFrame:(unsigned int)frame;

-(int) frameCount;

@end
