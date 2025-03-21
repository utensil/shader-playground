
#ifdef GL_ES
precision mediump float;
#endif

uniform float u_time;
uniform vec2 u_resolution;
uniform vec4 iCursorCurrent;
uniform vec4 iCursorPrevious;
uniform float iTimeCursorChange;

float distanceToSegment(vec2 a, vec2 b, vec2 p)
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float sdBox(in vec2 p, in vec2 b)
{
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 iResolution = u_resolution;
    float iTime = u_time;

    //Normalization
    vec2 vu = fragCoord / iResolution.xy;
    //Aspect ration fix
    vu.x *= iResolution.x / iResolution.y;

    // Normalize cursor coordinates
    //xy: bottom-right point, zw top-left point
    vec4 cc = vec4(iCursorCurrent.xy / iResolution.xy, (iCursorCurrent.xy + iCursorCurrent.zw) / iResolution.xy);
    vec4 cp = vec4(iCursorPrevious.xy / iResolution.xy, (iCursorPrevious.xy + iCursorPrevious.zw) / iResolution.xy);

    // Apply aspect ratio correction
    cc.x *= iResolution.x / iResolution.y;
    cc.z *= iResolution.x / iResolution.y;
    cp.x *= iResolution.x / iResolution.y;
    cp.z *= iResolution.x / iResolution.y;

    fragColor = vec4(cos(iTime), vu.x, vu.y, 1.);

    if (vu.x > cc.x && vu.y > cc.y && vu.x < cc.z && vu.y < cc.w) {
        fragColor = vec4(1., 0., 0., 1.);
    }
    float d = sdBox(vu, cc.zw);
    if (step(0.1, d) == 1.) {
        fragColor = vec4(1., 1., 0., 1.);
    }

    // vec2 p = fragCoord / iResolution.x;
    //
    // vec4 current = vec4(0.2, 0.2, 10., 20.);
    // vec4 previous = vec4(.8, .8, 10., 20.);
    //
    // // Adjust coordinates based on aspect ratio
    // // current.x *= iResolution.x / iResolution.y;
    // previous.y *= iResolution.y / iResolution.x;
    // current.y *= iResolution.y / iResolution.x;
    //
    // vec3 col = vec3(0.);
    //
    // float d = distanceToSegment(previous.xy, abs(current.xy), p);
    // col = mix(col, vec3(1.0, 7.0, 0.0), 1.0 - smoothstep(.004, 0.058, d));
    //
    // col = mix(col, vec3(1.0, 0.0, 0.0), 1.0 - smoothstep(0.03, 0.035, length(p - previous.xy)));
    // col = mix(col, vec3(0.0, 0.0, 1.0), 1.0 - smoothstep(0.03, 0.035, length(p - abs(current.xy))));
    //
    // float alphaDistance = distance(p.xy, previous.xy) * 10.;
    // float alpha = abs(sin(iTime)) * alphaDistance;
    //
    // fragColor = mix(vec4(col, 1.0), fragColor, alpha);
}
void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
