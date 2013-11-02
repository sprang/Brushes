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
uniform float       hueShift;
uniform float       saturationShift;
uniform float       brightnessShift;
uniform float       opacity;
uniform bool        premultiply;

const vec3 grayscale = vec3(0.3, 0.59, 0.11);

vec3 HCYtoRGB(float h, float C, float Y)
{
    float   X = C * (1.0 - abs(mod(h, 2.0) - 1.0));
    int     i = int(h);
    vec3    rgb;
    
    if (i == 0) {
        rgb = vec3(C, X, 0.0);
    } else if (i == 1) {
        rgb = vec3(X, C, 0.0);
    } else if (i == 2) {
        rgb = vec3(0.0, C, X);
    } else if (i == 3) {
        rgb = vec3(0.0, X, C);
    } else if (i == 4) {
        rgb = vec3(X, 0.0, C);
    } else {
        rgb = vec3(C, 0.0, X);
    }
    
    float m = Y - dot(rgb, grayscale);
    return rgb + vec3(m);
}

void main (void)
{
    gl_FragColor = texture2D(texture, varTexcoord.st, 0.0);
    
    float h = gl_FragColor.x;
    float c = gl_FragColor.y;
    float y = gl_FragColor.z;
    
    h += hueShift;
    h = mod(h * 6.0, 6.0);
    
    c = clamp(c * saturationShift, 0.0, 1.0);
    y = clamp(y * brightnessShift, 0.0, 1.0);
    
    gl_FragColor.rgb = HCYtoRGB(h, c, y);
    
    if (premultiply) {
        // -- layer with un-premultiplied data
        gl_FragColor.a *= opacity;
        gl_FragColor.rgb *= gl_FragColor.a;
    }
}
