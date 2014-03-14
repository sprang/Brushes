#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
in vec2      varTexcoord;
out vec4     fragColor;
#else
varying vec2 varTexcoord;
#endif

uniform sampler2D   texture;
uniform float       redShift;
uniform float       greenShift;
uniform float       blueShift;
uniform float       opacity;
uniform bool        premultiply;

void main (void)
{
    vec4 inColor = texture2D(texture, varTexcoord.st, 0.0);
    vec4 shifted = vec4(inColor.r * (1.0 + redShift), inColor.g * (1.0 + greenShift), inColor.b * (1.0 + blueShift), inColor.a);
    
    gl_FragColor = clamp(shifted, 0.0, 1.0);
    
    if (premultiply) {
        // -- layer with un-premultiplied data
        gl_FragColor.a *= opacity;
        gl_FragColor.rgb *= gl_FragColor.a;
    }
}