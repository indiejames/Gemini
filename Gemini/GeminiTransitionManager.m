//
//  GeminiTransitionManager.m
//  Gemini
//
//  Created by James Norton on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiTransitionManager.h"

GeminiTransitionManager *geminiTransistionManagerSingleton = nil;

@implementation GeminiTransitionManager

-(id) init {
    self = [super init];
    
    if (self) {
        transitions = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    return self;
}

-(void) dealloc {
    [transitions release];
    
    [super dealloc];
}

-(void) addTransition:(GeminiTransistion *)trans {
    [transitions addObject:trans];
}

-(void)removeTransition:(GeminiTransistion *)trans {
    [transitions removeObject:trans];
}

-(void)processTransitions:(double)secondsSinceLastUpdate {
    for (int i=[transitions count]-1; i>=0; i--) {
        GeminiTransistion *transition = [transitions objectAtIndex:i];
        [transition update:secondsSinceLastUpdate];
        if (![transition isActive]) {
            [transitions removeObjectAtIndex:i];
        }
    }
}

+(GeminiTransitionManager *)shared {
    if (geminiTransistionManagerSingleton == nil) {
        geminiTransistionManagerSingleton = [[GeminiTransitionManager alloc] init];
    }
    
    return geminiTransistionManagerSingleton;
}

@end

