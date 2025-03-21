const canvas = document.querySelector(".glslCanvas");
canvas.width = 300;
canvas.height = 300;
const sandbox = new GlslCanvas(canvas);
fetch("/shaders/cursor_example.glsl")
  .then((response) => {
    return response.text();
  })
  .then((fragment) => {
    sandbox.load(fragment);
  });

let previousCursor = { x: 0, y: 1, z: 20, w: 40 };
let currentCursor = { x: 0, y: 1, z: 20, w: 40 };

updateCursor();
updateCursor();
function setCursorUniforms() {
  sandbox.setUniform(
    "iCursorCurrent",
    currentCursor.x,
    currentCursor.y,
    currentCursor.z,
    currentCursor.w,
  );
  sandbox.setUniform(
    "iCursorPrevious",
    previousCursor.x,
    previousCursor.y,
    previousCursor.z,
    previousCursor.w,
  );
  sandbox.setUniform("iTimeCursorChange", performance.now() / 1000);
}

function updateCursor() {
  // Update the previous cursor to current
  previousCursor = { ...currentCursor };

  // Simulate new cursor position (for example, setting a new random position)
  const z = 20;
  const w = 40;
  const x = Math.random() * canvas.width;
  const y = Math.random() * canvas.height;

  currentCursor = { x: x, y: y, z: z, w: w };
  console.log(currentCursor);

  setCursorUniforms();
}

setInterval(updateCursor, 3000); // Change every 10 seconds
