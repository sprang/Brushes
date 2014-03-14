#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
in vec2      varTexcoord;
out vec4     fragColor;
#else
varying vec2 varTexcoord;
#endif

uniform sampler2D bottom;
uniform sampler2D top;
uniform float bottomOpacity;
uniform float topOpacity;
uniform int blendMode;

const vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
const int kNormal = 1852797549; // 'norm'
const int kMultiply = 1836412020; // 'mult'
const int kScreen = 1935897198; // 'scrn'
const int kExclude = 1702388588; // 'excl'

vec4 mergeOverWhite()
{
    vec4 dst = texture2D(bottom, varTexcoord.st, 0.0);
    vec4 src = texture2D(top, varTexcoord.st, 0.0);
    vec4 final;
    
    // capture the desired alphas
    float srcA = (src.a * topOpacity);
    float dstA = (dst.a * bottomOpacity);
    
    // make the colors opaque
    src.a = 1.0;
    dst.a = 1.0;
    
    // first blend the destination into opaque white
    vec4 intoWhite = (dst * dstA) + (white * (1.0 - dstA));
    
    // now blend the src
    vec4    blend = (src * srcA);
    vec4    target;
    
    if (blendMode == kNormal) {
        target = blend + (intoWhite * (1.0 - srcA));
    } else if (blendMode == kMultiply) {
        blend = blend * intoWhite;
        target = blend + (intoWhite * (1.0 - srcA));
    } else if (blendMode == kExclude) { // WDBlendModeExclusion
        target = blend * (1.0 - intoWhite) + (1.0 - blend) * intoWhite;
    }
    
    // now, compute RGB so that with the proper A it matches target when blending over white
    final.a = srcA + dstA * (1.0 - srcA);
    final.rgb = (target.rgb - vec3(1.0 - final.a)) / final.a;
    
    return final;
}
    
vec4 mergeDirectly()
{
    vec4 dst = texture2D(bottom, varTexcoord.st, 0.0);
    vec4 src = texture2D(top, varTexcoord.st, 0.0);
    vec4 final;
    
    // capture the desired alphas
    float srcA = (src.a * topOpacity);
    float dstA = (dst.a * bottomOpacity);
    
    // make the colors opaque
    src.a = 1.0;
    src *= srcA;
    dst.a = 1.0;
    dst *= dstA;
    
    if (blendMode == kScreen) {  // WDBlendModeScreen
        final = src + (1.0 - src) * dst;
    }
    
    final.a = srcA + dstA * (1.0 - srcA);
    final.rgb /= final.a;
    
    return final;
}

void main (void)
{
    if (blendMode == kNormal) { // WDNormalBlendMode
        gl_FragColor = mergeOverWhite();
    } else if (blendMode == kMultiply) { // WDBlendModeMultiply
        gl_FragColor = mergeOverWhite();
    } else if (blendMode == kScreen) {  // WDBlendModeScreen
        gl_FragColor = mergeDirectly();
    } else if (blendMode == kExclude) { // WDBlendModeExclusion
        gl_FragColor = mergeOverWhite();
    }
}
