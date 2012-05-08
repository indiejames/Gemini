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
#import "GeminiLayer.h"

#define LINE_BUFFER_CHUNK_SIZE (512)


BOOL bufferCreated = NO;
GLfloat lineWidth[512];
GLuint lineCount = 0;

@implementation GeminiRenderer

-(GLuint)makeLineVertBuffer:(GLfloat **)buffer fromGroup:(GeminiDisplayGroup *)group bufferStartIndex:(GLuint *) startIndex bufferSize:(GLuint) bufferSize forLayer:(int)layerIndex {
    
    for (int i=0; i<[group.objects count]; i++) {
        
        GeminiDisplayObject *gemObj = (GeminiDisplayObject *)[group.objects objectAtIndex:i];
        if (gemObj.class == GeminiDisplayGroup.class) {
            // recursion
            bufferSize = [self makeLineVertBuffer:buffer fromGroup:(GeminiDisplayGroup *)gemObj bufferStartIndex:startIndex bufferSize:bufferSize forLayer:layerIndex];
        } else if(gemObj.class == GeminiLine.class){
            GeminiLine *line = (GeminiLine *)gemObj;
            lineWidth[lineCount] = line.width;
            lineCount += 1;
            
            // make the buffer bigger if need be
            GLuint newByteCount = (line.numPoints * 3 * sizeof(GLfloat));
            while (*startIndex * 3 * sizeof(GLfloat) + newByteCount > bufferSize) {
                bufferSize += LINE_BUFFER_CHUNK_SIZE;
                *buffer = (GLfloat *)realloc(*buffer, bufferSize);
            }
            
            for (unsigned int j=0; j<line.numPoints; j++) {
                
                *(*buffer + *startIndex * 3 + j*3)  = line.points[j*2] + [line getDoubleForKey:"x" withDefault:0];
                *(*buffer + *startIndex * 3 + j*3+1) = line.points[j*2 + 1] + [line getDoubleForKey:"y" withDefault:0];
                
                *(*buffer + *startIndex * 3 + j*3 + 2) = (GLfloat)layerIndex / 100.0 - 1;
                                
            }
            
            *startIndex += line.numPoints;

            
        } else if(gemObj.class == GeminiSprite.class){
            
        }
        
        
    }

    
    
    return bufferSize;
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
                [self renderDisplayGroup:layer forLayer:[layerIndex intValue]];
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
            
            [self renderDisplayGroup:layer forLayer:layer.index];
        }
        
    }
}


-(void)render {
    NSArray *blendedLayers = [self renderUnblendedLayers];
    [self renderBlendedLayers:blendedLayers];
     glBindVertexArrayOES(0);
}

-(void)renderDisplayGroup:(GeminiDisplayGroup *)group forLayer:(int)layer {
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:1];
    // NSMutableDictionary *spriteBatch = [NSMutableDictionary dictionaryWithCapacity:1];
    
    NSLog(@"Rendering layer %d", layer);
    NSLog(@"DisplayGroup has %d objects", [group.objects count]);
    
    for (int i=0; i<[group.objects count]; i++) {
        
        GeminiDisplayObject *gemObj = (GeminiDisplayObject *)[group.objects objectAtIndex:i];
        if (gemObj.class == GeminiDisplayGroup.class) {
            // recursion
            [self renderDisplayGroup:(GeminiDisplayGroup *)gemObj forLayer:layer];
            
        } else if(gemObj.class == GeminiLine.class){
            // TODO - sort all lines by line properties so they can be batched
            [lines addObject:gemObj];
            
        } else if(gemObj.class == GeminiSprite.class){
            
        }
        
    }

    [self renderLines:lines layerIndex:layer];

}



-(void)renderLayer:(GeminiDisplayGroup *)layer atOffset:(GLuint *) offset withIndex:(int)layerIndex{
    //NSLog(@"GeminiRenderer rendering layer %d", index);
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:1];
   // NSMutableDictionary *spriteBatch = [NSMutableDictionary dictionaryWithCapacity:1];
    
    
    
    for (int i=0; i<[layer.objects count]; i++) {
        
        GeminiDisplayObject *gemObj = (GeminiDisplayObject *)[layer.objects objectAtIndex:i];
        if (gemObj.class == GeminiDisplayGroup.class) {
            // recursion
            [self renderLayer:(GeminiDisplayGroup *)gemObj atOffset:offset withIndex:layerIndex];
        } else if(gemObj.class == GeminiLine.class){
            // TODO - sort all lines by line properties so they can be batched
            [lines addObject:gemObj];
            
        } else if(gemObj.class == GeminiSprite.class){
            
        }
            
        *offset = [self renderLines:lines withBufferOffset:*offset layerIndex:layerIndex];
        
        
    }
    
    
}

-(void)renderLine:(GeminiLine *)line withLayer:(int)layerIndex {
    NSLog(@"Rendering line...");
    [line computeVertices:layerIndex];
        
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    glBufferSubData(GL_ARRAY_BUFFER, 0, 6*line.numPoints*sizeof(GLfloat), line.verts);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, (line.numPoints - 1)*6*sizeof(GLushort), line.vertIndex);

    glDrawElements(GL_TRIANGLES,(line.numPoints - 1)*6,GL_UNSIGNED_SHORT, (void*)0);
}

-(GLuint)renderLines:(NSArray *)lines withBufferOffset:(GLuint)offset layerIndex:(int)layerIndex {
   // NSLog(@"GeminiRenderer rendering %d lines...", [lines count]);
    glBindVertexArrayOES(lineVAO);
    //glUseProgram(lineShaderManager.program);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
       
    for (int i=0; i<[lines count]; i++) {
        GeminiLine *line = (GeminiLine *)[lines objectAtIndex:i];
            
        //NSLog(@"Line color: (%f,%f,%f,%f)", line.color.r,line.color.g,line.color.b,line.color.a);
        glUniform4f(uniforms_line[UNIFORM_COLOR_LINE], line.color.r, line.color.g, line.color.b, line.color.a);
        offset += line.numPoints;
    
        [self renderLine:line withLayer:layerIndex];
               
    }
    
    return offset;
    
}


-(void)renderLines:(NSArray *)lines layerIndex:(int)layerIndex {
    
    glBindVertexArrayOES(lineVAO);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    for (int i=0; i<[lines count]; i++) {
        GeminiLine *line = (GeminiLine *)[lines objectAtIndex:i];
        
        glUniform4f(uniforms_line[UNIFORM_COLOR_LINE], line.color.r, line.color.g, line.color.b, line.color.a);
       
        [self renderLine:line withLayer:layerIndex];
        
    }
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

-(void)setupGL {
    
    
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
