#define PI 3.14159265359
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
// Balanced ray parameters for fire explosion
#define RAY_BRIGHTNESS 8.0
#define RAY_GAMMA 3.0
#define RAY_DENSITY 3.5
#define RAY_CURVATURE 10.0
#define RAY_RED 2.5
#define RAY_GREEN 1.0
#define RAY_BLUE 0.3

// Balanced fire explosion colors
const vec4 EXPLOSION_CORE1_COLOR = vec4(1.0, 0.95, 0.7, 1.0);   // White-hot core
const vec4 EXPLOSION_CORE2_COLOR = vec4(1.0, 0.85, 0.3, 1.0);   // Bright yellow
const vec4 EXPLOSION_HOT1_COLOR = vec4(1.0, 0.7, 0.2, 1.0);      // Yellow-orange 
const vec4 EXPLOSION_HOT2_COLOR = vec4(1.0, 0.5, 0.1, 1.0);      // Orange
const vec4 EXPLOSION_MID1_COLOR = vec4(1.0, 0.3, 0.0, 1.0);      // Orange-red
const vec4 EXPLOSION_MID2_COLOR = vec4(1.0, 0.2, 0.0, 1.0);      // Red
const vec4 EXPLOSION_COOL_COLOR = vec4(0.8, 0.1, 0.0, 1.0);      // Deep red

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

// Particle structure simulation
struct Particle {
    vec2 position;
    vec2 velocity;
    float lifetime;
    float size;
    vec3 color;
};

// Generate explosion particles
float explosionParticles(vec2 p, vec2 center, float radius, float time) {
    float effect = 0.0;
    const int NUM_PARTICLES = 32;
    
    for (int i = 0; i < NUM_PARTICLES; i++) {
        // Microscopic, very short-lived particles
        float seed = float(i) * 1.618;
        vec2 dir = normalize(vec2(random(vec2(seed, 1.0)), random(vec2(seed, 2.0))) * 2.0 - 1.0);
        float speed = 0.1 + random(vec2(seed, 3.0)) * 0.2; // Very slow particles
        float lifetime = 0.1 + random(vec2(seed, 4.0)) * 0.15; // Very short lifetime
        float size = 0.003 + random(vec2(seed, 5.0)) * 0.007; // Tiny particles
        
        // Particle physics
        vec2 pos = center + dir * radius * (time * speed);
        pos += dir * radius * (time * time * 0.5); // Acceleration
        pos += vec2(random(vec2(seed, 6.0)) - 0.5, 
                  random(vec2(seed, 7.0)) - 0.5) * radius * 0.1; // Jitter
        
        // Fade out over lifetime
        float age = clamp(time / lifetime, 0.0, 1.0);
        float fade = 1.0 - smoothstep(0.7, 1.0, age);
        
        // Particle rendering
        float dist = distance(p, pos);
        float particle = smoothstep(size, 0.0, dist) * fade;
        
        // Color based on particle age
        vec3 color = mix(
            vec3(1.0, 0.9, 0.3), // yellow
            vec3(1.0, 0.3, 0.0), // orange-red
            age
        );
        
        effect += particle * (0.5 + 0.5 * random(vec2(seed, 8.0)));
    }
    
    return clamp(effect, 0.0, 1.0);
}

float explosionRings(vec2 p, vec2 center, float radius) {
    float time = mod(iTime*3.0, 1.0); // Faster looping
    
    // Directional distance with more chaos
    vec2 offset = p - center;
    float angle = atan(offset.y, offset.x) + sin(iTime*10.0) * 0.5;
    float dist = length(offset) / radius;
    
    // Extreme directional bias with turbulence
    vec2 noiseDir = normalize(hash2(vec2(floor(angle*8.0), time*15.0)) * 2.0 - 1.0);
    float directionalBias = 0.3 + 0.7*pow(dot(normalize(offset), noiseDir), 3.0);
    
    float core = smoothstep(0.4, 0.0, dist) * 
                (1.0 + 0.5*sin(iTime*60.0 + angle*12.0)) * 
                (0.7 + 0.3*directionalBias) *
                (0.8 + 0.4*random(vec2(floor(angle*8.0), time*12.0)));
    
    // Chaotic shockwaves
    float shockwave = smoothstep(0.2, 0.0, abs(dist - (0.1 + 0.1*random(vec2(time, angle*5.0))))) * 
                     (0.5 + 0.5*sin(iTime*30.0 + angle*20.0));
    
    // More intense but fewer particles
    float particles = explosionParticles(p, center, radius, time) * 
                    (0.3 + 0.2*random(vec2(floor(dist*20.0), time)));
    
    // Combine effects
    float explosion = max(core, max(shockwave, particles));
    
    // Sharper fade out at edges
    explosion *= smoothstep(0.6, 0.4, dist);
    
    return clamp(explosion, 0.0, 1.0);
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
            // Half-sized explosion with extreme directional randomness
            float randSize = 0.075 + 0.175 * pow(random(vec2(iTime*3.0, centerCP.x)), 6.0); // More extreme size variation
            vec2 cursorRightBottom = centerCP + vec2(
                currentCursorData.z * 0.25, 
                currentCursorData.w * 0.25  // Positive Y for bottom on macOS
            );
            
            // Wild position jitter with directional chaos
            vec2 explosionPos = cursorRightBottom;
            vec2 jitterDir = normalize(hash2(vec2(iTime*0.5, centerCP.x*2.3)) * 4.0 - 2.0);
            explosionPos += jitterDir * 0.075 * pow(random(vec2(iTime*1.5, centerCP.x)), 3.0);
            
            // Multi-directional explosion with more extreme angles
            float explosion = 0.0;
            for (int j = 0; j < 4; j++) {
                vec2 dir = normalize(hash2(vec2(float(j)*2.71, iTime*0.7)) * 4.0 - 2.0);
                vec2 offsetPos = explosionPos + dir * 0.01 * (1.0 + random(vec2(float(j), iTime*2.0)));
                explosion += explosionRings(vu, offsetPos, randSize * (0.6 + 0.6*random(vec2(float(j)*3.0, iTime*1.5))));
            }
            explosion = clamp(explosion, 0.0, 1.0);
            
            // Create 6-10 micro booms with chaotic directions
            int numBooms = 6 + int(random(vec2(iTime*3.7, centerCP.y)) * 5.0);
            for (int i = 0; i < numBooms; i++) {
                // Direction clusters with random spread
                float cluster = floor(float(i)/2.0);
                vec2 baseDir = normalize(hash2(vec2(cluster*0.79, iTime*0.7)) * 2.0 - 1.0);
                float angle = atan(baseDir.y, baseDir.x) + (random(vec2(float(i), iTime)) - 0.5) * PI * 0.5;
                
                // Non-linear distance with directional bias
                float distance = mix(0.01, 0.12, pow(random(vec2(float(i), iTime*3.0)), 4.0));
                distance *= 1.0 + 0.5 * sin(iTime*5.0 + float(i)*2.0);
                
                // Position with turbulence
                vec2 boomPos = explosionPos;
                boomPos += vec2(cos(angle), sin(angle)) * randSize * distance;
                boomPos += hash2(vec2(float(i)*3.7, iTime*1.3)) * 0.03;
                
                // Wildly varying boom sizes (0.1-1.0 pixels)
                float boomSize = mix(0.1, 1.0, pow(random(vec2(float(i)*5.0, iTime*3.0)), 5.0));
                
                // Random color variation between yellow and red
                float colorMix = random(vec2(float(i), centerCP.x));
                vec4 boomColor = mix(
                    mix(EXPLOSION_CORE2_COLOR, EXPLOSION_HOT1_COLOR, 0.5),
                    mix(EXPLOSION_HOT2_COLOR, EXPLOSION_MID1_COLOR, 0.5),
                    colorMix
                );
                
                // Create the boom
                float boom = explosionRings(vu, boomPos, boomSize);
                
                // Apply color with some randomness
                float boomAlpha = boom * (1.0 - (progress * 0.5)) * 1.5;
                baseColor = mix(baseColor, boomColor, boomAlpha);
            }
            
            // Dynamic color based on explosion intensity
            vec3 fireColor = mix(
                vec3(1.0, 0.9, 0.3), // yellow core
                vec3(1.0, 0.2, 0.0), // red edges
                smoothstep(0.3, 0.7, explosion)
            );
            
            // Add glowing embers
            fireColor += vec3(0.8, 0.4, 0.1) * explosion * 0.5;
            
            float explosionAlpha = explosion * (1.0 - progress) * 2.0;
            baseColor.rgb = mix(baseColor.rgb, fireColor, explosionAlpha);
        }
    }
    
    fragColor = baseColor;
}
