//
//  GeminiDisplayGroup.h
//  Gemini
//
//  Created by James Norton on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiDisplayObject.h"

@interface GeminiDisplayGroup : GeminiDisplayObject {
    NSMutableArray *objects;
    GLuint layer;
}

@property (readonly) NSArray *objects;
@property GLuint layer;

-(void)insert:(GeminiDisplayObject *) obj;
-(void)remove:(GeminiDisplayObject *) obj;

@end
