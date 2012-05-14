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
#import "GeminiRectangle.h"
#import "GeminiSprite.h"
#import "GeminiLayer.h"

#define LINE_BUFFER_CHUNK_SIZE (512)


BOOL bufferCreated = NO;
GLfloat lineWidth[512];
GLuint lineCount = 0;

@implementation GeminiRenderer

//
// apply a transform to a set of vertices.  
// the ouput array should be preallocated to the same size as the input array
//
static void transformVertices(GLfloat *outVerts, GLfloat *inVerts, GLuint vertCount, GLKMatrix4 transform){
    
    // create an array of vectors from our input data
    GLKVector3 *vectorArray = (GLKVector3 *)malloc(vertCount * sizeof(GLKVector3));
    for (GLuint i = 0; i<vertCount; i++) {
        vectorArray[i] = GLKVector3MakeWithArray(inVerts + 3*i);    
    }
    
    GLKMatrix4MultiplyVector3ArrayWithTranslation(transform, vectorArray, vertCount);
    
    for (GLuint i = 0; i<vertCount; i++) {
        
        outVerts[i*3] = vectorArray[i].x;
        outVerts[i*3+1] = vectorArray[i].y;
        outVerts[i*3+2] = vectorArray[i].z;
        
    }
    
    free(vectorArray);
    
}

-(void)render {
    NSArray *blendedLayers = [self renderUnblendedLayers];
    [self renderBlendedLayers:blendedLayers];
    glBindVertexArrayOES(0);
}

// render layers from front to back to minimize overdraw
-(NSArray *)renderUnblendedLayers {
    glDisable(GL_BLEND);
    
    NSMutableArray *blendedLayers = [[[NSMutableArray alloc] initWithCapacity:1] autorelease];
    
    NSMutableDictionary *stage = (NSMutableDictionary *)[stages objectForKey:activeStage];
    NSMutableArray *layers = [NSMutableArray arrayWithArray:[stage allKeys]];
    // sort layers from front (highest number) to back (lowest number)
    [layers sortUsingComparator:(NSComparator)^(NSNumber *layer1, NSNumber *layer2) {
        return [layer2 compare:layer1];
    }];
    lineCount = 0;
    
    for (int i=0; i<[layers count]; i++) {
        NSNumber *layerIndex = (NSNumber *)[layers objectAtIndex:i];
        
        NSObject *obj = [stage objectForKey:layerIndex];
        if (obj.class == NSValue.class) {
            // this is a callback layer
            void(*callback)(void) = (void (*)(void))[(NSValue *)obj pointerValue];
            callback();
        } else {
            // a display group layer 
            GeminiLayer *layer = (GeminiLayer *)obj;
            if (layer.isBLendingLayer) {
                [blendedLayers insertObject:layer atIndex:0];
            } else {
                [self renderDisplayGroup:layer forLayer:[layerIndex intValue] withAlpha:1.0 transform:GLKMatrix4Identity];
            }
            
        }
        
    }

    
    
    return blendedLayers;
    
}

// render layers from back to front to support blending
-(void)renderBlendedLayers:(NSArray *)layers {
    glEnable(GL_BLEND);
    
    for (int i=0; i<[layers count]; i++) {
        
        NSObject *obj = [layers objectAtIndex:i];
        if (obj.class == NSValue.class) {
            // this is a callback layer
            void(*callback)(void) = (void (*)(void))[(NSValue *)obj pointerValue];
            callback();
        } else {
            // a display group layer
            GeminiLayer *layer = (GeminiLayer *)obj;
            
            glBlendFunc(layer.sourceBlend, layer.destBlend);
            
            [self renderDisplayGroup:layer forLayer:layer.index withAlpha:1.0 transform:GLKMatrix4Identity];
        }
        
    }
}




-(void)renderDisplayGroup:(GeminiDisplayGroup *)group forLayer:(int)layer withAlpha:(GLfloat)alpha transform:(GLKMatrix4)transform {
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:1];
    // NSMutableDictionary *spriteBatch = [NSMutableDictionary dictionaryWithCapacity:1];
    
    NSLog(@"Rendering layer %d", layer);
    NSLog(@"DisplayGroup has %d objects", [group.objects count]);
    
    GLKMatrix4 cumulTransform = GLKMatrix4Multiply(transform, group.transform);
    GLfloat cumulAlpha = group.alpha * alpha;
    
    for (int i=0; i<[group.objects count]; i++) {
        
        GeminiDisplayObject *gemObj = (GeminiDisplayObject *)[group.objects objectAtIndex:i];
        if (gemObj.class == GeminiDisplayGroup.class) {
            // recursion
            [self renderDisplayGroup:(GeminiDisplayGroup *)gemObj forLayer:layer withAlpha:alpha transform:cumulTransform];
            
        } else if(gemObj.class == GeminiLine.class){
            // TODO - sort all lines by line properties so they can be batched
            [lines addObject:gemObj];
            
        } else if(gemObj.class == GeminiSprite.class){
            
        } else if(gemObj.class == GeminiRectangle.class){
            [self renderRectangle:((GeminiRectangle *)gemObj) withLayer:layer alpha:alpha transform:transform];
        }
        
    }

    [self renderLines:lines layerIndex:layer alpha:cumulAlpha tranform:cumulTransform];

}

-(void)renderLines:(NSArray *)lines layerIndex:(int)layerIndex alpha:(GLfloat)alpha tranform:(GLKMatrix4 ) transform {
    
    glBindVertexArrayOES(lineVAO);
    
    glUseProgram(lineShaderManager.program);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    for (int i=0; i<[lines count]; i++) {
        GeminiLine *line = (GeminiLine *)[lines objectAtIndex:i];
        
        glUniform4f(uniforms_line[UNIFORM_COLOR_LINE], line.color.r, line.color.g, line.color.b, line.color.a);
       
        [self renderLine:line withLayer:layerIndex alpha:alpha transform:transform];
        
    }
}

-(void)renderLine:(GeminiLine *)line withLayer:(int)layerIndex alpha:(GLfloat)alpha transform:(GLKMatrix4)transform {
    
    [line computeVertices:layerIndex];
    
    GLKMatrix4 finalTransform = GLKMatrix4Multiply(transform, line.transform);
    
    GLfloat *newVerts = (GLfloat *)malloc(line.numPoints * 6*sizeof(GLfloat));
    transformVertices(newVerts, line.verts, line.numPoints*2, finalTransform);
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    glBufferSubData(GL_ARRAY_BUFFER, 0, 6*line.numPoints*sizeof(GLfloat), newVerts);
    //glBufferSubData(GL_ARRAY_BUFFER, 0, 6*line.numPoints*sizeof(GLfloat), line.verts);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, (line.numPoints - 1)*6*sizeof(GLushort), line.vertIndex);
    
    glDrawElements(GL_TRIANGLES,(line.numPoints - 1)*6,GL_UNSIGNED_SHORT, (void*)0);
    
    free(newVerts);
}


-(void)renderRectangle:(GeminiRectangle *)rectangle withLayer:(int)layerIndex alpha:(GLfloat)alpha transform:(GLKMatrix4)transform {
    
    glBindVertexArrayOES(rectangleVAO);
    
    glUseProgram(rectangleShaderManager.program);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(ATTRIB_VERTEX_RECTANGLE);
    glEnableVertexAttribArray(ATTRIB_COLOR_RECTANGLE);
    
    GLKMatrix4 finalTransform = GLKMatrix4Multiply(transform, rectangle.transform);
    
    GLfloat *newVerts = (GLfloat *)malloc(12*3*sizeof(GLfloat));
    
    
    unsigned int vertCount = 4;
    unsigned int indexCount = 6;
    if (rectangle.strokeWidth > 0) {
        vertCount = 12;
        indexCount = 30;
    }
    
    transformVertices(newVerts, rectangle.verts, vertCount, finalTransform);
    
    memcpy(newVerts, rectangle.verts, vertCount*3*sizeof(GLfloat));
    
    ColoredVertex *vertData = (ColoredVertex *)malloc(vertCount*sizeof(ColoredVertex));
    for (int i=0; i<vertCount; i++) {
        vertData[i].position[0] = newVerts[i*3];
        vertData[i].position[1] = newVerts[i*3+1];
        vertData[i].position[2] = newVerts[i*3+2];
        vertData[i].color[0] = rectangle.vertColor[i*4];
        vertData[i].color[1] = rectangle.vertColor[i*4+1];
        vertData[i].color[2] = rectangle.vertColor[i*4+2];
        vertData[i].color[3] = rectangle.vertColor[i*4+3];
    }
    
    glBufferSubData(GL_ARRAY_BUFFER, 0, vertCount*sizeof(ColoredVertex), vertData);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, indexCount*sizeof(GLushort), rectangle.vertIndex);

    glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_SHORT, (void*)0);
    
    /*if (rectangle.strokeWidth > 0) {
        glDrawElements(GL_TRIANGLES, 30, GL_UNSIGNED_SHORT, (void*)0);
    } else {
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, (void*)0);
    }*/
    
    free(vertData);
    free(newVerts);
}


// add a new layer
-(void)addLayer:(GeminiLayer *)layer {
    NSLog(@"GeminiRenderer adding layer");
    NSMutableDictionary *stage = (NSMutableDictionary *)[stages objectForKey:activeStage];
    [stage setObject:layer forKey:[NSNumber numberWithInt:layer.index]];
}


// add a display object to the default layer (layer 0)
-(void)addObject:(GeminiDisplayObject *)obj {
    NSLog(@"GeminiRenderer adding object");
    NSMutableDictionary *stage = (NSMutableDictionary *)[stages objectForKey:activeStage];
    NSLog(@"GeminiRenderer found stage");
    // get the default layer on the stage
    NSNumber *layerIndex = [NSNumber numberWithInt:0];
    GeminiLayer *layerGroup = (GeminiLayer *)[stage objectForKey:layerIndex];
    NSLog(@"GeminiRenderer found layer");
    if (layerGroup == nil) {
        NSLog(@"GeminiRenderer layer is nil");
        layerGroup = [[GeminiLayer alloc] initWithLuaState:((GeminiDisplayObject *)obj).L];
        layerGroup.index = 0;
        NSLog(@"GeminiRenderer created new layer");
        [stage setObject:layerGroup forKey:layerIndex];
    }
    NSLog(@"Inserting object into layer 0");
    // remove from previous layer (if any) first
    [obj.layer remove:obj];
    obj.layer = layerGroup;
    [layerGroup insert:obj];
    
}


// add a display object to a given layer of the currently active stage.  create the layer
// if it does not already exist
-(void)addObject:(GeminiDisplayObject *)obj toLayer:(int)layer {
    NSLog(@"GeminiRenderer adding object");
    NSMutableDictionary *stage = (NSMutableDictionary *)[stages objectForKey:activeStage];
    NSLog(@"GeminiRenderer found stage");
    // sort the layers from front to back
    GeminiLayer *layerGroup = (GeminiLayer *)[stage objectForKey:[NSNumber numberWithInt:layer]];
    NSLog(@"GeminiRenderer found layer");
    if (layerGroup == nil) {
        NSLog(@"GeminiRenderer layer is nil");
        layerGroup = [[GeminiLayer alloc] initWithLuaState:((GeminiDisplayObject *)obj).L];
        layerGroup.index = layer;
        NSLog(@"GeminiRenderer created new layer");
        [stage setObject:layerGroup forKey:[NSNumber numberWithInt:layer]];
    }
    NSLog(@"Inserting object into layer %d", layer);
    // remove from previous layer (if any) first
    [obj.layer remove:obj];
    obj.layer = layerGroup;
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

-(void)setupLineRendering {
    glGenVertexArraysOES(1, &lineVAO);
    glBindVertexArrayOES(lineVAO);
    
    lineShaderManager = [[GeminiLineShaderManager alloc] init];
    [lineShaderManager loadShaders];
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, 4096*sizeof(GLfloat), NULL, GL_DYNAMIC_DRAW);
    
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 4096*sizeof(GLushort), NULL, GL_DYNAMIC_DRAW);
    
    glUseProgram(lineShaderManager.program);
    GLfloat width = 320;
    GLfloat height = 480;
    
    GLfloat left = 0;
    GLfloat right = width;
    GLfloat bottom = 0;
    GLfloat top = height;
    
    glVertexAttribPointer(ATTRIB_VERTEX_LINE, 3, GL_FLOAT, GL_FALSE, 0, (GLvoid *)0);
    
    
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Make(2.0/(right-left),0,0,0,0,2.0/(top-bottom),0,0,0,0,-1.0,0,-1.0,-1.0,-1.0,1.0);
    glUniformMatrix4fv(uniforms_line[UNIFORM_PROJECTION_LINE], 1, 0, modelViewProjectionMatrix.m);
    glEnableVertexAttribArray(ATTRIB_VERTEX_LINE);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glBindVertexArrayOES(0);
}

-(void)setupRectangleRendering {
    glGenVertexArraysOES(1, &rectangleVAO);
    glBindVertexArrayOES(rectangleVAO);
    
    rectangleShaderManager = [[GeminiRectangleShaderManager alloc] init];
    [rectangleShaderManager loadShaders];
    
    glUseProgram(rectangleShaderManager.program);
    GLfloat width = 320;
    GLfloat height = 480;
    
    GLfloat left = 0;
    GLfloat right = width;
    GLfloat bottom = 0;
    GLfloat top = height;
    
    glVertexAttribPointer(ATTRIB_VERTEX_RECTANGLE, 3, GL_FLOAT, GL_FALSE, sizeof(ColoredVertex), (GLvoid *)0);
    
    glVertexAttribPointer(ATTRIB_COLOR_RECTANGLE, 4, GL_FLOAT, GL_FALSE, 
                          sizeof(ColoredVertex), (GLvoid*) (sizeof(float) * 3));
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(ATTRIB_VERTEX_RECTANGLE);
    glEnableVertexAttribArray(ATTRIB_COLOR_RECTANGLE);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Make(2.0/(right-left),0,0,0,0,2.0/(top-bottom),0,0,0,0,-1.0,0,-1.0,-1.0,-1.0,1.0);
    glUniformMatrix4fv(uniforms_line[UNIFORM_PROJECTION_RECTANGLE], 1, 0, modelViewProjectionMatrix.m);
   
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glBindVertexArrayOES(0);
}

-(void)setupGL {
    
    [self setupLineRendering];
    [self setupRectangleRendering];
    
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
        
        [self setupGL];
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

// vector functions



@end
