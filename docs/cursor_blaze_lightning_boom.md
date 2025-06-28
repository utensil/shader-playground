# Cursor Blaze Lightning Boom Effects

## Lightning Effect (Right Movement)

When the cursor moves to the right, a dynamic lightning effect is rendered:

- **Core Structure**: Bright, jagged blue-white lines form the main lightning path
- **Intensity**: Center of each line is intensely vivid with slight edge diffusion
- **Branching**: Lines fork into smaller paths like natural lightning
- **Secondary Arcs**: Smaller, fainter arcs extend from main lines
- **Glow Effect**: Subtle charged-air glow surrounds the formation

## Explosion Effect (Left Movement)

When the cursor moves left, a highly realistic explosion effect is triggered:

### Core Visual Elements
- **Initial Flash**: 
  - Intense white-yellow core (1700-2000K color temperature)
  - Organic flickering at 30-40Hz for realistic combustion effect
  - Radial brightness falloff with turbulence

- **Shockwave**: 
  - Asymmetric propagation with 3-5 main lobes
  - Directionally-biased pressure waves
  - Temperature gradient from white-hot (2000K) to red (1000K)
  - Organic turbulence patterns based on angular displacement

- **Debris Field**:
  - 20+ high-velocity particles with randomized:
    - Trajectories (0-360° ejection angles)
    - Sizes (2-8% of blast radius)  
    - Velocities (0.5-1.0 radius units/frame)
    - Rotation speeds
  - Secondary fragmentation effects

- **Smoke Plume**:
  - Volumetric dark smoke with density variations
  - Convection-driven upward movement
  - Temperature-based color gradient (black to gray)
  - Organic dissipation patterns

### Color Spectrum
| Temperature | Color | RGB Value | Usage |
|-------------|-------|-----------|-------|
| 2500K+ | White-Yellow | (1.0, 0.95, 0.6) | Core flash |
| 1800K | Fiery Red | (1.0, 0.2, 0.0) | Primary shock front |
| 1200K | Bright Orange | (1.0, 0.5, 0.1) | Secondary wave |
| 900K | Vivid Yellow | (1.0, 0.8, 0.3) | Cooling phase |

## Technical Implementation

### Core Techniques
- **Signed Distance Functions**: Used for precise shape rendering of both lightning and explosion elements
- **Direction Detection**: Determines movement direction (left/right) to trigger appropriate effects
- **Particle Systems**: 
  - 20 debris particles with randomized trajectories and sizes
  - 10 smoke wisps with organic movement patterns
- **Layered Rendering**: Multiple passes create depth and realism
- **Procedural Animation**: Time-based curves control effect evolution

### Performance Optimizations
- **Branchless Design**: Minimizes conditional logic in shader
- **Pre-calculated Values**: Reuses computed values where possible  
- **Efficient Randomness**: Uses optimized hash functions for particle effects
- **Distance-based Culling**: Automatically fades effects based on distance

### Effect Parameters
```glsl
// Lightning Parameters
const float LIGHTNING_BRANCH_COUNT = 5.0;    // Number of secondary arcs
const float LIGHTNING_WIDTH = 0.01;         // Main channel thickness

// Explosion Thermodynamics  
const float EXPLOSION_DURATION = 0.1;       // Total effect lifespan (seconds)
const float CORE_TEMPERATURE = 2.0;         // Initial flash intensity
const float SHOCKWAVE_SPEED = 1.5;          // Expansion rate multiplier

// Particle Systems
const int DEBRIS_COUNT = 20;                // High-velocity fragments
const float DEBRIS_SIZE_MIN = 0.02;         // As fraction of blast radius  
const float DEBRIS_SIZE_MAX = 0.08;
const int SMOKE_COUNT = 10;                 // Convective plumes
const float SMOKE_DENSITY = 0.7;            // Opacity control

// Physical Simulation
const float SHOCKWAVE_TURBULENCE = 0.2;     // Air disturbance magnitude
const float THERMAL_DECAY_RATE = 0.8;       // Cooling speed
```

### Animation Timeline
1. **Initial Frame (0ms)**: 
   - Core flash reaches peak intensity
   - Shockwave begins propagating
2. **Early Phase (0-30ms)**:
   - Primary rings emerge
   - Debris particles accelerate outward  
3. **Mid Phase (30-70ms)**:
   - Secondary effects become visible
   - Smoke begins to form
4. **Late Phase (70-100ms)**:
   - Effects begin dissipating 
   - Smooth fade-out transition

## Uniform Variable Guidelines

**Important Rules for Uniform Usage:**
1. Only use these pre-defined uniforms:
   - `iResolution` (vec3) - Viewport resolution
   - `iTime` (float) - Shader playback time
   - `iCurrentCursor` (vec4) - Current cursor position/size (xy=position, zw=size)
   - `iPreviousCursor` (vec4) - Previous cursor position/size  
   - `iTimeCursorChange` (float) - Time when cursor last moved
   - `iChannel0` (sampler2D) - Background texture

2. Never declare new uniforms - only use the ones listed above

3. Uniform naming conventions:
   - Always use exact names (case-sensitive)
   - Never modify or redefine uniforms
   - Access existing uniforms directly (no UBOs/interface blocks)

4. Coordinate handling:
   - Normalize coordinates using `normalizeCoord()`
   - Use `iResolution` for proper scaling
   - Cursor positions are in pixels (use `iCurrentCursor.xy`/`iPreviousCursor.xy`)

**Example Proper Usage:**
```glsl
vec2 pos = normalizeCoord(fragCoord, 1.0);
float timeDelta = iTime - iTimeCursorChange; 
vec4 bg = texture(iChannel0, fragCoord/iResolution.xy);
```
