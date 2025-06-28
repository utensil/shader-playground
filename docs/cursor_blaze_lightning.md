# Cursor Blaze Lightning Effect Implementation

## Requirements

### 1. Activation Condition
- Triggered exclusively when:
  - Cursor moves left-to-right on same line
  - Movement indicates typing/copy-paste activity
  - Horizontal delta > vertical delta

### 2. Origin Zone
- Narrow top-screen region parameters:
  - Base width = cursor horizontal distance traveled
  - Constrained by ratio (0.2-0.4 recommended)
  - Final width = min(base_width * ratio, max_screen_percentage)

### 3. Lightning Path Generation
- Branch characteristics:
  - 3-5 primary branches
  - Random origin points within origin zone
  - Perlin noise-driven trembling (frequency: 8-12Hz)
  - Fractal Brownian Motion (FBM) for organic zigzag
  - Merge point randomization:
    - Vertical position range: 25-75% screen height
    - Horizontal position bias: 70% toward cursor

### 4. Color Profile
- Core components:
  - Main channel: HSB(45°, 90%, 100%)
  - Edge effect: RGB(0.7, 0.2, 1.0) with distance falloff
  - Color mixing:
    ```glsl
    float t = smoothstep(0.0, 0.2, distance_from_core);
    vec3 final_color = mix(core_color, edge_color, t);
    ```

### 5. Implementation Strategy
- Particle system requirements:
  - GPU-driven via compute shader
  - Mode 4 isolation (existing modes 0-3 untouched)
  - Dynamic buffers:
    - Branch paths (SSBO)
    - Lightning state (UBO)

## Implementation Guidelines

### 1. Same-line Detection
Track cursor delta in vertex shader:
```glsl
vec2 prev_pos = texelFetch(prevCursorBuffer, 0, 0).xy;
float delta_x = current_pos.x - prev_pos.x;
float delta_y = abs(current_pos.y - prev_pos.y);
bool same_line = delta_y < (1.0/iResolution.y) * 2.0;
```

### 2. FBM Optimization
3 octaves with falloff:
```glsl
float fbm(vec2 p) {
  float amp = 0.5;
  for(int i=0; i<3; i++) {
    noise += amp * cnoise(p);
    amp *= 0.5;
    p *= 2.0;
  }
  return noise;
}
```

### 3. Particle Synchronization
Time-modulated lifetime:
```glsl
float refresh_rate = 60.0;
float frame_duration = 1.0/refresh_rate;
float t = mod(iTime, frame_duration);
```

### 4. Color Conversion
HSB->RGB function:
```glsl
vec3 hsb2rgb(float h, float s, float b) {
  vec3 c = vec3(h, s, b);
  vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0);
  return c.z * mix(vec3(1.0), rgb, c.y);
}
```

### 5. Branch Buffering
Single dispatch strategy:
```glsl
layout(std430, binding=0) buffer Branches {
  atomic_uint branch_count;
  vec2 positions[];
};
```

### 6. Temporal AA
Velocity-based blending:
```glsl
vec4 previous = texture(prevFrame, uv);
vec4 current = texture(currentFrame, uv);
vec4 blended = mix(previous, current, 0.2);
```

### 7. Coordinate Standardization
Aspect correction:
```glsl
vec2 uv = gl_FragCoord.xy/iResolution.xy;
uv.x *= iResolution.x/iResolution.y;
```

## Next Steps
1. Implement cursor movement analysis in vertex stage
2. Prototype branch merging algorithm
3. Benchmark particle count limits
4. Establish color blending reference implementation