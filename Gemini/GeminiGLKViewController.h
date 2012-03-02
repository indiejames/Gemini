//
//  GeminiGLKViewController.h
//  Gemini
//
//  Created by James Norton on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>




@interface GeminiGLKViewController : GLKViewController <GLKViewControllerDelegate>{
    EAGLContext *context;
    SEL preRenderCallback;
    SEL postRenderCallback;
}

-(void)setPreRenderCallback:(SEL)callback;
-(void)setPostRenderCallback:(SEL)callback;
@end
