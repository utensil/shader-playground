// Classic Perlin noise helper functions

/* ORIGINAL WORKING IMPLEMENTATION
// Cursor Blaze Lightning Effect Implementation

// Requirements
// 1. Activation Condition
// - Triggered exclusively when:
//   - Cursor moves left-to-right on same line
//   - Movement indicates typing/copy-paste activity
//   - Horizontal delta > vertical delta

// 2. Origin Zone
// - Narrow top-screen region parameters:
//   - Base width = cursor horizontal distance traveled
//   - Constrained by ratio (0.2-0.4 recommended)
//   - Final width = min(base_width * ratio, max_screen_percentage)

// 3. Lightning Path Generation
// - Branch characteristics:
//   - 3-5 primary branches
//   - Random origin points within origin zone
//   - Perlin noise-driven trembling (frequency: 8-12Hz)
//   - Fractal Brownian Motion (FBM) for organic zigzag
//   - Merge point randomization:
//     - Vertical position range: 25-75% screen height
//     - Horizontal position bias: 70% toward cursor

// 4. Color Profile
// - Core components:
//   - Main channel: HSB(45°, 90%, 100%)
//   - Edge effect: RGB(0.7, 0.2, 1.0) with distance falloff
//   - Color mixing:
//     float t = smoothstep(0.0, 0.2, distance_from_core);
//     vec3 final_color = mix(core_color, edge_color, t);

// 5. Implementation Strategy
// - Particle system requirements:
//   - GPU-driven via compute shader
//   - Mode 4 isolation (existing modes 0-3 untouched)
//   - Dynamic buffers:
//     - Branch paths (SSBO)
//     - Lightning state (UBO)
*/

// Original working implementation starts here:

// Existing functions from original file
float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);

    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);

    return s * sqrt(d);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float blend(float t)
{
    float sqr = t * t;
    return sqr / (2.0 * (sqr - t) + 1.0);
}

float antialising(float distance) {
    return 1. - smoothstep(0., normalize(vec2(2., 2.), 0.).x, distance);
}

float determineStartVertexFactor(vec2 a, vec2 b) {
    float condition1 = step(b.x, a.x) * step(a.y, b.y);
    float condition2 = step(a.x, b.x) * step(b.y, a.y);
    return 1.0 - max(condition1, condition2);
}
vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}

// Classic Perlin noise implementations
float cnoise(vec2 P) {
    vec3 Pi = floor(vec3(P.xyx)) + vec3(0.0, 0.0, 1.0);
    vec3 Pf = fract(vec3(P.xyx)) - vec3(0.0, 0.0, 1.0);
    Pi = mod(Pi, 289.0);
    vec4 ix = vec4(Pi.x, Pi.z, Pi.x, Pi.z);
    vec4 iy = vec4(Pi.yy, Pi.yy + 1.0);
    vec4 fx = vec4(Pf.x, Pf.z, Pf.x, Pf.z);
    vec4 fy = vec4(Pf.yy, Pf.yy + 1.0);
    
    vec4 i = permute(permute(ix) + iy);
    vec4 gx = fract(i / 41.0) * 2.0 - 1.0;
    vec4 gy = abs(gx) - 0.5;
    vec4 tx = floor(gx + 0.5);
    gx = gx - tx;
    
    vec2 g00 = vec2(gx.x, gy.x);
    vec2 g10 = vec2(gx.y, gy.y);
    vec2 g01 = vec2(gx.z, gy.z);
    vec2 g11 = vec2(gx.w, gy.w);
    
    float norm00 = dot(g00, g00);
    float norm01 = dot(g01, g01);
    float norm10 = dot(g10, g10);
    float norm11 = dot(g11, g11);
    
    g00 *= inversesqrt(norm00);
    g01 *= inversesqrt(norm01);
    g10 *= inversesqrt(norm10);
    g11 *= inversesqrt(norm11);
    
    float n00 = dot(g00, vec2(fx.x, fy.x));
    float n10 = dot(g10, vec2(fx.y, fy.y));
    float n01 = dot(g01, vec2(fx.z, fy.z));
    float n11 = dot(g11, vec2(fx.w, fy.w));
    
    vec2 fade_xy = fade(Pf.xy);
    vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
    float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}

vec4 permute(vec4 x) {
    return mod(((x*34.0)+1.0)*x, 289.0);
}
vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}
vec3 fade(vec3 t) {
    return t*t*t*(t*(t*6.0-15.0)+10.0);
}
float cnoise(vec3 P) {
    vec3 Pi0 = floor(P);
    vec3 Pi1 = Pi0 + vec3(1.0);
    Pi0 = mod(Pi0, 289.0);
    Pi1 = mod(Pi1, 289.0);
    vec3 Pf0 = fract(P);
    vec3 Pf1 = Pf0 - vec3(1.0);
    vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
    vec4 iy = vec4(Pi0.yy, Pi1.yy);
    vec4 iz0 = Pi0.zzzz;
    vec4 iz1 = Pi1.zzzz;
    
    vec4 ixy = permute(permute(ix) + iy);
    vec4 ixy0 = permute(ixy + iz0);
    vec4 ixy1 = permute(ixy + iz1);
    
    vec4 gx0 = ixy0 / 7.0;
    vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
    gx0 = fract(gx0);
    vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
    vec4 sz0 = step(gz0, vec4(0.0));
    gx0 -= sz0 * (step(0.0, gx0) - 0.5);
    gy0 -= sz0 * (step(0.0, gy0) - 0.5);
    
    vec4 gx1 = ixy1 / 7.0;
    vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
    gx1 = fract(gx1);
    vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
    vec4 sz1 = step(gz1, vec4(0.0));
    gx1 -= sz1 * (step(0.0, gx1) - 0.5);
    gy1 -= sz1 * (step(0.0, gy1) - 0.5);
    
    vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
    vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
    vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
    vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
    vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
    vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
    vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
    vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);
    
    vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
    g000 *= norm0.x;
    g010 *= norm0.y;
    g100 *= norm0.z;
    g110 *= norm0.w;
    vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
    g001 *= norm1.x;
    g011 *= norm1.y;
    g101 *= norm1.z;
    g111 *= norm1.w;
    
    float n000 = dot(g000, Pf0);
    float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
    float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
    float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
    float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
    float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
    float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
    float n111 = dot(g111, Pf1);
    
    vec3 fade_xyz = fade(Pf0);
    vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
    vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
    float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
    return 2.2 * n_xyz;
}

// Lightning constants
const int MAX_BRANCHES = 5;
const float BRANCH_WIDTH = 0.01;
const float NOISE_FREQ = 10.0;
const vec3 CORE_COLOR = vec3(1.0, 0.8, 0.2);
const vec3 EDGE_COLOR = vec3(0.7, 0.2, 1.0);

// Lightning branch function with noise
float drawLightningBranch(vec2 p, vec2 a, vec2 b, float width, float time) {
    vec2 dir = normalize(b - a);
    vec2 normal = vec2(-dir.y, dir.x);
    
    // Add Perlin noise trembling
    float noise = cnoise(vec3(p * NOISE_FREQ, time * 10.0)) * 0.02;
    
    // Calculate distance with noise offset
    float d = dot(p - a + noise, normal);
    return smoothstep(width, 0.0, abs(d));
}

// Fractal Brownian Motion for organic paths
float fbm(vec2 p) {
    float amp = 0.5;
    float noise = 0.0;
    for(int i=0; i<3; i++) {
        noise += amp * cnoise(p * exp2(float(i)));
        amp *= 0.5;
    }
    return noise;
}

const vec4 TRAIL_COLOR = vec4(1.0, 0.725, 0.161, 1.0);
const vec4 TRAIL_COLOR_ACCENT = vec4(1.0, 0., 0., 1.0);
const vec4 CURRENT_CURSOR_COLOR = TRAIL_COLOR;
const vec4 PREVIOUS_CURSOR_COLOR = TRAIL_COLOR;
const float DURATION = 0.1;

/* LIGHTNING EFFECT CONSTANTS (COMMENTED OUT)
const bool USE_LIGHTNING = true;
const vec4 LIGHTNING_COLOR = vec4(0.0, 0.5, 1.0, 1.0);
const float LIGHTNING_WIDTH = 0.02;
const float LIGHTNING_SPEED = 2.0;
const float SPARSE_LEVEL = 0.3;
*/

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif
    
    vec4 newColor = vec4(fragColor);
    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);
    
    // Get cursor positions
    vec2 prev_pos = iCurrentCursor.xy;
    vec2 curr_pos = iCurrentCursor.zw;
    
    // Debug cursor positions (commented out for now)
    // if (distance(fragCoord, vec2(20,40)) < 10.0) {
    //     newColor.rgb = vec3(prev_pos.x/iResolution.x, prev_pos.y/iResolution.y, 0);
    // }
    // if (distance(fragCoord, vec2(20,60)) < 10.0) {
    //     newColor.rgb = vec3(curr_pos.x/iResolution.x, curr_pos.y/iResolution.y, 0);
    // }
    

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    float invertedVertexFactor = 1.0 - vertexFactor;

    vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
    vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
    vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
    vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);
    
    float progress = blend(clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0));

    vec2 centerCC = getRectangleCenter(currentCursor);
    vec2 centerCP = getRectangleCenter(previousCursor);
    float lineLength = distance(centerCC, centerCP);
    float distanceToEnd = distance(vu.xy, centerCC);
    float alphaModifier = distanceToEnd / (lineLength * (1.0 - progress));

    float sdfCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
    float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

    if (progress < 1.0) {
        vec2 trailAxis = v3 - v0;
        float trailLength = length(trailAxis);
        
        vec2 toFragment = vu.xy - v0;
        float t = dot(toFragment, trailAxis) / (trailLength * trailLength);
        t = clamp(t, 0.0, 1.0);
        
        float gradient = 1.0 - t;
        gradient = smoothstep(0.0, 1.0, gradient);
        
        float trailAlpha = 1.0 - smoothstep(sdfTrail, -0.01, 0.001);
        trailAlpha *= gradient;
        
        newColor = mix(newColor, TRAIL_COLOR_ACCENT, trailAlpha);
        newColor = mix(newColor, TRAIL_COLOR, trailAlpha);
        newColor = mix(newColor, TRAIL_COLOR, antialising(sdfTrail) * gradient);
    }
    
    newColor = mix(newColor, CURRENT_CURSOR_COLOR, 1.0 - smoothstep(sdfCursor, -0.000, 0.003 * (1. - progress)));
    // Lightning activation check
    float delta_x = curr_pos.x - prev_pos.x;
    float delta_y = abs(curr_pos.y - prev_pos.y);
    bool should_lightning = delta_x > 0.0 && delta_y < 2.0;
    
    // Lightning effect
    if (should_lightning) {
        float screen_width = iResolution.x;
        float travel_dist = curr_pos.x - prev_pos.x;
        float zone_width = min(travel_dist * 0.3, screen_width * 0.4);
        float zone_top = iResolution.y * 0.1;
        
        // Generate random branch origins in top zone
        for (int i = 0; i < MAX_BRANCHES; i++) {
            float rand = fract(sin(float(i)*12.9898) * 43758.5453);
            vec2 origin = vec2(
                prev_pos.x + rand * zone_width,
                zone_top
            );
            
            // Calculate merge point (70% toward cursor)
            float merge_x = mix(origin.x, curr_pos.x, 0.7);
            float merge_y = mix(iResolution.y * 0.25, iResolution.y * 0.75, 
                               fract(sin(float(i)*78.233) * 126.5453));
            
            // Add FBM to path for organic movement
            vec2 mid = mix(origin, vec2(merge_x, merge_y), 0.5);
            mid += vec2(fbm(mid + iTime), fbm(mid + iTime + 10.0)) * 0.1;
            
            // Draw branch
            float branch1 = drawLightningBranch(fragCoord, origin, mid, BRANCH_WIDTH, iTime);
            float branch2 = drawLightningBranch(fragCoord, mid, vec2(merge_x, merge_y), BRANCH_WIDTH, iTime);
            float branch = max(branch1, branch2);
            
            // Color with edge fade
            float fade = smoothstep(0.0, 0.2, distance(fragCoord, mid)/iResolution.y);
            vec3 bolt_color = mix(CORE_COLOR, EDGE_COLOR, fade);
            
            newColor.rgb = mix(newColor.rgb, bolt_color, branch);
        }
    }
    
    fragColor = newColor;
}
