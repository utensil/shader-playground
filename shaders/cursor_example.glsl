#ifdef GL_ES
precision mediump float;
#endif

uniform float u_time;
uniform vec2 u_resolution;
uniform vec4 iCursorCurrent;
uniform vec4 iCursorPrevious;
uniform float iTimeCursorChange;

float sdBox(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// //Author: https://iquilezles.org/articles/distfunctions2d/
// float sdParallelogram(in vec2 p, float wi, float he, float sk)
// {
//     vec2 e = vec2(sk, he);
//     p = (p.y < 0.0) ? -p : p;
//     vec2 w = p - e;
//     w.x -= clamp(w.x, -wi, wi);
//     vec2 d = vec2(dot(w, w), -w.y);
//     float s = p.x * e.y - p.y * e.x;
//     p = (s < 0.0) ? -p : p;
//     vec2 v = p - vec2(wi, 0);
//     v -= e * clamp(dot(v, e) / dot(e, e), -1.0, 1.0);
//     d = min(d, vec2(dot(v, v), wi * he - abs(s)));
//     return sqrt(d.x) * sign(-d.y);
// }
float sdfParallelogram(vec2 p, vec2 origin, vec2 a, vec2 b) {
    // Calculate the determinant of the basis vectors matrix
    float det = a.x * b.y - a.y * b.x;

    // Translate the point so that the parallelogram's origin is at (0, 0)
    vec2 p_prime = p - origin;

    // Transform the point to the unit square's coordinate system
    float u = (p_prime.x * b.y - p_prime.y * b.x) / det;
    float v = (-p_prime.x * a.y + p_prime.y * a.x) / det;

    // Calculate the signed distance to the unit square [0, 1] x [0, 1]
    vec2 d = abs(vec2(u, v) - 0.5) - 0.5;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

vec2 normalize(vec2 value, float isPosition, vec3 iResolution) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float sdParallelogram(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    vec2 h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0) * ba - pa;

    vec2 perp = vec2(-ba.y, ba.x); // Perpendicular to b
    vec2 h2 = clamp(dot(pa, perp) / dot(perp, perp), -1.0, 1.0) * perp - pa;

    return min(length(h), length(h2));
}

float antialising(float distance, vec3 iResolution) {
    return 1. - smoothstep(0., normalize(vec2(2., 2.), 0., iResolution).x, distance);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 iResolution = vec3(u_resolution, 0.);
    float iTime = u_time;

    //Normalization
    vec2 vu = normalize(fragCoord, 1., iResolution);

    //xy will have the normalized position of the center of the cursor, and zw, the width and height normalized too
    vec4 currentCursor = vec4(normalize(iCursorCurrent.xy, 1., iResolution), normalize(iCursorCurrent.zw, 0., iResolution));
    vec4 previousCursor = vec4(normalize(iCursorPrevious.xy, 1., iResolution), normalize(iCursorPrevious.zw, 0., iResolution));

    vec2 offsetFactor = vec2(-.5, 0.5);
    float cCursorDistance = sdBox(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
    fragColor = mix(fragColor, vec4(1., 0., 1., 1.), step(cCursorDistance, .0));

    float pCursorDistance = sdBox(vu, previousCursor.xy - (previousCursor.zw * offsetFactor), previousCursor.zw * 0.5);
    fragColor = mix(fragColor, vec4(.87, .87, .87, 1.), step(pCursorDistance, .0));

    float d = sdfParallelogram(vu, currentCursor.xy, vec2(0.1, 0), vec2(0., .5));

    fragColor = mix(fragColor, vec4(1., 1., 1., 1.), step(d, .0));
}
void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
