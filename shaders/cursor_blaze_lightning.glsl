/* IMPLEMENTATION NOTES PRESERVED AS COMMENTS
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

// Simple lightning branch function
float drawLightningBranch(vec2 p, vec2 a, vec2 b, float width) {
    vec2 dir = normalize(b - a);
    vec2 normal = vec2(-dir.y, dir.x);
    float d = dot(p - a, normal);
    return smoothstep(width, 0.0, abs(d));
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

// Lightning effect parameters
const float LIGHTNING_WIDTH = 0.02;
const vec3 CORE_COLOR = vec3(1.0, 0.8, 0.2);
const vec3 EDGE_COLOR = vec3(0.7, 0.2, 1.0);

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif
    
    // Check lightning activation conditions
    vec2 prev_pos = iCurrentCursor.xy;
    vec2 curr_pos = iCurrentCursor.zw;
    float delta_x = curr_pos.x - prev_pos.x;
    float delta_y = abs(curr_pos.y - prev_pos.y);
    bool should_lightning = delta_x > 0.0 && delta_y < 2.0;
    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);
    
    // Initialize origin at cursor position
    vec2 origin = curr_pos;
    
    // Calculate origin zone if lightning should activate
    if (should_lightning) {
        float screen_width = iResolution.x;
        float travel_dist = delta_x;
        float zone_width = min(travel_dist * 0.3, screen_width * 0.4);
        float zone_top = iResolution.y * 0.1;
        
        // Generate random origin points within zone
        float rand1 = fract(sin(dot(vec2(iTime, 0.5), vec2(12.9898,78.233))) * 43758.5453);
        float rand2 = fract(sin(dot(vec2(iTime, 1.0), vec2(12.9898,78.233))) * 43758.5453);
        origin = vec2(
            prev_pos.x + rand1 * zone_width,
            zone_top + rand2 * (iResolution.y * 0.05)
        );
    }

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    float invertedVertexFactor = 1.0 - vertexFactor;

    vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
    vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
    vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
    vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);
    
    vec4 newColor = vec4(fragColor);

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
    
    newColor = mix(newColor, TRAIL_COLOR_ACCENT, 1.0 - smoothstep(sdfCursor, -0.000, 0.003 * (1. - progress)));
    newColor = mix(newColor, CURRENT_CURSOR_COLOR, 1.0 - smoothstep(sdfCursor, -0.000, 0.003 * (1. - progress)));
    // Draw simple test lightning if active
    if (should_lightning) {
        vec2 target = curr_pos; // Start with simple straight line
        float branch = drawLightningBranch(fragCoord, origin, target, LIGHTNING_WIDTH);
        newColor.rgb = mix(newColor.rgb, CORE_COLOR, branch * 0.5); // Reduced intensity for testing
    }
    
    fragColor = mix(newColor, fragColor, step(sdfCursor, 0.));
}
