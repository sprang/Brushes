//
//  WDUtilities.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "WDGLUtilities.h"

void WDGLBuildQuadForRect(CGRect rect, CGAffineTransform transform, GLuint *quadVAO, GLuint *quadVBO)
{
    CGPoint corners[4];
    
    corners[0] = rect.origin;
    corners[1] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    corners[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    corners[3] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    
    for (int i = 0; i < 4; i++) {
        corners[i] = CGPointApplyAffineTransform(corners[i], transform);
    }
    
    const GLfloat vertices[] = {
        corners[0].x, corners[0].y, 0.0, 0.0,
        corners[1].x, corners[1].y, 1.0, 0.0,
        corners[3].x, corners[3].y, 0.0, 1.0,
        corners[2].x, corners[2].y, 1.0, 1.0,
    };
    
    glGenVertexArraysOES(1, quadVAO);
    glBindVertexArrayOES(*quadVAO);
    
    // create, bind, and populate VBO
    glGenBuffers(1, quadVBO);
    glBindBuffer(GL_ARRAY_BUFFER, *quadVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 16, vertices, GL_STATIC_DRAW);
    
    // set up attrib pointers
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, (void*)0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, (void*)8);
    glEnableVertexAttribArray(1);
    
    glBindBuffer(GL_ARRAY_BUFFER,0);
    glBindVertexArrayOES(0);
}

inline void WDGLRenderInRect(CGRect rect, CGAffineTransform transform)
{
    CGPoint corners[4];
    GLuint  quadVBO = 0;
    
    corners[0] = rect.origin;
    corners[1] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    corners[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    corners[3] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    
    for (int i = 0; i < 4; i++) {
        corners[i] = CGPointApplyAffineTransform(corners[i], transform);
    }
    
    const GLfloat quadVertices[] = {
        corners[0].x, corners[0].y, 0.0, 0.0,
        corners[1].x, corners[1].y, 1.0, 0.0,
        corners[3].x, corners[3].y, 0.0, 1.0,
        corners[2].x, corners[2].y, 1.0, 1.0,
    };
    
    // create, bind, and populate VBO
    glGenBuffers(1, &quadVBO);
    glBindBuffer(GL_ARRAY_BUFFER, quadVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 16, quadVertices, GL_STATIC_DRAW);
    
    // set up attrib pointers
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, (void*)0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, (void*)8);
    glEnableVertexAttribArray(1);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDeleteBuffers(1, &quadVBO);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}
