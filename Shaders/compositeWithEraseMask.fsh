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
uniform sampler2D mask;
uniform bool lockAlpha;

void main (void)
{
    gl_FragColor = texture2D(texture, varTexcoord.st, 0.0);
    float srcAlpha = 1.0 - texture2D(mask, varTexcoord.st, 0.0).a;
    gl_FragColor.a *= srcAlpha;
}
