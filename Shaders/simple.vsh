attribute vec4 inPosition;

uniform mat4 modelViewProjectionMatrix;
uniform vec4 color;

varying vec4 colorVarying;

void main()
{
	gl_Position = modelViewProjectionMatrix * inPosition;
	colorVarying = color;
}
