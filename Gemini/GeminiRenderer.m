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
#import "LGeminiDisplay.h"
#import "GeminiSpriteBatch.h"
#import "GeminiGLKViewController.h"

#define LINE_BUFFER_CHUNK_SIZE (512)

#define SPRITE_BATCH_CHUNK_SIZE (64)


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
    glDepthMask(GL_TRUE);
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
        
        if ([spriteBatches count] > 0) {
            [self renderSpriteBatches];
        }
        
    }
    
    return blendedLayers;
    
}

// render layers from back to front to support blending
-(void)renderBlendedLayers:(NSArray *)layers {
    glEnable(GL_BLEND);
    glDepthMask(GL_FALSE);
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
        
        if ([spriteBatches count] > 0) {
            [self renderSpriteBatches];
        }

        
    }
}




-(void)renderDisplayGroup:(GeminiDisplayGroup *)group forLayer:(int)layer withAlpha:(GLfloat)alpha transform:(GLKMatrix4)transform {
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *rectangles = [NSMutableArray arrayWithCapacity:1];
    
    GLKMatrix4 cumulTransform = GLKMatrix4Multiply(transform, group.transform);
    GLfloat groupAlpha = group.alpha;
    GLfloat cumulAlpha = groupAlpha * alpha;
    
    for (int i=0; i<[group.objects count]; i++) {
        
        GeminiDisplayObject *gemObj = (GeminiDisplayObject *)[group.objects objectAtIndex:i];
        if (gemObj.class == GeminiDisplayGroup.class) {
            // recursion
            [self renderDisplayGroup:(GeminiDisplayGroup *)gemObj forLayer:layer withAlpha:cumulAlpha transform:cumulTransform];
            
        } else if(gemObj.class == GeminiLine.class){
            // TODO - sort all lines by line properties so they can be batched
            [lines addObject:gemObj];
            
        } else if(gemObj.class == GeminiSprite.class){
            [self renderSprite:(GeminiSprite *)gemObj withLayer:layer alpha:cumulAlpha transform:cumulTransform];
                                    
        } else if(gemObj.class == GeminiRectangle.class){
            //[self renderRectangle:((GeminiRectangle *)gemObj) withLayer:layer alpha:cumulAlpha transform:transform];
            [rectangles addObject:gemObj];
        }
        
    }
    
    if ([lines count] > 0) {
        [self renderLines:lines layerIndex:layer alpha:cumulAlpha tranform:cumulTransform];
    }
    if ([rectangles count] > 0) {
        [self renderRectangles:rectangles withLayer:layer alpha:cumulAlpha transform:cumulTransform];
    }
    
    
}

-(void)renderSpriteBatches {
    glBindVertexArrayOES(spriteVAO);
    glUseProgram(spriteShaderManager.program);
    
    NSEnumerator *textureEnumerator = [spriteBatches keyEnumerator];
    GLKTextureInfo *texture;
    while (texture = (GLKTextureInfo *)[textureEnumerator nextObject]) {
        GeminiSpriteBatch *batch = [spriteBatches objectForKey:texture];
        //GLuint indexByteCount = 6 * [batch count] * sizeof(GLushort);
        GLuint indexByteCount = (4 * [batch count] + 2*([batch count] - 1)) * sizeof(GLushort);
        GLushort *index = (GLushort *)malloc(indexByteCount);
        
        unsigned int indexCount = 0;
        for (int i=0; i<[batch count]; i++) {
            index[i*6] = indexCount++;
            index[i*6 + 1] = indexCount++;
            index[i*6 + 2] = indexCount++;
            index[i*6 + 3] = indexCount++;
            
            if (i < [batch count] - 1) {
                index[i*6 + 4] = indexCount - 1;
                index[i*6 + 5] = indexCount;
            }
            
            
        }
                                                         
        
        glBufferSubData(GL_ARRAY_BUFFER, 0, [batch count] * 4*sizeof(TexturedVertex), batch.vertexBuffer);
        glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, indexByteCount, index);
        
        glActiveTexture(GL_TEXTURE0); 
        GLuint texId = texture.name;
        glBindTexture(GL_TEXTURE_2D, texId);
        glUniform1i(uniforms_sprite[UNIFORM_TEXTURE_SPRITE], 0); 
        
        
        glDrawElements(GL_TRIANGLE_STRIP, indexByteCount / sizeof(GLushort), GL_UNSIGNED_SHORT, (void*)0);
        //glDrawElements(GL_TRIANGLE_STRIP, 10, GL_UNSIGNED_SHORT, (void*)0);
        
        free(index);
    }
  

    [spriteBatches removeAllObjects];
}

-(void)renderSprite:(GeminiSprite *)sprite withLayer:(int)layerIndex alpha:(GLfloat)alpha transform:(GLKMatrix4)transform {
    
    GLKMatrix4 finalTransform = GLKMatrix4Multiply(transform, sprite.transform);
    
    GLfloat z = ((GLfloat)(layerIndex)) / 256.0 - 0.5;
    
    GLfloat *posVerts = (GLfloat *)malloc(4*3*sizeof(GLfloat));

    posVerts[0] = sprite.x - sprite.width / 2.0;
    posVerts[1] = sprite.y - sprite.height / 2.0;
    posVerts[2] = z;
    posVerts[3] = posVerts[0];
    posVerts[4] = sprite.y + sprite.height / 2.0;
    posVerts[5] = z;
    posVerts[6] = sprite.x + sprite.width / 2.0;
    posVerts[7] = posVerts[1];
    posVerts[8] = z;
    posVerts[9] = posVerts[6];
    posVerts[10] = posVerts[4];
    posVerts[11] = z;
    
    GLfloat *newPosVerts = (GLfloat *)malloc(4*3*sizeof(GLfloat));
    
    transformVertices(newPosVerts, posVerts, 4, finalTransform);
    
    GeminiSpriteBatch *sprites = (GeminiSpriteBatch *)[spriteBatches objectForKey:sprite.textureInfo];
    if (sprites == nil) {
        sprites = [[[GeminiSpriteBatch alloc] initWithCapacity:SPRITE_BATCH_CHUNK_SIZE] autorelease];
        [spriteBatches setObject:sprites forKey:sprite.textureInfo];
        
    }
    
    TexturedVertex *spriteVerts = [sprites getPointerForInsertion];
    
    for (int i=0; i<4; i++) {
        
        for (int j=0; j<3; j++) {
            
            spriteVerts[i].position[j] = newPosVerts[i*3+j];
            spriteVerts[i].color[j] = 1.0; // TODO - allow use of colors here
        }
        spriteVerts[i].color[3] = sprite.alpha;
        spriteVerts[i].texCoord[0] = (i == 0 || i == 1) ? sprite.textureCoord.x : sprite.textureCoord.z;
        spriteVerts[i].texCoord[1] = (i == 0 || i == 2) ? sprite.textureCoord.y : sprite.textureCoord.w;
    }
    
    
    free(newPosVerts);
    free(posVerts);
    
}


-(void)renderLines:(NSArray *)lines layerIndex:(int)layerIndex alpha:(GLfloat)alpha tranform:(GLKMatrix4 ) transform {
    
    glBindVertexArrayOES(lineVAO);
    
    glUseProgram(lineShaderManager.program);
    
   // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
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
    
  //  glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
  //  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    glBufferSubData(GL_ARRAY_BUFFER, 0, 6*line.numPoints*sizeof(GLfloat), newVerts);
    //glBufferSubData(GL_ARRAY_BUFFER, 0, 6*line.numPoints*sizeof(GLfloat), line.verts);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, (line.numPoints - 1)*6*sizeof(GLushort), line.vertIndex);
    
    glDrawElements(GL_TRIANGLES,(line.numPoints - 1)*6,GL_UNSIGNED_SHORT, (void*)0);
    
    free(newVerts);
}



-(void)renderRectangles:(NSArray *)rectangles withLayer:(int)layerIndex alpha:(GLfloat)alpha transform:(GLKMatrix4)transform {
    
    glBindVertexArrayOES(rectangleVAO);
    
    glUseProgram(rectangleShaderManager.program);
    
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    //glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    
    
    GLuint vertOffset = 0;
    GLuint indexOffset = 0;
    
    for (int i=0; i<[rectangles count]; i++) {
        GeminiRectangle *rectangle = (GeminiRectangle *)[rectangles objectAtIndex:i];
        GLKMatrix4 finalTransform = GLKMatrix4Multiply(transform, rectangle.transform);
        
        GLfloat *newVerts = (GLfloat *)malloc(12*3*sizeof(GLfloat));
        
        
        unsigned int vertCount = 4;
        unsigned int indexCount = 6;
        if (rectangle.strokeWidth > 0) {
            vertCount = 12;
            indexCount = 30;
        }
        
        transformVertices(newVerts, rectangle.verts, vertCount, finalTransform);
        
        GLfloat finalAlpha = alpha * rectangle.alpha;
        
        //memcpy(newVerts, rectangle.verts, vertCount*3*sizeof(GLfloat));
        
        ColoredVertex *vertData = (ColoredVertex *)malloc(vertCount*sizeof(ColoredVertex));
        for (int j=0; j<vertCount; j++) {
            vertData[j].position[0] = newVerts[j*3];
            vertData[j].position[1] = newVerts[j*3+1];
            vertData[j].position[2] = newVerts[j*3+2];
            vertData[j].color[0] = rectangle.vertColor[j*4];
            vertData[j].color[1] = rectangle.vertColor[j*4+1];
            vertData[j].color[2] = rectangle.vertColor[j*4+2];
            vertData[j].color[3] = rectangle.vertColor[j*4+3] * finalAlpha;
        }
        
        GLushort *newIndex = malloc(indexCount * sizeof(GLushort));
        
        GLushort vertIndexOffset = vertOffset / sizeof(ColoredVertex);
        
        for (int j=0; j<indexCount; j++) {
            newIndex[j] = rectangle.vertIndex[j] + vertIndexOffset;
        }
        
        glBufferSubData(GL_ARRAY_BUFFER, vertOffset, vertCount*sizeof(ColoredVertex), vertData);
        glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, indexOffset, indexCount*sizeof(GLushort), newIndex);
        
        vertOffset += vertCount*sizeof(ColoredVertex);
        indexOffset += indexCount*sizeof(GLushort);
        
        free(vertData);
        free(newVerts);
        free(newIndex);
    }
    
    glDrawElements(GL_TRIANGLES, indexOffset / sizeof(GLushort), GL_UNSIGNED_SHORT, (void*)0);

}

-(void)renderRectangle:(GeminiRectangle *)rectangle withLayer:(int)layerIndex alpha:(GLfloat)alpha transform:(GLKMatrix4)transform {
    
    glBindVertexArrayOES(rectangleVAO);
    
    glUseProgram(rectangleShaderManager.program);
    
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    //glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
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
    
    GLfloat finalAlpha = alpha * rectangle.alpha;
    
    //memcpy(newVerts, rectangle.verts, vertCount*3*sizeof(GLfloat));
    
    ColoredVertex *vertData = (ColoredVertex *)malloc(vertCount*sizeof(ColoredVertex));
    for (int i=0; i<vertCount; i++) {
        vertData[i].position[0] = newVerts[i*3];
        vertData[i].position[1] = newVerts[i*3+1];
        vertData[i].position[2] = newVerts[i*3+2];
        vertData[i].color[0] = rectangle.vertColor[i*4];
        vertData[i].color[1] = rectangle.vertColor[i*4+1];
        vertData[i].color[2] = rectangle.vertColor[i*4+2];
        vertData[i].color[3] = rectangle.vertColor[i*4+3] * finalAlpha;
    }
    
    glBufferSubData(GL_ARRAY_BUFFER, 0, vertCount*sizeof(ColoredVertex), vertData);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, indexCount*sizeof(GLushort), rectangle.vertIndex);
    
    NSLog(@"renderRectangle() - indexCount = %d", indexCount);
    
    glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_SHORT, (void*)0);
    
    free(vertData);
    free(newVerts);
}


// add a new layer
-(void)addLayer:(GeminiLayer *)layer {
    NSLog(@"GeminiRenderer adding layer with index %d", layer.index);
    NSMutableDictionary *stage = (NSMutableDictionary *)[stages objectForKey:activeStage];
    [stage setObject:layer forKey:[NSNumber numberWithInt:layer.index]];
}


// add a display object to the default layer (layer 0)
-(void)addObject:(GeminiDisplayObject *)obj {
    NSLog(@"GeminiRenderer adding object");
    NSMutableDictionary *stage = (NSMutableDictionary *)[stages objectForKey:activeStage];
    // get the default layer on the stage
    NSNumber *layerIndex = [NSNumber numberWithInt:0];
    GeminiLayer *layerGroup = (GeminiLayer *)[stage objectForKey:layerIndex];
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
        layerGroup = [[[GeminiLayer alloc] initWithLuaState:((GeminiDisplayObject *)obj).L] autorelease];
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
    glBufferData(GL_ARRAY_BUFFER, 64096*sizeof(GLfloat), NULL, GL_DYNAMIC_DRAW);
    
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 64096*sizeof(GLushort), NULL, GL_DYNAMIC_DRAW);
    
    glUseProgram(lineShaderManager.program);
    
    GLKView *view = (GLKView *)((GeminiGLKViewController *)([Gemini shared].viewController)).view;
    
    
    GLfloat width = 640;
    GLfloat height = 960;
    
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
    
    GLKView *view = (GLKView *)((GeminiGLKViewController *)([Gemini shared].viewController)).view;
    
    
    GLfloat width = 640;
    GLfloat height = 960;
    
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
    glUniformMatrix4fv(uniforms_rectangle[UNIFORM_PROJECTION_RECTANGLE], 1, 0, modelViewProjectionMatrix.m);
   
    glEnableVertexAttribArray(ATTRIB_VERTEX_RECTANGLE);
    glEnableVertexAttribArray(ATTRIB_COLOR_RECTANGLE);
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glBindVertexArrayOES(0);
}

-(void)setupSpriteRendering {
    glGenVertexArraysOES(1, &spriteVAO);
    glBindVertexArrayOES(spriteVAO);
    
    spriteBatches = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    spriteShaderManager = [[GeminiSpriteShaderManager alloc] init];
    [spriteShaderManager loadShaders];
    
    glUseProgram(spriteShaderManager.program);
    
    GLKView *view = (GLKView *)((GeminiGLKViewController *)([Gemini shared].viewController)).view;
    
    
    GLfloat width = 640;
    GLfloat height = 960;
    
    GLfloat left = 0;
    GLfloat right = width;
    GLfloat bottom = 0;
    GLfloat top = height;
    
    glVertexAttribPointer(ATTRIB_VERTEX_SPRITE, 3, GL_FLOAT, GL_FALSE, sizeof(TexturedVertex), (GLvoid *)0);
    
    glVertexAttribPointer(ATTRIB_COLOR_SPRITE, 4, GL_FLOAT, GL_FALSE, 
                          sizeof(TexturedVertex), (GLvoid*) (sizeof(float) * 3));
    glVertexAttribPointer(ATTRIB_TEXCOORD_SPRITE, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedVertex), (GLvoid *)(sizeof(float) * 7));
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(ATTRIB_VERTEX_SPRITE);
    glEnableVertexAttribArray(ATTRIB_COLOR_SPRITE);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD_SPRITE);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Make(2.0/(right-left),0,0,0,0,2.0/(top-bottom),0,0,0,0,-1.0,0,-1.0,-1.0,-1.0,1.0);
    glUniformMatrix4fv(uniforms_sprite[UNIFORM_PROJECTION_SPRITE], 1, 0, modelViewProjectionMatrix.m);
    
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    //glEnable(GL_TEXTURE_2D);
    
    glBindVertexArrayOES(0);
}


-(void)setupGL {
    
    [self setupLineRendering];
    [self setupRectangleRendering];
    [self setupSpriteRendering];
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
        [defaultStage release];
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
