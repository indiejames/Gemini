//
//  GeminiRenderer.m
//  Gemini
//
//  Created by James Norton on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeminiRenderer.h"
#import "Gemini.h"
#import "GeminiLine.h"
#import "GeminiSprite.h"

#define LINE_BUFFER_CHUNK_SIZE (512)


GLuint vertexBuffer = 0;
BOOL bufferCreated = NO;

@implementation GeminiRenderer

-(GLuint)makeLineVertBuffer:(GLfloat **)buffer fromGroup:(GeminiDisplayGroup *)group bufferStartIndex:(GLuint *) startIndex bufferSize:(GLuint) bufferSize forLayer:(int)layerIndex {
    
    if ([group.objects count] > 0) {
        // make the buffer bigger with a big chunk at first
        bufferSize += LINE_BUFFER_CHUNK_SIZE;
        *buffer = (GLfloat *)realloc(*buffer, bufferSize);
    }
    for (int i=0; i<[group.objects count]; i++) {
        
        GeminiDisplayObject *gemObj = (GeminiDisplayObject *)[group.objects objectAtIndex:i];
        if (gemObj.class == GeminiDisplayGroup.class) {
            // recursion
            [self makeLineVertBuffer:buffer fromGroup:(GeminiDisplayGroup *)gemObj bufferStartIndex:startIndex bufferSize:bufferSize forLayer:layerIndex];
        } else if(gemObj.class == GeminiLine.class){
            GeminiLine *line = (GeminiLine *)gemObj;
            // make the buffer bigger if need be
            GLuint newByteCount = (line.numPoints * 3 * sizeof(GLfloat));
            while (*startIndex * 3 * sizeof(GLfloat) + newByteCount > bufferSize) {
                bufferSize += LINE_BUFFER_CHUNK_SIZE;
                *buffer = (GLfloat *)realloc(*buffer, bufferSize);
            }
            
            for (unsigned int j=0; j<line.numPoints; j++) {
                *buffer[*startIndex + j*3] = line.points[j*2] + [line getDoubleForKey:"x" withDefault:0];
                *buffer[*startIndex + j*3+1] = line.points[j*2 + 1] + [line getDoubleForKey:"y" withDefault:0];
                
                *buffer[*startIndex + j*3 + 2] = (GLfloat)layerIndex / 100.0 - 1;
                                
            }
            
            startIndex += line.numPoints;

            
        } else if(gemObj.class == GeminiSprite.class){
            
        }
        
        
    }

    
    
    return bufferSize;
}

-(void)render {
        
    NSMutableDictionary *stage = (NSMutableDictionary *)[stages objectForKey:activeStage];
    NSMutableArray *layers = [NSMutableArray arrayWithArray:[stage allKeys]];
    // sort layers from front (highest number) to back (lowest number)
    [layers sortUsingComparator:(NSComparator)^(NSNumber *layer1, NSNumber *layer2) {
        return [layer2 compare:layer1];
    }];
    //NSLog(@"GeminiRenderer found %d layers", [layers count]);
    // TODO - Add breaks in here to call client render methods before and after layer 0 to allow
    // client code to draw under or on top of some Lau objects - better yet, let the client
    // register callbacks for rendering particular layers - some layers will be rendered here
    // while other will defer to client code directly
    
    GLuint lineBufferSize = 0;
    
  /*  for (int i=0; i<[layers count]; i++) {
        NSNumber *layerIndex = (NSNumber *)[layers objectAtIndex:i];
        NSObject *obj = [stage objectForKey:layerIndex];
        
        if (obj.class == NSValue.class) {
            // this is a callback
           
        } else {
            // a display group 
            GeminiDisplayGroup *layer = (GeminiDisplayGroup *)obj;
           
            
        }
    }*/
    
    
    for (int i=0; i<[layers count]; i++) {
        NSNumber *layerIndex = (NSNumber *)[layers objectAtIndex:i];
        NSObject *obj = [stage objectForKey:layerIndex];
        if (obj.class == NSValue.class) {
            // this is a callback
            void(*callback)(void) = (void (*)(void))[(NSValue *)obj pointerValue];
            callback();
        } else {
            // a display group 
            GeminiDisplayGroup *layer = (GeminiDisplayGroup *)obj;
            [self renderLayer:layer atIndex:[layerIndex intValue]];
        }
       
    }
    
}

-(void)renderLayer:(GeminiDisplayGroup *)layer atIndex:(int) index {
    //NSLog(@"GeminiRenderer rendering layer %d", index);
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:1];
    NSMutableDictionary *spriteBatch = [NSMutableDictionary dictionaryWithCapacity:1];
    
    for (int i=0; i<[layer.objects count]; i++) {
        
        GeminiDisplayObject *gemObj = (GeminiDisplayObject *)[layer.objects objectAtIndex:i];
        if (gemObj.class == GeminiDisplayGroup.class) {
            // recursion
            [self renderLayer:(GeminiDisplayGroup *)gemObj atIndex:index];
        } else if(gemObj.class == GeminiLine.class){
            // TODO - sort all lines by line properties so they can be batched
            [lines addObject:gemObj];
            
        } else if(gemObj.class == GeminiSprite.class){
            
        }
            
        
    }
    
    [self renderLines:lines forLayerIndex:index];
}

-(void)renderLines:(NSArray *)lines forLayerIndex:(int)layerIndex {
   // NSLog(@"GeminiRenderer rendering %d lines...", [lines count]);
    glUseProgram(lineShaderManager.program);
    
    
    unsigned int maxPointCount = 0;
    for (int i=0; i<[lines count]; i++) {
        GeminiLine *line = (GeminiLine *)[lines objectAtIndex:i];
        if (line.numPoints > maxPointCount) {
            maxPointCount = line.numPoints;
        }
    }
    
    //glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
       
    for (int i=0; i<[lines count]; i++) {
        GeminiLine *line = (GeminiLine *)[lines objectAtIndex:i];
        GLfloat *verts = (GLfloat *)malloc(line.numPoints * 3 * sizeof(GLfloat));
        
        for (unsigned int j=0; j<line.numPoints; j++) {
            verts[j*3] = line.points[j*2] + [line getDoubleForKey:"x" withDefault:0];
            verts[j*3+1] = line.points[j*2 + 1] + [line getDoubleForKey:"y" withDefault:0];
            //verts[j*3] = x;
            //verts[j*3 + 1] = y;
            verts[j*3 + 2] = (GLfloat)layerIndex / 100.0 - 1;
            //x += 10;
            //y += 10;
            
        }
                
        //glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferSubData(GL_ARRAY_BUFFER, 0, 3*line.numPoints*sizeof(GLfloat), verts);
        //glBufferSubData(GL_ARRAY_BUFFER, 0, 6*sizeof(GLfloat), verts);
        
                
        //planetModelViewProjectionMatrix = GLKMatrix4MakeTranslation(0, 0, 0);
        
        
                
        //NSLog(@"Line color: (%f,%f,%f,%f)", line.color.r,line.color.g,line.color.b,line.color.a);
        glUniform4f(uniforms_line[UNIFORM_COLOR_LINE], line.color.r, line.color.g, line.color.b, line.color.a);
        
        
        //glEnableVertexAttribArray(ATTRIB_TEXCOORD);
        
        glVertexAttribPointer(ATTRIB_VERTEX_LINE, 3, GL_FLOAT, GL_FALSE, 0, 0);
        double linewidth = line.width;
        //NSLog(@"Line width = %f", linewidth);
        glLineWidth(linewidth);
        //glLineWidth(7.0);
        //glDrawElements(GL_LINE_STRIP, line.numPoints, GL_UNSIGNED_INT, 0);
        
        
        
        glDrawArrays(GL_LINE_STRIP, 0, line.numPoints);
                
        free(verts);
        
    }
    
    //glBindBuffer(GL_ARRAY_BUFFER, 0);
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
}



// add a display object to a given layer of the currently active stage.  create the layer
// if it does not already exist
-(void)addObject:(GeminiDisplayObject *)obj toLayer:(int)layer {
    NSLog(@"GeminiRenderer adding object");
    NSMutableDictionary *stage = (NSMutableDictionary *)[stages objectForKey:activeStage];
    NSLog(@"GeminiRenderer found stage");
    // sort the layers from front to back
    GeminiDisplayGroup *layerGroup = (GeminiDisplayGroup *)[stage objectForKey:[NSNumber numberWithInt:layer]];
    NSLog(@"GeminiRenderer found layer");
    if (layerGroup == nil) {
        NSLog(@"GeminiRenderer layer is nil");
        layerGroup = [[GeminiDisplayGroup alloc] initWithLuaState:((GeminiDisplayObject *)obj).L];
        NSLog(@"GeminiRenderer created new layer");
        [stage setObject:layerGroup forKey:[NSNumber numberWithInt:layer]];
    }
    NSLog(@"Inserting object into layer %d", layer);
    [layerGroup insert:obj];
    
}

// allow the client to register a callback to render for a particular layer
-(void)addCallback:(void (*)(void))callback forLayer:(int)layer {
     NSMutableDictionary *stage = (NSMutableDictionary *)[stages objectForKey:activeStage];
    NSValue *sel = [NSValue valueWithPointer:callback];
    [stage setObject:sel forKey:[NSNumber numberWithInt:layer]];
}

-(void)setActiveStage:(NSString *)stage {
    if (activeStage != nil) {
        [activeStage release];
    }
    activeStage = [stage retain];
}

-(id) initWithLuaState:(lua_State *)luaState {
    self = [super init];
    if (self) {
        //L = luaState;
        stages = [[NSMutableDictionary alloc] initWithCapacity:1];
        // add a default stage
        NSMutableDictionary *defaultStage = [[NSMutableDictionary alloc] initWithCapacity:1];
        [stages setObject:defaultStage forKey:DEFAULT_STAGE_NAME];
        [self setActiveStage:DEFAULT_STAGE_NAME];
        
        lineShaderManager = [[GeminiLineShaderManager alloc] init];
        [lineShaderManager loadShaders];
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        //glBufferData(GL_ARRAY_BUFFER, 3*maxPointCount*sizeof(GLfloat), NULL, GL_STATIC_DRAW);
        glBufferData(GL_ARRAY_BUFFER, 100000*sizeof(GLfloat), NULL, GL_DYNAMIC_DRAW);
        glUseProgram(lineShaderManager.program);
        GLfloat width = 320;
        GLfloat height = 480;
        
        GLfloat left = 0;
        GLfloat right = width;
        GLfloat bottom = 0;
        GLfloat top = height;
        
        
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Make(2.0/(right-left),0,0,0,0,2.0/(top-bottom),0,0,0,0,-1.0,0,-1.0,-1.0,-1.0,1.0);
        glUniformMatrix4fv(uniforms_line[UNIFORM_PROJECTION_LINE], 1, 0, modelViewProjectionMatrix.m);
        glEnableVertexAttribArray(ATTRIB_VERTEX_LINE);
        glEnable(GL_DEPTH_TEST);
    }
    
    return self;
}

-(void) dealloc {
    // TODO - objects shouldn't be dealloc'ed here - they should be removed in Lua
    NSArray *keys = [stages allKeys];
    for (int i=0; i<[keys count]; i++) {
        //NSString *stageKey = (NSString *)[keys objectAtIndex:i];
        
    }
    
    
    [super dealloc];
    
}


@end