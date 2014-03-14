//
//  WDUtilities.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

void WDGLBuildQuadForRect(CGRect rect, CGAffineTransform transform, GLuint *quadVAO, GLuint *quadVBO);
void WDGLRenderInRect(CGRect rect, CGAffineTransform transform);
