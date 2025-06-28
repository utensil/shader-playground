// Standalone implementation of lightning and explosion cursor effects
// Uses pre-declared uniforms from the cursor system:
// iResolution, iTime, iCurrentCursor, iPreviousCursor, iTimeCursorChange, iChannel0

const vec4 LIGHTNING_CORE_COLOR = vec4(0.8, 0.9, 1.0, 1.0);
const vec4 LIGHTNING_EDGE_COLOR = vec4(0.4, 0.6, 1.0, 0.7);
// Inspired by https://www.shadertoy.com/view/4d2XR1
#define RAY_BRIGHTNESS 12.0
#define RAY_DENSITY 5.0
#define RAY_CURVATURE 18.0
#define RAY_RED 4.0
#define RAY_GREEN 1.0
#define RAY_BLUE 0.3

// Enhanced explosion color layers with ray-inspired colors
const vec4 EXPLOSION_CORE1_COLOR = vec4(1.0, 0.95, 0.6, 1.0);  // White-hot core
const vec4 EXPLOSION_CORE2_COLOR = vec4(RAY_RED*0.8, RAY_GREEN*0.8, RAY_BLUE*0.8, 1.0); // Ray-inspired
const vec4 EXPLOSION_HOT1_COLOR = vec4(1.0, 0.2, 0.0, 1.0);    // Intense red
const vec4 EXPLOSION_HOT2_COLOR = vec4(1.0, 0.4, 0.1, 0.9);    // Orange-red
const vec4 EXPLOSION_MID1_COLOR = vec4(1.0, 0.6, 0.2, 0.8);    // Orange
const vec4 EXPLOSION_MID2_COLOR = vec4(1.0, 0.8, 0.3, 0.7);    // Yellow-orange
const vec4 EXPLOSION_COOL_COLOR = vec4(0.9, 0.9, 0.5, 0.6);    // Yellow
const vec4 DEBRIS_COLOR = vec4(1.0, 0.85, 0.5, 1.0);           // Glowing debris
const vec4 SMOKE_COLOR = vec4(0.15, 0.15, 0.15, 0.8);         // Dark contrast smoke

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

// Noise function inspired by reference shader
float rayNoise(vec2 x) {
    return texture(iChannel0, x*.01).x;
}

// Flaring generator - inspired by reference shader
mat2 m2 = mat2(0.80, 0.60, -0.60, 0.80);
float rayFbm(vec2 p) {    
    float z = 2.0;
    float rz = -0.05;
    p *= 0.25;
    for (int i = 1; i < 6; i++) {
        rz += abs((rayNoise(p)-0.5)*2.)/z;
        z = z*1.8;
        p = p*2.0*m2;
    }
    return rz;
}

float explosionRings(vec2 p, vec2 center, float radius) {
    float d = 0.0;
    
    // Create organic shape with ray-inspired patterns
    vec2 uv = p - center;
    uv *= RAY_CURVATURE / radius;
    
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    
    // Add ray-inspired flaring
    float t = iTime * 0.33;
    float x = dot(normalize(uv), vec2(0.5,0.0)) + t;
    float y = dot(normalize(uv), vec2(0.0,0.5)) + t;
    float rays = rayFbm(vec2(y * RAY_DENSITY, x * RAY_DENSITY));
    rays = smoothstep(0.02-0.1, RAY_BRIGHTNESS+0.001, rays);
    
    // Base shape with noise distortion
    float shapeNoise = 0.5 + 0.5*sin(angle*10.0 + iTime*5.0) * 
                      (0.5 + 0.5*sin(dist*15.0 + iTime*3.0));
    float baseShape = smoothstep(radius*0.9, radius*0.1, dist * shapeNoise);
    
    // Shockwave with organic turbulence
    float shockwave = 1.0 - smoothstep(0.0, radius*0.9, dist);
    float turbulence = (sin(dist*25.0 - iTime*12.0) * 0.2 + 
                       sin(angle*8.0 + iTime*4.0) * 0.15) * 
                      smoothstep(radius, 0.0, dist);
    shockwave = smoothstep(0.2, 0.8, shockwave + turbulence);
    
    // Intense core flash with organic flicker
    float flicker = 0.7 + 0.3*sin(iTime*40.0 + dist*10.0);
    float core = smoothstep(radius*0.15, 0.0, dist) * 4.0 * flicker;
    d += core * (1.0 + 0.5*sin(angle*12.0 + iTime*8.0));
    
    // Asymmetric explosion lobes with directional bias
    float lobe1 = smoothstep(radius*0.5, radius*0.2, 
                           dist*(0.7 + 0.3*sin(iTime*5.0 + angle*3.0))) * 
                  (0.8 + 0.2*sin(angle*4.0 + iTime*2.0));
    float lobe2 = smoothstep(radius*0.6, radius*0.25, 
                           dist*(0.6 + 0.4*cos(iTime*3.0 + angle*5.0))) * 
                  (0.7 + 0.3*cos(angle*6.0 - iTime*1.5));
    float lobe3 = smoothstep(radius*0.8, radius*0.4, 
                           dist*(0.9 + 0.1*sin(iTime*7.0 + angle*7.0))) * 
                  (0.6 + 0.4*sin(angle*2.0 + iTime*3.0));
    
    // Combine lobes with ray effect
    d += max(lobe1, max(lobe2*0.8, lobe3*0.6)) + rays*0.5;
    
    // Debris with more randomness
    for(int i = 0; i < 30; i++) {  // Increased debris count
        // Create clustered ejection patterns
        float cluster = floor(float(i)/5.0);
        float rnd1 = random(vec2(float(i), iTime*0.3 + cluster));
        float rnd2 = random(vec2(float(i)*1.3, iTime*0.4 + cluster));
        
        // Bias directions based on cluster
        vec2 baseDir = vec2(sin(cluster*2.0), cos(cluster*1.5));
        vec2 dir = normalize(mix(
            vec2(rnd1-0.5, rnd2-0.5), 
            baseDir, 
            0.7
        ));
        
        // Particle movement with acceleration
        float speed = 0.5 + rnd1*0.5;
        float t = mod(iTime*(0.5 + rnd2), 1.0);
        vec2 debrisPos = center + dir * radius * (t * speed + t*t * 0.5);
        
        // More varied particle sizes
        float size = mix(0.01, 0.15, rnd1) * radius; // Wider size range
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
            // 10x smaller explosion size (0.03-0.07 of screen height)
            float randSize = 0.03 + 0.04 * random(vec2(iTime, centerCP.x));
            float explosion = explosionRings(vu, centerCP, iResolution.y * randSize);
            
            // Layered colors for different effects
            float coreMask = smoothstep(0.7, 1.0, explosion);
            float ringMask = smoothstep(0.3, 0.7, explosion);
            float debrisMask = smoothstep(0.1, 0.4, explosion);
            
            // More intense color blending
            vec4 explosionColor = EXPLOSION_CORE1_COLOR * coreMask * 3.5;
            explosionColor = mix(explosionColor, EXPLOSION_CORE2_COLOR, coreMask*2.5);
            explosionColor = mix(explosionColor, EXPLOSION_HOT1_COLOR, ringMask*2.5);
            explosionColor = mix(explosionColor, EXPLOSION_HOT2_COLOR, ringMask*2.0);
            explosionColor = mix(explosionColor, EXPLOSION_MID1_COLOR, ringMask*1.5);
            explosionColor = mix(explosionColor, EXPLOSION_MID2_COLOR, ringMask*1.0);
            explosionColor = mix(explosionColor, EXPLOSION_COOL_COLOR, ringMask*0.8);
            
            // Super-bright glowing debris
            vec4 debrisColor = DEBRIS_COLOR * (1.2 + 0.8*sin(iTime*12.0));
            explosionColor = mix(explosionColor, debrisColor, debrisMask*2.0);
            
            // Deep smoke for maximum contrast
            explosionColor = mix(explosionColor, SMOKE_COLOR, 
                               smoothstep(0.3, 0.6, explosion)*0.9);
            
            float explosionAlpha = explosion * (1.0 - progress) * 1.5;
            baseColor = mix(baseColor, explosionColor, explosionAlpha);
        }
    }
    
    fragColor = baseColor;
}
