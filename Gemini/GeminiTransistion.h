//
//  GeminiTransistion.h
//  Gemini
//
//  Created by James Norton on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeminiDisplayObject.h"

@interface GeminiTransistion : NSObject {
    double elapsedTime;
    double duration;
    double delay;
    
    NSMutableDictionary *finalParamValues;
    NSMutableDictionary *initialParamValues;

    GeminiDisplayObject *obj;
}

-(id)initWithObject:(GeminiDisplayObject *)object Data:(NSDictionary *)data To:(BOOL)to;
-(void)update:(double)secondsSinceLastUpdate;
-(BOOL)isActive;

@end
