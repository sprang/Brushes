#ifdef GL_ES
precision highp float;
#endif

// uniforms
uniform sampler2D   baseImage;
uniform sampler2D   blendImage;
uniform float       opacity;
uniform bool        bottom;

varying vec2 varTexcoord;

const vec4 white = vec4(1.0, 1.0, 1.0, 1.0);

void main (void)
{
    vec4 baseColor = bottom ? white : texture2D(baseImage, varTexcoord.st);
    vec4 blendColor = texture2D(blendImage, varTexcoord.st);
    
    // perform lighten blend
    vec4 result = max(blendColor, baseColor);
    
    gl_FragColor = mix(baseColor, result, opacity);
}
