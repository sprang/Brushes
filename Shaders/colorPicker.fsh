#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
in vec2      varTexcoord;
out vec4     fragColor;
#else
varying vec2 varTexcoord;
#endif

uniform float hue;

vec3 HSLtoRGB(float h, float s, float v) 
{
    vec3 rgb;
    
    if (s == 0.0) {
        rgb = vec3(v);
    } else {
        float   f,p,q,t;
        int     i;
        
        h = mod(h * 6.0, 6.0);
        f = fract(h);
        i = int(h);
        
        p = v * (1.0 - s);
        q = v * (1.0 - s * f);
        t = v * (1.0 - (s * (1.0 - f)));
        
        if (i == 0) {
            rgb = vec3(v,t,p);
        } else if (i == 1) {
            rgb = vec3(q,v,p);
        } else if (i == 2) {
            rgb = vec3(p,v,t);
        } else if (i == 3) {
            rgb = vec3(p,q,v);
        } else if (i == 4) {
            rgb = vec3(t,p,v);
        } else {
            rgb = vec3(v,p,q);
        }
    }
    
    return rgb;
}

void main (void)
{
    gl_FragColor.rgb = HSLtoRGB(hue, varTexcoord.s, varTexcoord.t);
    gl_FragColor.a = 1.0;
}

