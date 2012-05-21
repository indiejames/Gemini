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
@synthesize textureInfo;
@synthesize frameWidth;
@synthesize frameHeight;

static GLKTextureInfo *createTexture(NSString * imgFileName){
    
    NSRange separatorRange = [imgFileName rangeOfString:@"."];
    
    NSString *imgFilePrefix = [imgFileName substringToIndex:separatorRange.location];
    NSString *imgFileSuffix = [imgFileName substringFromIndex:separatorRange.location + 1];
    
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:1];
    [options setValue:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:imgFilePrefix ofType:imgFileSuffix];
    
    GLKTextureInfo *textId = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    assert(textId != nil);
    
    return textId;
}

-(id) initWithImage:(NSString *)imgFileName Data:(NSArray *)data {
    self = [super init];
    
    if (self) {
        
        imageFileName = [[NSString alloc] initWithString:imgFileName];
        textureInfo = [createTexture(imageFileName) retain];
        frames = [[NSArray alloc] initWithArray:data];
        
    }
    
    return self;
}

-(id)initWithImage:(NSString *)imgFileName FrameWidth:(int)width FrameHeight:(int)height {
    
    self = [super init];
    
    if (self) {
        imageFileName = [[NSString alloc] initWithString:imgFileName];
        textureInfo = [createTexture(imageFileName) retain];
        frameWidth = width;
        frameHeight = height;
        framesPerRow = textureInfo.width / frameWidth;
        numRows = textureInfo.height / frameHeight;
    }
        
    
    return self;
}

-(GLfloat)frameWidth:(unsigned int)frameNum {
    if (frames) {
        NSDictionary *frame = (NSDictionary *)[frames objectAtIndex:frameNum];
        
        return [(NSNumber *)[frame valueForKey:@"width"] floatValue];
    } else {
        return frameWidth;
    }

}

-(GLfloat)frameHeight:(unsigned int)frameNum {
    if (frames) {
        NSDictionary *frame = (NSDictionary *)[frames objectAtIndex:frameNum];
        
        return [(NSNumber *)[frame valueForKey:@"height"] floatValue];
    } else {
        return frameHeight;
    }
}

-(GLKVector4)texCoordsForFrame:(unsigned int)frameNum {
    GLfloat imgWidth = textureInfo.width;
    GLfloat imgHeight = textureInfo.height;
    if (frames) {
        NSDictionary *frame = (NSDictionary *)[frames objectAtIndex:frameNum];
        
              
        GLfloat frmWidth = [(NSNumber *)[frame valueForKey:@"width"] floatValue];
        GLfloat frmHeight = [(NSNumber *)[frame valueForKey:@"height"] floatValue];
        GLfloat x = [(NSNumber *)[frame valueForKey:@"x"] floatValue];
        GLfloat y = [(NSNumber *)[frame valueForKey:@"y"] floatValue];
        
        GLfloat x0 = x / imgWidth;
        GLfloat y0 = (imgHeight - y - frmHeight) / imgHeight; // reorient y axis
        GLfloat x1 = x0 + frmWidth / imgWidth;
        GLfloat y1 = y0 + frmHeight / imgHeight;
        
        return GLKVector4Make(x0,y0,x1,y1);
        
    } else {
        unsigned int row = frameNum / framesPerRow;
        unsigned int col = frameNum % framesPerRow;
        GLfloat y0 = (imgHeight - (row + 1) * frameHeight) / imgHeight;
        GLfloat x0 = (col * frameWidth) / imgWidth;
        GLfloat x1 = x0 + frameWidth / imgWidth;
        GLfloat y1 = y0 + frameHeight / imgHeight;
        
        return GLKVector4Make(x0, y0, x1, y1);
    }
}

-(int) frameCount {
    int frameCount = 0;
    if (frames != nil) {
        frameCount = [frames count];
    } else {
        // compute frame count from image size and frame size
        int cols = textureInfo.width / frameWidth;
        int rows = textureInfo.height / frameHeight;
        
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
