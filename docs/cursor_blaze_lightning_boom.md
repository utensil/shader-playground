# Cursor Blaze Lightning Boom Effects

## Lightning Effect (Right Movement)

When the cursor moves to the right, a dynamic lightning effect is rendered:

- **Core Structure**: Bright, jagged blue-white lines form the main lightning path
- **Intensity**: Center of each line is intensely vivid with slight edge diffusion
- **Branching**: Lines fork into smaller paths like natural lightning
- **Secondary Arcs**: Smaller, fainter arcs extend from main lines
- **Glow Effect**: Subtle charged-air glow surrounds the formation

## Explosion Effect (Left Movement)

When the cursor moves left, an explosive effect is triggered:

- **Initial Flash**: Sudden intense white/yellow-white flash at epicenter
- **Color Rings**: Concentric expanding rings with:
  - Deep red innermost ring
  - Orange-yellow middle band  
  - Light yellow-green outer ring
- **Debris**: Irregular shimmering fragments hurled outward
- **Smoke**: Dark billowing smoke rises from center
- **Chaos Effect**: Layered elements create visual chaos

## Technical Implementation

The effect uses:
- Signed distance functions for shape rendering
- Direction detection (left/right movement) 
- Color gradients and blending modes
- Particle-like effects for debris/smoke
- Time-based animation curves

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
