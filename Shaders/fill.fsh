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
uniform vec4 color;
uniform bool lockAlpha;

void main (void)
{
    vec4 dst = texture2D(texture, varTexcoord.st, 0.0);

    float srcAlpha = color.a;
    float outAlpha = srcAlpha + dst.a * (1.0 - srcAlpha);
    
    gl_FragColor.rgb = (color.rgb * srcAlpha + dst.rgb * dst.a * (1.0 - srcAlpha)) / outAlpha;
    gl_FragColor.a = lockAlpha ? dst.a : outAlpha;
}
