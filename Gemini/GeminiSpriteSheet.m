//
//  GeminiSpriteSheet.m
//  Gemini
//
//  Created by James Norton on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiSpriteSheet.h"


@implementation GeminiSpriteSheet
@synthesize frames;
@synthesize imageFileName;


static GLKTextureInfo *createTexture(NSString * imgFileName){
    
    NSRange separatorRange = [imgFileName rangeOfString:@"."];
    
    NSString *imgFilePrefix = [imgFileName substringToIndex:separatorRange.location];
    NSString *imgFileSuffix = [imgFileName substringFromIndex:separatorRange.location + 1];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:imgFilePrefix ofType:imgFileSuffix];
    
    GLKTextureInfo *textId = [GLKTextureLoader textureWithContentsOfFile:filePath options:nil error:nil];
    
    assert(textId != nil);
    
    return textId;
}

-(id) initWithImage:(NSString *)imgFileName Data:(NSArray *)data {
    self = [super init];
    
    if (self) {
        
        imageFileName = [[NSString alloc] initWithString:imgFileName];
        texInfo = createTexture(imageFileName);
        frames = [[NSArray alloc] initWithArray:data];
        
    }
    
    return self;
}

-(id)initWithImage:(NSString *)imgFileName FrameWidth:(int)width FrameHeight:(int)height {
    assert(frameHeight > 0);
    assert(frameWidth > 0);
    
    self = [super init];
    
    if (self) {
        imageFileName = [[NSString alloc] initWithString:imgFileName];
        texInfo = createTexture(imageFileName);
        frameWidth = width;
        frameHeight = height;
    }
        
    
    return self;
}

-(int) frameCount {
    int frameCount = 0;
    if (frames != nil) {
        frameCount = [frames count];
    } else {
        // compute frame count from image size and frame size
        int cols = texInfo.width / frameWidth;
        int rows = texInfo.height / frameHeight;
        
        frameCount = cols * rows;
    }
    
    return frameCount;
}

-(void)dealloc {
    [imageFileName release];
    [frames release];
    [super dealloc];
}

@end
