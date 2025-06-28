// Standalone implementation of lightning and explosion cursor effects
uniform vec3 iResolution;
uniform float iTime;
uniform vec4 iCurrentCursor;
uniform vec4 iPreviousCursor;
uniform float iTimeCursorChange;

const vec4 LIGHTNING_CORE_COLOR = vec4(0.8, 0.9, 1.0, 1.0);
const vec4 LIGHTNING_EDGE_COLOR = vec4(0.4, 0.6, 1.0, 0.7);
const vec4 EXPLOSION_CORE_COLOR = vec4(1.0, 0.9, 0.7, 1.0);
const vec4 EXPLOSION_RING1_COLOR = vec4(1.0, 0.3, 0.1, 0.8);
const vec4 EXPLOSION_RING2_COLOR = vec4(1.0, 0.6, 0.2, 0.6);
const vec4 EXPLOSION_RING3_COLOR = vec4(0.8, 0.9, 0.3, 0.4);

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float distanceToLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float lightningBranches(vec2 p, vec2 start, vec2 end, float width) {
    float d = 0.0;
    vec2 dir = normalize(end - start);
    vec2 perp = vec2(-dir.y, dir.x);
    
    // Main lightning path
    float mainDist = distanceToLine(p, start, end);
    d = smoothstep(width, 0.0, mainDist);
    
    // Add branches
    float branchCount = 5.0;
    for(float i = 0.0; i < branchCount; i++) {
        float t = random(vec2(i, iTime)) * 0.5 + 0.3;
        vec2 branchStart = mix(start, end, t);
        vec2 branchEnd = branchStart + perp * (random(vec2(i+1.0, iTime)) * 0.2 - 0.1) * length(end - start);
        d += smoothstep(width*0.5, 0.0, distanceToLine(p, branchStart, branchEnd)) * 0.5;
    }
    
    return clamp(d, 0.0, 1.0);
}

float explosionRings(vec2 p, vec2 center, float radius) {
    float d = 0.0;
    float dist = distance(p, center);
    
    // Core flash
    d += smoothstep(radius*0.1, 0.0, dist) * 2.0;
    
    // Rings
    d += smoothstep(radius*0.3, radius*0.2, dist) * 0.8;
    d += smoothstep(radius*0.5, radius*0.4, dist) * 0.6;
    d += smoothstep(radius*0.8, radius*0.7, dist) * 0.4;
    
    // Debris effect
    for(int i = 0; i < 10; i++) {
        vec2 dir = vec2(sin(float(i)*123.456), cos(float(i)*321.654));
        vec2 debrisPos = center + dir * radius * (0.5 + 0.5*sin(iTime*5.0 + float(i)));
        d += smoothstep(radius*0.05, 0.0, distance(p, debrisPos)) * 0.3;
    }
    
    return clamp(d, 0.0, 1.0);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}

float blend(float t) {
    float sqr = t * t;
    return sqr / (2.0 * (sqr - t) + 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Start with a transparent background
    vec4 baseColor = vec4(0.0);
    
    vec2 vu = normalize(fragCoord, 1.);
    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));
    
    float progress = blend(clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0));
    
    if (progress < 1.0) {
        vec2 centerCC = getRectangleCenter(currentCursor);
        vec2 centerCP = getRectangleCenter(previousCursor);
        float lineLength = distance(centerCC, centerCP);
        
        // Lightning effect when moving right
        if (currentCursor.x > previousCursor.x) {
            float lightning = lightningBranches(vu, centerCP, centerCC, 0.01);
            vec4 lightningColor = mix(LIGHTNING_EDGE_COLOR, LIGHTNING_CORE_COLOR, lightning);
            baseColor = mix(baseColor, lightningColor, lightning * (1.0 - progress));
        } 
        // Explosion effect when moving left
        else {
            float explosion = explosionRings(vu, centerCP, lineLength * 0.5);
            vec4 explosionColor = mix(
                mix(EXPLOSION_RING3_COLOR, EXPLOSION_RING2_COLOR, explosion),
                mix(EXPLOSION_RING2_COLOR, EXPLOSION_RING1_COLOR, explosion),
                explosion
            );
            explosionColor = mix(explosionColor, EXPLOSION_CORE_COLOR, smoothstep(0.5, 1.0, explosion));
            baseColor = mix(baseColor, explosionColor, explosion * (1.0 - progress));
        }
    }
    
    fragColor = baseColor;
}
