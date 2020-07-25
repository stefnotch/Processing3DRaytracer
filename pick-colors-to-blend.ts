type integer = number;
type float = number;

interface ColorObject {
  color: float;
  depth: integer;
  bitPattern: integer;
}

interface ColorsResult {
  score: float;
  colors: ColorObject[];
  iterationValues: float[];
}

const ctx = canvas.getContext("2d");

function createColor(): ColorObject {
  return {
    color: 0,
    depth: 0,
    bitPattern: 0,
  } as ColorObject;
}

function drawColor(color: ColorObject) {
  ctx.fillStyle = "black";
  ctx.fillRect(color.color, 0 + color.depth * 20, 1, 350 - color.depth * 20);
}

function drawColors(colorsArray: ColorObject[]) {
  for (let i = 0; i < colorsArray.length; i++) {
    drawColor(colorsArray[i]);
  }
}

function setBit(number: integer, bitIndex: integer, value: integer) {
  // integers
  let bitValue = (number >> bitIndex) & 1;
  if (value != bitValue) {
    return number ^ (1 << bitIndex);
  }
  return number;
}

function constrain(val: float, min: float, max: float) {
  return Math.min(Math.max(val, min), max);
}
function random(min: integer, max: integer) {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function doRun(maxScore: float): ColorsResult | undefined {
  let colors: ColorObject[] = [];
  let colorsLength: integer = 0;
  let depth: integer = 0;

  function addIteration(newColor: float, t: float) {
    newColor = constrain(newColor, 0, 255);
    t = constrain(t, 0, 255) / 255;
    depth++;

    let len = colorsLength;
    for (let i = 0; i < len; i++) {
      let lerpedColor = colors[i].color * (1 - t) + newColor * t;

      if (colorsLength >= colors.length) colors.push(createColor());
      colors[colorsLength].color = lerpedColor;
      colors[colorsLength].depth = depth;
      colors[colorsLength].bitPattern = setBit(colors[i].bitPattern, depth, 1);
      colorsLength++;
    }
  }

  colorsLength = 0;
  depth = 0;
  // Iteration background
  if (colorsLength >= colors.length) colors.push(createColor());
  colors[colorsLength].color = 0;
  colors[colorsLength].depth = 0;
  colors[colorsLength].bitPattern = 0;
  colorsLength++;

  let iterationValues: float[] = [
    255,
    255,
    random(0, 255),
    random(0, 255),
    random(0, 255),
    random(0, 255),
    random(0, 255),
    random(0, 255),
    random(0, 255),
    random(0, 255),
  ];
  // Iteration 1
  addIteration(iterationValues[0], iterationValues[1]);

  // Iteration 2
  addIteration(iterationValues[2], iterationValues[3]);

  // Iteration 3
  addIteration(iterationValues[4], iterationValues[5]);

  // Iteration 4
  addIteration(iterationValues[6], iterationValues[7]);

  // Iteration 5
  addIteration(iterationValues[8], iterationValues[9]);

  colors.sort((a, b) => a.color - b.color);
  let score: float = 0;
  for (let i = 0; i < colorsLength - 1; i++) {
    let diff = colors[i + 1].color - colors[i].color;
    if (diff < 1) diff = 0;
    score += Math.sqrt(diff);
  }

  if (score < maxScore) return undefined;
  return {
    score: score,
    // Copy the colors list. Alternatively, you can create a new list every time
    colors: colors.map((c) => {
      return { ...c };
    }),
    iterationValues: iterationValues,
  };
}

let maxScore: float = 0;
let maxResult = undefined;

function draw() {
  let hasNewMaxScore = false;
  for (let i = 0; i < 5000; i++) {
    let result = doRun(maxScore);
    if (result && result.score > maxScore) {
      maxScore = result.score;
      maxResult = result;
      console.log(maxResult);
      hasNewMaxScore = true;
    }
  }

  if (hasNewMaxScore) {
    ctx.fillStyle = "white";
    ctx.fillRect(0, 0, 400, 400);

    for (let i = 0; i < 255; i++) {
      ctx.fillStyle = `rgb(${i},${i},${i})`;
      ctx.fillRect(i, 350, 1, 50);
    }

    drawColors(maxResult.colors);
    ctx.fillText(maxScore, 256, 10);
  }

  requestAnimationFrame(draw); // That's a way to make a redraw-loop in Javascript...
}

draw();
