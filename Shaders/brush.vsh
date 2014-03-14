#ifdef GL_ES
precision highp float;
#endif

uniform mat4 modelViewProjectionMatrix;

#if __VERSION__ >= 140
in vec4  inPosition;  
in vec2  inTexcoord;
in float alpha;
out vec2 varTexcoord;
out float varIntensity;
#else
attribute vec4 inPosition;  
attribute vec2 inTexcoord;
attribute float alpha;
varying vec2 varTexcoord;
varying float varIntensity;
#endif

void main (void) 
{
	gl_Position	= modelViewProjectionMatrix * inPosition;
    varTexcoord = inTexcoord;
    varIntensity = alpha;
}
