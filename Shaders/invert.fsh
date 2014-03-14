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

const vec3 white = vec3(1.0);

void main (void)
{
    gl_FragColor = texture2D(texture, varTexcoord.st, 0.0);
    gl_FragColor.rgb = white - gl_FragColor.rgb;
}