//
//  GeminiGLKViewController.m
//  Gemini
//
//  Created by James Norton on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiGLKViewController.h"

//NSString *spriteFragmentShaderStr = @"uniform sampler2D texture; // texture sampler\nuniform highp float alpha; // alpha value for image\nvarying highp vec2 vTexCoord; // texture coordinates\nvoid main()\n{\nhighp vec4 texVal = texture2D(texture, vTexCoord);\ngl_FragColor = texVal;\n}";
NSString *spriteFragmentShaderStr = @"void main(){\ngl_FragColor = vec4(1.0,1.0,1.0,1.0);\n}";
NSString *spriteVertexShaderStr = @"attribute vec4 position;\nattribute vec2 texCoord;\nvarying vec2 vTexCoord;\nuniform mat4 proj;\nuniform mat4 rot;\nvoid main()\n{\ngl_Position = proj * rot * position;\nvTexCoord = texCoord;\n}";

// Uniform index.
enum {
    UNIFORM_PROJECTION,
    UNIFORM_ROTATION,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

@interface GeminiGLKViewController () {
    GLuint program;
    GLuint planetProgram;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLKMatrix4 planetModelViewProjectionMatrix;
    GLKMatrix3 planetNormalMatrix;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    GLuint planetVertexBuffer;
    GLuint planetIndexBuffer;
    
    GLuint quadVertexBuffer;
    GLuint quadIndexBuffer;
    
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)shaderSource;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation GeminiGLKViewController
@synthesize context;

-(id)init {
    self = [super init];
    
    if (self) {
            
        preRenderCallback = nil;
        postRenderCallback = nil;
        
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
    
    [self loadShaders];
    
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
    
}


- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    if (program) {
        glDeleteProgram(program);
        program = 0;
    }
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
    glClear(GL_COLOR_BUFFER_BIT);
    
     // call the pre render method
    if (preRenderCallback) {
        [self performSelector:preRenderCallback];
    }
    
    
    // do our thing
    
    GLint width;
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
    //glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GLfloat), (const GLvoid *)(2*sizeof(GLfloat)));
    
    //glEnable(GL_TEXTURE_2D);
    //glActiveTexture(GL_TEXTURE0);
    //glBindTexture(GL_TEXTURE0, planTexture);
    //glUniform1i(uniforms[UNIFORM_TEXTURE_0], 0);
    //glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glLineWidth(5.0);
    glDrawElements(GL_LINE_STRIP, 7, GL_UNSIGNED_INT, 0);
    
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    
    //////////////////////////////
    
    
    // call the post render method
    if (postRenderCallback) {
        [self performSelector:postRenderCallback];
    }
    
}

/*- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    
    
    //glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClearColor(0.0, 0.0, 0.05, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // quad with world texture
    glUseProgram(_program);
    glBindBuffer(GL_ARRAY_BUFFER, quadVertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, quadIndexBuffer);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    
}*/

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    
    // Create shader program.
    program = glCreateProgram();
    
    // Create and compile vertex shader.
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    NSString *fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Create and compile vertex shader.
   /* if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:spriteVertexShaderStr])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:spriteFragmentShaderStr])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }*/
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    //glBindAttribLocation(program, ATTRIB_TEXCOORD, "texCoord");
    
    // Link program.
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_PROJECTION] = glGetUniformLocation(program, "modelViewProjectionMatrix");
    //uniforms[UNIFORM_ROTATION] = glGetUniformLocation(program, "rot");
    
    
    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}



- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)shaderSource
{
    GLint status;
    //const GLchar *source = [shaderSource UTF8String];
    
    const GLchar *source = (GLchar *)[[NSString stringWithContentsOfFile:shaderSource encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (void) setPreRenderCallback:(SEL)callback {
    preRenderCallback = callback;
}

- (void) setPostRenderCallback:(SEL)callback {
    postRenderCallback = callback;
}

@end
