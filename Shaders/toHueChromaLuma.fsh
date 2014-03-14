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

const vec3 grayscale = vec3(0.3, 0.59, 0.11);

vec3 RGBtoHCY(vec3 rgb)
{
    float max = max(rgb.r, max(rgb.g, rgb.b));
    float min = min(rgb.r, min(rgb.g, rgb.b));
    float chroma = max - min;
    
    float y = dot(rgb, grayscale);
    float h = 0.0;
    
    if (chroma != 0.0) {
        if (rgb.r == max) {
            h = (rgb.g - rgb.b) / chroma;
        } else if (rgb.g == max) {
            h = 2.0 + (rgb.b - rgb.r) / chroma;
        } else if (rgb.b == max) {
            h = 4.0 + (rgb.r - rgb.g) / chroma;
        }
        
        h = mod(h, 6.0) / 6.0;
    }
    
    return vec3(h, chroma, y);
}

void main (void)
{
    gl_FragColor = texture2D(texture, varTexcoord.st, 0.0);
    gl_FragColor.rgb = RGBtoHCY(gl_FragColor.rgb);
}
