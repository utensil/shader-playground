const canvas = document.querySelector(".glslCanvas");
canvas.width = document.body.clientWidth;
canvas.height = document.body.clientHeight;
const sandbox = new GlslCanvas(canvas);
let previousCursor = { x: 0, y: 0, z: 10, w: 20 };
let currentCursor = { x: 0, y: 0, z: 10, w: 20 };
let option = 0;

Promise.all([
  fetch("/shaders/cursor_example.glsl").then((response) => response.text()),
  fetch("/shaders/ghostty_wrapper.glsl").then((response) => response.text()),
]).then(([cursorFragment, ghosttyWrapper]) => {
  const modifiedShader = ghosttyWrapper.replace("//$REPLACE$", cursorFragment);
  sandbox.load(modifiedShader);
  gameLoop();
});

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
  let now = sandbox.uniforms["u_time"].value[0];
  sandbox.setUniform("iTimeCursorChange", now);
}
function updateCursor() {
  previousCursor = { ...currentCursor };
  const z = 10;
  const w = 20;
  const x = Math.random() * canvas.width;
  const y = Math.random() * canvas.height;
  currentCursor = { x: x, y: y, z: z, w: w };
  setCursorUniforms();
}
function moveCursor(x, y) {
  y = canvas.height - y;
  previousCursor = { ...currentCursor };
  currentCursor = {
    x: x,
    y: y,
    z: 10,
    w: 20,
  };
  setCursorUniforms();
}

canvas.addEventListener("click", function (event) {
  const rect = canvas.getBoundingClientRect();
  const x = event.clientX - rect.left;
  const y = event.clientY - rect.top;
  console.log(x, y);
  moveCursor(x, y);
  // changePresetPosition(1);
});
canvas.addEventListener("contextmenu", function (event) {
  event.preventDefault(); // Prevent the default context menu from appearing
  changePresetPosition(-1);
});

function gameLoop() {
  // changePresetPosition(1);
  // setInterval(updateCursor, 3000); // Change every 10 seconds
}

function changePresetPosition(value) {
  let top = canvas.height * 0.1;
  let bottom = canvas.height * 0.9;
  let left = canvas.width * 0.1;
  let right = canvas.width * 0.9;

  option = (option + value) % 8;
  console.log(option);
  switch (option) {
    case 0:
      moveCursor(left, top);
      moveCursor(right, bottom);
      break;
    case 1:
      moveCursor(left, bottom);
      moveCursor(right, top);
      break;
    case 2:
      moveCursor(right, bottom);
      moveCursor(left, top);
      break;
    case 3:
      moveCursor(right, top);
      moveCursor(left, bottom);
      break;
    case 4:
      moveCursor(top, right);
      moveCursor(bottom, right);
      break;
    case 5:
      moveCursor(bottom, right);
      moveCursor(top, right);
      break;
    case 6:
      moveCursor(bottom, left);
      moveCursor(bottom, right);
      break;
    case 7:
      moveCursor(top, right);
      moveCursor(top, left);
      break;
  }
}
