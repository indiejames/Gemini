//
//  GeminiTransitionManager.h
//  Gemini
//
//  Created by James Norton on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeminiTransistion.h"

@interface GeminiTransitionManager : NSObject {
    NSMutableArray *transitions;
}

-(void) addTransition:(GeminiTransistion *)trans;
-(void)removeTransition:(GeminiTransistion *)trans;
-(void)processTransitions:(double)secondsSinceLastUpdate;

+(GeminiTransitionManager *)shared;

@end
