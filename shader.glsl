#version 330 core
out vec4 FragColor;
in vec3 pos;

uniform sampler2D tex;
uniform      vec2 res;
uniform     float t;

#define V2 vec2
#define V3 vec3
#define V4 vec4
#define V1 float
#define PI 3.14159265359

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 0.66666, 0.33333, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, p - K.xxx, c.y);
}

V1 sq(V1 x){return x*x;}
V1 min2(V2 v){return min(v.x,v.y);}
V1 max2(V2 v){return max(v.x,v.y);}
V1 min3(V3 v){return min(min(v.x,v.y),v.z);}
V1 max3(V3 v){return max(max(v.x,v.y),v.z);}

V1 pws(V1 x,V1 y) { return sign(x)*pow(abs(x),y); }

V3 star(V2 p, V1 t, V1 antiblur) {
    p *= 10.0;
    p = V2(5.0*atan(p.y, p.x),
           ((length(p)-10)/5.0+1.0)*2.5);
    // V1 v = p.y - 0.9*pws(exp(0.9*sin(p.x)), 0.85);
    V1 v = p.y - exp(1.1*(abs(cos(p.x/2))-abs(sin(p.x/2))));
    return hsv2rgb(V3(mod(2.2*t, 1.0), 0.6, clamp(-v*antiblur, 0, 1)));
}

V4 starz(V2 p, V1 t, V2 off, V1 antiblur) {
    p += sin(V2(401.29, -4.3)*off);
    V2 loc = floor(p/2.0+0.5) + off;
    p.x += -2.0*abs(cos(loc.y))*t;
    loc = floor(p/2.0+0.5) + off;
    p = mod(p+2.0, 4)-2.0;
    V4 c = V4(0.0);
    V1 sd = mod(2.0*cos(24.0*loc.x)+5.5*sin(31.0*loc.y), 1.0);
    p *= 4.0 + sin(49.0*sd);
    p += V2(cos(sd*52.5), sin(sd+200.0));
    if(sd <= 0.5) {
        V1 d = length(p),
           a = atan(p.y,p.x)+1.0/sd*2.0*sd*t*sin(2*PI*sd);
        p = d*V2(cos(a), sin(a));
        V1 tt = t/(5.0+2.0*sd) + 2.0*sd;
        V3 c1 = star(p/(1+0.005*antiblur), tt, sd+antiblur);
        V3 c2 = star((1.1+0.1*sd)*p, tt, sd+antiblur);
        c = clamp(
            V4(c1 - c2, length(c1)>=0.99 ?(length(c2)>=0.99 ?0.8: 1.0): 0.0),
            0, 1);
    }else{
        V1 tt = clamp(1-length(p)*10, 0, 1);
        V3 cc = hsv2rgb(V3(max(sd,0.2)*t+sd, 0.1+0.03*sd, tt));
        c = vec4(cc, 0.1*length(tt));
    }
    return c;
}

void main() {
    // V2 p = gl_FragCoord.xy / res;
    V2 p = gl_FragCoord.xy / min2(res);
    p -= V2(.5);
    p *= 2.0;
    
    p*=4.0;
    p += V2(-t,5.0);
    
    V4 c = V4(0);
    
    V1 c1 = 265.0/360.0; // rgb2hsv(V3(0.0,0.0,1.0));
    V1 c2 = 290.0/360.0; // rgb2hsv(V3(0.6,0.2,1.0));
    V1 D = mix(c1, c2, clamp(
        sin(p.y)*cos(p.x)+sin(p.y-0.5*cos(0.2*t))-0.2*cos(t)
        +2*cos(p.x+sin(p.y)-cos(t-p.x)*p.y)*sin(p.y*0.2+cos(0.05*p.y+mod(p.x,2*PI)))
        +cos(p.y-mod(p.x,2*PI))
    , 0, 1)
    )*1.0;
    V3 d = hsv2rgb(V3(D, 1.0, 0.9)) * 1.0;
    c += V4(d*0.025, 0.025);
    
    for(int i = 0; i < 200; i+=clamp(i/5,1,4)) {
        int o = i/3;
        V1 s = 0.001+o/22.5;
        c += (1-c)*(1-c.w)*starz(
            s*p, t,
            V2(3123.0*i, 25.0*i+1221.0-35.0*o), 2+o); }
    // c = V4(d, 1.0);
    c += (1-c)*V4(d*0.1,0.5);
    FragColor = V4(c.xyz*c.w, 1.0); }