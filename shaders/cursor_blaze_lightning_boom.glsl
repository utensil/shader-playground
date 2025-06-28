// Standalone implementation of lightning and explosion cursor effects
// Uses pre-declared uniforms from the cursor system:
// iResolution, iTime, iCurrentCursor, iPreviousCursor, iTimeCursorChange, iChannel0

// Color schemes - uncomment your preferred one
// Original blue-white scheme
//#define COLOR_SCHEME_BLUE
// Gold-purple scheme
#define COLOR_SCHEME_GOLD_PURPLE

#ifdef COLOR_SCHEME_GOLD_PURPLE
    const vec4 LIGHTNING_CORE_COLOR = vec4(1.0, 0.9, 0.2, 1.0);  // Gold core
    const vec4 LIGHTNING_EDGE_COLOR = vec4(0.7, 0.2, 1.0, 0.7); // Purple edges
#else
    const vec4 LIGHTNING_CORE_COLOR = vec4(0.8, 0.9, 1.0, 1.0);  // Blue-white core
    const vec4 LIGHTNING_EDGE_COLOR = vec4(0.4, 0.6, 1.0, 0.7);  // Blue edges
#endif
// Unified ray parameters for red/orange explosion
#define RAY_BRIGHTNESS 12.0
#define RAY_GAMMA 5.0
#define RAY_DENSITY 4.5
#define RAY_CURVATURE 15.0
#define RAY_RED 4.0
#define RAY_GREEN 0.0
#define RAY_BLUE 0.0

// Pure red/orange/yellow explosion colors
const vec4 EXPLOSION_CORE1_COLOR = vec4(1.0, 0.9, 0.1, 1.0);    // Bright yellow core
const vec4 EXPLOSION_CORE2_COLOR = vec4(1.0, 0.7, 0.1, 1.0);    // Yellow-orange
const vec4 EXPLOSION_HOT1_COLOR = vec4(1.0, 0.5, 0.0, 1.0);     // Orange
const vec4 EXPLOSION_HOT2_COLOR = vec4(1.0, 0.3, 0.0, 1.0);     // Red-orange
const vec4 EXPLOSION_MID1_COLOR = vec4(1.0, 0.2, 0.0, 1.0);     // Bright red
const vec4 EXPLOSION_MID2_COLOR = vec4(1.0, 0.1, 0.0, 1.0);     // Deep red
const vec4 EXPLOSION_COOL_COLOR = vec4(0.9, 0.05, 0.0, 1.0);    // Dark red
const vec4 DEBRIS_COLOR = vec4(1.0, 0.95, 0.8, 1.0);           // White-hot debris

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float distanceToLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// Inspired by https://www.shadertoy.com/view/XlsGWS
// Created by S.Guillitte (CC BY-NC-SA 3.0)

float hash(float x) {
    return fract(21654.6512 * sin(385.51 * x));
}

float hash(vec2 p) {
    return fract(sin(p.x*15.32+p.y*35.78) * 43758.23);
}

vec2 hash2(vec2 p) {
    return vec2(hash(p*.754),hash(1.5743*p.yx+4.5891))-.5;
}

vec2 noise2(vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 res = mix(mix(hash2(p), hash2(p + vec2(1.0,0.0)),f.x),
                   mix(hash2(p + vec2(0.0,1.0)), hash2(p + vec2(1.0,1.0)),f.x),f.y);
    return res;
}

float dseg(vec2 ba, vec2 pa) {
    float h = clamp(dot(pa,ba)/dot(ba,ba), -0.2, 1.);
    return length(pa - ba*h);
}

float arc(vec2 x, vec2 p, vec2 dir) {
    vec2 r = p;
    float d = 10.;
    for (int i = 0; i < 5; i++) {
        vec2 s = noise2(r+iTime)+dir;
        d = min(d,dseg(s,x-r));
        r += s;
    }
    return d*3.;
}

float lightningBranches(vec2 p, vec2 start, vec2 end, float width) {
    // Convert to reference shader's coordinate space
    vec2 x = (p - start) * 10.0;
    vec2 tgt = (end - start) * 10.0;
    
    vec2 r = tgt;
    float d = 1000.;
    float dist = length(tgt-x);
     
    // Main lightning path 
    for (int i = 0; i < 19; i++) {
        if(r.y > x.y + 5.0) break;  // Standard Y direction check
        vec2 s = (noise2(r+iTime)+vec2(0.0,0.7))*2.0;
        dist = dseg(s,x-r);
        d = min(d,dist);
        
        r += s;
        if(i-(i/5)*5==0) {
            if(i-(i/10)*10==0) d = min(d,arc(x,r,vec2(0.3,0.5)));
            else d = min(d,arc(x,r,vec2(-0.3,0.5)));
        }
    }
    
    float lightning = exp(-5.0*d) + 0.2*exp(-1.0*dist);
    return clamp(lightning, 0.0, 1.0);
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
    
    // Convert to reference shader's coordinate space
    vec2 uv = (p - center) * iResolution.y;
    uv *= RAY_CURVATURE * 0.1; // Adjusted curvature to match reference
    
    float t = -iTime * 0.33; // Negative time to match reference direction
    float r = sqrt(dot(uv,uv));
    float x = dot(normalize(uv), vec2(0.5,0.0)) + t;
    float y = dot(normalize(uv), vec2(0.0,0.5)) + t;
    
    // Generate flaring effect from reference
    float rays = rayFbm(vec2(y * RAY_DENSITY, x * RAY_DENSITY));
    rays = smoothstep(RAY_GAMMA*0.02-0.1, RAY_BRIGHTNESS+0.001, rays);
    rays = sqrt(rays);
    
    // Base shape with noise distortion
    float angle = atan(uv.y, uv.x);
    float dist = length(uv);
    float shapeNoise = 0.5 + 0.5*sin(angle*10.0 + iTime*5.0) * 
                      (0.5 + 0.5*sin(dist*15.0 + iTime*3.0));
    float baseShape = smoothstep(radius*0.9, radius*0.1, dist * shapeNoise);
    
    // Shockwave with organic turbulence
    float shockwave = 1.0 - smoothstep(0.0, radius*0.9, dist);
    float turbulence = (sin(dist*25.0 - iTime*12.0) * 0.2 + 
                       sin(angle*8.0 + iTime*4.0) * 0.15) * 
                      smoothstep(radius, 0.0, dist);
    shockwave = smoothstep(0.2, 0.8, shockwave + turbulence);
    
    // More intense and random core flash
    float flicker = 0.6 + 0.4*sin(iTime*50.0 + dist*15.0 + random(vec2(angle, iTime)));
    float core = smoothstep(radius*0.15, 0.0, dist) * 5.0 * flicker;
    d += core * (1.0 + 0.7*sin(angle*15.0 + iTime*10.0));
    
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
        
        // Fixed pixel-based particle sizes (2-15 pixels)
        float size = mix(2.0, 15.0, rnd1); 
        d += smoothstep(size, 0.0, distance(p, debrisPos)) * 0.4;
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
            // Lightning strikes from top of screen (y = 1.0 in normalized coords)
            vec2 lightningStart = vec2(centerCC.x, 1.0);
            // Invert Y coordinate for macOS in the lightning calculation
            vec2 lightningVu = vec2(vu.x, -vu.y);
            vec2 lightningCC = vec2(centerCC.x, -centerCC.y);
            float lightning = lightningBranches(lightningVu, lightningStart, lightningCC, 0.01);
            
            // Core lightning color with optional glow
            vec4 lightningColor = mix(LIGHTNING_EDGE_COLOR, LIGHTNING_CORE_COLOR, lightning);
            #ifdef COLOR_SCHEME_GOLD_PURPLE
                // Add golden glow for this scheme
                lightningColor.rgb += vec3(0.1, 0.08, 0.0) * lightning * 0.5;
            #endif
            float lightningAlpha = lightning * (1.0 - progress) * 1.2;
            
            baseColor = mix(baseColor, lightningColor, lightningAlpha);
        }
        // Explosion effect when moving left
        else {
            // Explosion with extreme size variance (100-400 pixels)
            float randSize = 100.0 + 300.0 * pow(random(vec2(iTime, centerCP.x)), 2.0);
            vec2 cursorRightBottom = centerCP + vec2(
                currentCursorData.z * 0.5, 
                currentCursorData.w * 0.5  // Positive Y for bottom on macOS
            );
            vec2 explosionPos = cursorRightBottom;
            float explosion = explosionRings(vu, explosionPos, randSize);
            
            // Apply reference shader's color inversion
            vec3 col = vec3(RAY_RED, RAY_GREEN, RAY_BLUE);
            col = 1.0 - col;
            
            // Layered colors for different effects
            float coreMask = smoothstep(0.7, 1.0, explosion);
            float ringMask = smoothstep(0.3, 0.7, explosion);
            float debrisMask = smoothstep(0.1, 0.4, explosion);
            
            // More vibrant and random color blending
            float colorRand = random(vec2(iTime, centerCP.x));
            vec4 explosionColor = EXPLOSION_CORE1_COLOR * coreMask * 4.0;
            
            // Chaotic red/orange mixing with more randomness
            float mixFactor1 = random(vec2(colorRand, iTime*0.1));
            float mixFactor2 = random(vec2(colorRand*1.3, iTime*0.2));
            
            explosionColor = mix(
                mix(EXPLOSION_CORE2_COLOR, EXPLOSION_HOT1_COLOR, mixFactor1),
                mix(EXPLOSION_HOT2_COLOR, EXPLOSION_MID1_COLOR, mixFactor2),
                ringMask*3.0
            );
            
            // Add some orange highlights
            if (random(vec2(colorRand, iTime*0.3)) > 0.3) {
                explosionColor = mix(explosionColor, EXPLOSION_MID2_COLOR, ringMask*1.5);
            }
            
            // Add random color accents
            if (colorRand > 0.7) {
                explosionColor.r += 0.3 * ringMask;
            }
            
            // Super-bright glowing debris
            vec4 debrisColor = DEBRIS_COLOR * (1.2 + 0.8*sin(iTime*12.0));
            explosionColor = mix(explosionColor, debrisColor, debrisMask*2.0);
            
            // Longer duration (0.2s instead of 0.1s) and brighter colors
            float explosionAlpha = explosion * (1.0 - (progress * 0.5)) * 2.0;
            baseColor = mix(baseColor, explosionColor, explosionAlpha);
        }
    }
    
    fragColor = baseColor;
}
