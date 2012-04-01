//
//  GeminiGLKViewController.m
//  Gemini
//
//  Created by James Norton on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Gemini.h"
#import "GeminiGLKViewController.h"
#import "GeminiRenderer.h"

//NSString *spriteFragmentShaderStr = @"uniform sampler2D texture; // texture sampler\nuniform highp float alpha; // alpha value for image\nvarying highp vec2 vTexCoord; // texture coordinates\nvoid main()\n{\nhighp vec4 texVal = texture2D(texture, vTexCoord);\ngl_FragColor = texVal;\n}";
NSString *spriteFragmentShaderStr = @"void main(){\ngl_FragColor = vec4(1.0,1.0,1.0,1.0);\n}";
NSString *spriteVertexShaderStr = @"attribute vec4 position;\nattribute vec2 texCoord;\nvarying vec2 vTexCoord;\nuniform mat4 proj;\nuniform mat4 rot;\nvoid main()\n{\ngl_Position = proj * rot * position;\nvTexCoord = texCoord;\n}";


@interface GeminiGLKViewController () {
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    GLKMatrix4 planetModelViewProjectionMatrix;
    GLKMatrix3 planetNormalMatrix;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    GLuint planetVertexBuffer;
    GLuint planetIndexBuffer;
    
    GLuint quadVertexBuffer;
    GLuint quadIndexBuffer;
    
    lua_State *L;
    
    
    
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation GeminiGLKViewController
@synthesize context;
@synthesize renderer;

-(id)initWithLuaState:(lua_State *)luaState {
    self = [super init];
    
    if (self) {
            
        preRenderCallback = nil;
        postRenderCallback = nil;
        L = luaState;
    }
    
    return self;
}


-(void) viewDidLoad {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    //view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    view.contentScaleFactor = 1.0;
    
    self.preferredFramesPerSecond = 60;
    
    [self setupGL];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

- (void)setupGL
{
    // combined position and tex coord
    GLfloat quadVerts[] = {
        50.0, 50.0, 0.0, 0.0,
        200.0, 50.0, 1.0, 0.0,
        50.0, 200.0, 0.0, 1.0,
        200.0, 250.0, 1.0, 1.0
    };
    
    
    GLuint quadIndex[] = {
        0, 1, 3, 2, 1, 3, 0  
    };
    
    [EAGLContext setCurrentContext:self.context];
    
    

    
    //glEnable(GL_DEPTH_TEST);
    
    /*// planet
     glGenBuffers(1, &planetVertexBuffer);
     glGenBuffers(1, &planetIndexBuffer);
     // bind buffer object for verts
     glBindBuffer(GL_ARRAY_BUFFER, planetVertexBuffer);
     glBufferData(GL_ARRAY_BUFFER, planet.numVerts * 3 * sizeof(GLfloat), 
     planet.verts, GL_STATIC_DRAW);
     glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, planetIndexBuffer);
     glBufferData(GL_ELEMENT_ARRAY_BUFFER, planet.numIndices*sizeof(GLuint), planet.indices, GL_STATIC_DRAW);
     
     glEnableVertexAttribArray(PLANET_ATTRIB_VERTEX);
     glVertexAttribPointer(PLANET_ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), 0);*/
    
    // quad
    glGenBuffers(1, &quadVertexBuffer);
    glGenBuffers(1, &quadIndexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, quadVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, 4*4*sizeof(GLfloat), quadVerts, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, quadIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6*sizeof(GLuint), quadIndex, GL_STATIC_DRAW);
    
    // load the renderer
    renderer = [[GeminiRenderer alloc] initWithLuaState:L];
    
}


- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
}

- (void)update
{
    //NSLog(@"update()");
    double scale = [UIScreen mainScreen].scale;
    
    
    GLint width;
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    NSLog(@"width = %d", width);
    NSLog(@"height = %d", height);
    NSLog(@"main screen scale = %f", scale);
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause {
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //NSLog(@"Drawing");
    glClearColor(0, 0.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
     // call the pre render method
    if (preRenderCallback) {
        [self performSelector:preRenderCallback];
    }
    
    
    
    // do our thing
    
    [renderer render];
    
/*    GLint width;
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    
    glUseProgram(program);
    glBindBuffer(GL_ARRAY_BUFFER, quadVertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, quadIndexBuffer);
    
    GLfloat left = 0;
    GLfloat right = width;
    GLfloat bottom = 0;
    GLfloat top = height;
    
    //planetModelViewProjectionMatrix = GLKMatrix4MakeTranslation(0, 0, 0);
    planetModelViewProjectionMatrix = GLKMatrix4Make(2.0/(right-left),0,0,0,0,2.0/(top-bottom),0,0,0,0,-2.0,0,-1.0,-1.0,-1.0,1.0);
    
    glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION], 1, 0, planetModelViewProjectionMatrix.m);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    //glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GLfloat), 0);
    
    glLineWidth(5.0);
    glDrawElements(GL_LINE_STRIP, 7, GL_UNSIGNED_INT, 0);
    
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
  */  
    
    //////////////////////////////
    
    
    // call the post render method
    if (postRenderCallback) {
        [self performSelector:postRenderCallback];
    }
    
}

- (void) setPreRenderCallback:(SEL)callback {
    preRenderCallback = callback;
}

- (void) setPostRenderCallback:(SEL)callback {
    postRenderCallback = callback;
}

@end
