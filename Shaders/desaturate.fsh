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

const vec3 grayscale = vec3(0.3, 0.59, 0.11);

void main (void)
{
    gl_FragColor = texture2D(texture, varTexcoord.st, 0.0);
    gl_FragColor.rgb = vec3(dot(gl_FragColor.rgb, grayscale));
}