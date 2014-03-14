#ifdef GL_ES
precision highp float;
#endif

uniform mat4 modelViewProjectionMatrix;

attribute vec4 inPosition;  
attribute vec2 inTexcoord;
varying vec2 varTexcoord;

void main (void) 
{
    gl_Position	= modelViewProjectionMatrix * inPosition;
    varTexcoord = inTexcoord;
}
