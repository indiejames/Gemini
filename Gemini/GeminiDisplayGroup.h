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
}

@property (readonly) NSArray *objects;

-(void)remove:(GeminiDisplayObject *) obj;
-(void)recomputeWidthHeight;
-(void)insert:(GeminiDisplayObject *) obj;
-(void)insert:(GeminiDisplayObject *)obj atIndex:(int)indx;

@end
