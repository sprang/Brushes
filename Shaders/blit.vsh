#ifdef GL_ES
precision highp float;
#endif

uniform mat4 modelViewProjectionMatrix;

#if __VERSION__ >= 140
in vec4  inPosition;  
in vec2  inTexcoord;
out vec2 varTexcoord;
#else
attribute vec4 inPosition;  
attribute vec2 inTexcoord;
varying vec2 varTexcoord;
#endif

void main (void) 
{
	gl_Position	= modelViewProjectionMatrix * inPosition;
    varTexcoord = inTexcoord;
}
