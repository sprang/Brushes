#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
in vec2      varTexcoord;
out vec4     fragColor;
#else
varying vec2 varTexcoord;
#endif

uniform sampler2D texture;
uniform float opacity;

void main (void)
{
    gl_FragColor = texture2D(texture, varTexcoord.st, 0.0);
    
    // undo the premultiplication
    gl_FragColor.rgb /= gl_FragColor.a;
    
    gl_FragColor.a *= opacity;
}