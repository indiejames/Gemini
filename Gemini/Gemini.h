//
//  Gemini.h
//  Gemini
//
//  Created by James Norton on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "ObjectAL.h"

@interface Gemini : NSObject

@property (readonly) NSMutableArray *geminiObjects;
@property (readonly) GLKViewController *viewController;

-(void)execute:(NSString *)filename;
-(BOOL)handleEvent:(NSString *)event;
+(Gemini *)shared;

@end
