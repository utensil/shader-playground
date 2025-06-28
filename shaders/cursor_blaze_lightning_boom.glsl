// Standalone implementation of lightning and explosion cursor effects
// Uses pre-declared uniforms from the cursor system:
// iResolution, iTime, iCurrentCursor, iPreviousCursor, iTimeCursorChange, iChannel0

const vec4 LIGHTNING_CORE_COLOR = vec4(0.8, 0.9, 1.0, 1.0);
const vec4 LIGHTNING_EDGE_COLOR = vec4(0.4, 0.6, 1.0, 0.7);
const vec4 EXPLOSION_CORE_COLOR = vec4(1.0, 0.95, 0.8, 1.0);
const vec4 EXPLOSION_RING1_COLOR = vec4(1.0, 0.5, 0.1, 0.9);
const vec4 EXPLOSION_RING2_COLOR = vec4(1.0, 0.7, 0.3, 0.7);
const vec4 EXPLOSION_RING3_COLOR = vec4(0.9, 0.9, 0.5, 0.5);
const vec4 DEBRIS_COLOR = vec4(0.8, 0.7, 0.6, 1.0);
const vec4 SMOKE_COLOR = vec4(0.3, 0.3, 0.3, 0.5);

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
    
    // Shockwave with turbulence
    float shockwave = 1.0 - smoothstep(0.0, radius*0.9, dist);
    float turbulence = sin(dist*20.0 - iTime*10.0) * 0.1;
    shockwave = smoothstep(0.3, 0.7, shockwave + turbulence);
    
    // Core flash with flicker
    float flicker = 0.8 + 0.2*sin(iTime*30.0);
    d += smoothstep(radius*0.1, 0.0, dist) * 3.0 * flicker;
    
    // Multi-layered rings with varying speeds
    d += smoothstep(radius*0.3, radius*0.2, dist*(0.9 + 0.1*sin(iTime*5.0))) * 0.8;
    d += smoothstep(radius*0.5, radius*0.4, dist*(0.8 + 0.2*cos(iTime*3.0))) * 0.6;
    d += smoothstep(radius*0.8, radius*0.7, dist*(1.1 + 0.1*sin(iTime*7.0))) * 0.4;
    
    // Debris effect with more randomness
    for(int i = 0; i < 20; i++) {
        // Random direction and speed for each particle
        float rnd1 = random(vec2(float(i), iTime*0.3));
        float rnd2 = random(vec2(float(i)*1.3, iTime*0.4));
        vec2 dir = normalize(vec2(rnd1-0.5, rnd2-0.5));
        
        // Particle movement with acceleration
        float speed = 0.5 + rnd1*0.5;
        float t = mod(iTime*(0.5 + rnd2), 1.0);
        vec2 debrisPos = center + dir * radius * (t * speed + t*t * 0.5);
        
        // Varying particle sizes
        float size = mix(0.02, 0.08, rnd1) * radius;
        d += smoothstep(size, 0.0, distance(p, debrisPos)) * 0.4;
    }
    
    // Smoke wisps
    for(int i = 0; i < 10; i++) {
        float rnd = random(vec2(float(i), iTime*0.2));
        vec2 dir = vec2(sin(float(i)*1.5), cos(float(i)*1.3));
        float offset = 0.3 + 0.7*rnd;
        vec2 smokePos = center + dir * radius * offset * (0.5 + 0.5*sin(iTime*2.0));
        
        // Animated smoke density
        float density = 0.5 + 0.5*sin(iTime*3.0 + float(i));
        float smoke = smoothstep(radius*0.1, 0.0, distance(p, smokePos)) * density;
        d = mix(d, d*0.7, smoke);
    }
    
    return clamp(d * shockwave, 0.0, 1.0);
}

vec2 normalizeCoord(vec2 value, float isPosition) {
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
    // Start with background texture
    vec4 baseColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    
    vec2 vu = normalizeCoord(fragCoord, 1.);
    vec4 currentCursorData = vec4(normalizeCoord(iCurrentCursor.xy, 1.), normalizeCoord(iCurrentCursor.zw, 0.));
    vec4 previousCursorData = vec4(normalizeCoord(iPreviousCursor.xy, 1.), normalizeCoord(iPreviousCursor.zw, 0.));
    
    float progress = blend(clamp((iTime - iTimeCursorChange) / 0.1, 0.0, 1.0));
    
    if (progress < 1.0) {
        vec2 centerCC = getRectangleCenter(currentCursorData);
        vec2 centerCP = getRectangleCenter(previousCursorData);
        float lineLength = distance(centerCC, centerCP);
        
        // Lightning effect when moving right
        if (currentCursorData.x > previousCursorData.x) {
            float lightning = lightningBranches(vu, centerCP, centerCC, 0.01);
            vec4 lightningColor = mix(LIGHTNING_EDGE_COLOR, LIGHTNING_CORE_COLOR, lightning);
            float lightningAlpha = lightning * (1.0 - progress) * 0.7; // Reduced intensity
            baseColor = mix(baseColor, lightningColor, lightningAlpha);
        } 
        // Explosion effect when moving left
        else {
            float explosion = explosionRings(vu, centerCP, lineLength * 0.5);
            
            // Layered colors for different effects
            float coreMask = smoothstep(0.7, 1.0, explosion);
            float ringMask = smoothstep(0.3, 0.7, explosion);
            float debrisMask = smoothstep(0.1, 0.4, explosion);
            
            vec4 explosionColor = EXPLOSION_CORE_COLOR * coreMask;
            explosionColor = mix(explosionColor, EXPLOSION_RING1_COLOR, ringMask);
            explosionColor = mix(explosionColor, EXPLOSION_RING2_COLOR, ringMask*0.7);
            explosionColor = mix(explosionColor, EXPLOSION_RING3_COLOR, ringMask*0.3);
            explosionColor = mix(explosionColor, DEBRIS_COLOR, debrisMask);
            explosionColor = mix(explosionColor, SMOKE_COLOR, smoothstep(0.2, 0.5, explosion));
            
            float explosionAlpha = explosion * (1.0 - progress) * 0.9;
            baseColor = mix(baseColor, explosionColor, explosionAlpha);
        }
    }
    
    fragColor = baseColor;
}
