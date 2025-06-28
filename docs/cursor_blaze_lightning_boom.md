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
