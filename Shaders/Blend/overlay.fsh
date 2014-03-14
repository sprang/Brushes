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
const vec4 lumCoeff = vec4(0.2125, 0.7154, 0.0721, 1.0);

void main (void)
{
    vec4    baseColor = bottom ? white : texture2D(baseImage, varTexcoord.st);
    vec4    blendColor = texture2D(blendImage, varTexcoord.st);
    float   luminance = dot(baseColor, lumCoeff);
    vec4    result;
    
    // perform overlay blend
    
    if (luminance < 0.45) {
        result = 2.0 * blendColor * baseColor;
    } else if (luminance > 0.55) {
        result = white - 2.0 * (white - blendColor) * (white - baseColor);
    } else {
        vec4 result1 = 2.0 * blendColor * baseColor;
        vec4 result2 = white - 2.0 * (white - blendColor) * (white - baseColor);
        result = mix(result1, result2, (luminance - 0.45) * 10.0);
    }
    
    gl_FragColor = mix(baseColor, result, opacity);
}
