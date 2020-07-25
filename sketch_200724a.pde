// Raytracer tutorial that I followed https://raytracing.github.io/books/RayTracingInOneWeekend.html
// Pixels
int width = 399;
int height = 400;
char[] offOn = new char[] { ' ', '█' };

// World
float skycolor = 0.2;
// A sphere consists of a vec3 and a radius
float[] spheres = new float[] { 0, 0, -0.95, 1, 0.4, 0.4, -0.8, 1, -0.4, -0.4, -0.8, 1 };


// Constants
int ALPHA_MASK = 0xFF000000;
int RED_MASK =   0x00FF0000;
int GREEN_MASK = 0x0000FF00;
int BLUE_MASK =  0x000000FF;

void setup() {
  size(400, 400);
  pixelDensity(1); // Required so that it looks 
  noSmooth();      // the same on all screens
  surface.setLocation(700, 100); // So that it doesn't get in my way when coding

  int[][] pixels = new int[width][height]; // Packed colors

  pathtrace(pixels);

  colorBlitToScreen(pixels);
  //blitToScreen(pixels);
}

void pathtrace(int[][] pixels) {
  int samplesPerPixel = 1;
  float samplesMultiplier = 1.0 / (float)samplesPerPixel;
  float focalLength = 1;
  float[] origin = {0, 0, 0};

  float[] hitColor = {0, 0, 0};
  float[] pixelColor = {0, 0, 0};
  float[] rayDirection = {0, 0, 0};

  float[] hitVector = {0, 0, 0};
  float[] hitNormalVector = {0, 0, 0};
  float[] hitDistance = {0};

  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {      
      pixelColor[0] = 0;
      pixelColor[1] = 0;
      pixelColor[2] = 0;
      for (int s = 0; s < samplesPerPixel; s++) {
        // Texture coordinates
        float u = (i + nextRandom()) / (float)(width - 1);
        float v = (j + nextRandom()) / (float)(height - 1);
        // Screenspace coordinates (from -1 to 1)
        float screenX = u * 2 - 1;
        float screenY = v * 2 - 1;
  
        rayDirection[0] = screenX - origin[0];
        rayDirection[1] = screenY - origin[1];
        rayDirection[2] = -focalLength - origin[2];

        hitColor[0] = 0;
        hitColor[1] = 0;
        hitColor[2] = 0;
        // TODO: Move this to a function
        for (int sphereIndex = 0; sphereIndex < spheres.length; sphereIndex += 4) {
          boolean hit = rayHitSphere(
            origin, rayDirection, 
            spheres[sphereIndex], spheres[sphereIndex + 1], spheres[sphereIndex + 2], spheres[sphereIndex + 3], 
            hitVector, hitNormalVector, hitDistance
            );
          if (hit) {
            hitColor[0] = hitNormalVector[0];
            hitColor[1] = hitNormalVector[1];
            hitColor[2] = hitNormalVector[2];
            break;
          }
        }

        pixelColor[0] += hitColor[0] * samplesMultiplier;
        pixelColor[1] += hitColor[1] * samplesMultiplier;
        pixelColor[2] += hitColor[2] * samplesMultiplier;
      }
      
      int alpha = 255;
      int red = (int)(pixelColor[0] * 255);
      int green = (int)(pixelColor[1] * 255);
      int blue = (int)(pixelColor[2] * 255);
      if(red < 0) red = 0; if(red > 255) red = 255;
      if(green < 0) green = 0; if(green > 255) green = 255;
      if(blue < 0) blue = 0; if(blue > 255) blue = 255;
      
      red *= 2;
      green *= 2;
      blue *= 2;
      
      pixels[i][j] = ((alpha << 24) & ALPHA_MASK) | ((red << 16) & RED_MASK) | ((green << 8) & GREEN_MASK) | (blue & BLUE_MASK);
    }
  }
}

// Manually writing variables here, because structs aren't a thing
float[] sphereCenterToRayStart = {0, 0, 0};
boolean rayHitSphere(
  float[] rayCenter, float[] rayDirection, 
  float sphereCenterX, float sphereCenterY, float sphereCenterZ, float sphereRadius, 
  float[] hitVector, float[] hitNormalVector, float[] hitDistance
  ) {
  sphereCenterToRayStart[0] = rayCenter[0] - sphereCenterX;
  sphereCenterToRayStart[1] = rayCenter[1] - sphereCenterY;
  sphereCenterToRayStart[2] = rayCenter[2] - sphereCenterZ;
  // Quadratic formula: (-b +- sqrt(b*b - 4*a*c)) / 2*a
  // Damn, it also works for vectors?
  // Modify the formula (because our b = 2 * something)
  // (-2*B +- sqrt(4*(B*B - a*c))) / 2*a
  // (-2*B +- 2*sqrt(B*B - a*c)) / 2*a
  // (-B +- sqrt(B*B - a*c)) / a

  float a = rayDirection[0] * rayDirection[0] + 
    rayDirection[1] * rayDirection[1] + 
    rayDirection[2] * rayDirection[2];

  float B = (rayDirection[0] * sphereCenterToRayStart[0] +
    rayDirection[1] * sphereCenterToRayStart[1] +
    rayDirection[2] * sphereCenterToRayStart[2]
    );

  float c = 2 * (sphereCenterToRayStart[0] * sphereCenterToRayStart[0] +
    sphereCenterToRayStart[1] * sphereCenterToRayStart[1] +
    sphereCenterToRayStart[2] * sphereCenterToRayStart[2]
    ) - sphereRadius * sphereRadius;

  // Stuff inside the sqrt()
  float n = B*B - a*c;
  if (n < 0) return false; // No solutions, it's a complex number after all

  // The closer solution of the two
  float smallerSolution = (-B - sqrt(n)) / a;
  if (smallerSolution < 0) return false; // Object is behind us/we are inside the object

  hitVector[0] = rayCenter[0] + rayDirection[0] * smallerSolution;
  hitVector[1] = rayCenter[1] + rayDirection[1] * smallerSolution;
  hitVector[2] = rayCenter[2] + rayDirection[2] * smallerSolution;

  hitNormalVector[0] = (hitVector[0] - sphereCenterX) / sphereRadius;
  hitNormalVector[1] = (hitVector[1] - sphereCenterY) / sphereRadius;
  hitNormalVector[2] = (hitVector[2] - sphereCenterZ) / sphereRadius;
  
  hitDistance[0] = smallerSolution;
  return true;
}

// I'm not using anything special... :3
// http://prng.di.unimi.it/xoshiro128plus.c
int[] randomState = new int[] { 324, 252, 1234, 35 };
float nextRandom() {
  // >> 9 shifts the bits to the float's mantissa
  // & 0x007FFFFF makes sure that they're all 0
  // | 0x3F800000 sets the upper bits so that we get numbers in the range [1;2[
  int result = randomState[0] + randomState[3];

  int t = randomState[1] << 9;
  randomState[2] ^= randomState[0];
  randomState[3] ^= randomState[1];
  randomState[1] ^= randomState[2];
  randomState[0] ^= randomState[3];
  randomState[2] ^= t;
  randomState[3] = (randomState[3] << 11) | (randomState[3] >> (32 - 11));

  return Float.intBitsToFloat((result >> 9) & 0x007FFFFF | 0x3F800000) - 1;
}

// For debugging
void colorBlitToScreen(int[][] pixels) {
  background(0);
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      set(i, j, pixels[i][j]);
    }
  }
}

void blitToScreen(int[][] pixels) {
  textFont(createFont("Monospaced", 1), 1);
  textLeading(1);
  background(0);

  int[] bitPattern = new int[width*height];
  char[] s = new char[width*height];

  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      int red = (pixels[i][j] >> 16) & BLUE_MASK;
      int green = (pixels[i][j] >> 8) & BLUE_MASK;
      int blue = (pixels[i][j]) & BLUE_MASK;
      int val = (red + green + blue) / 3;
      int p = 0;
      // Generated using
      /* 
       res = { colors: [ ], ... }
       res.colors.map(c =>{
       return `if(val <= ${Math.round(c.color)}) {\n  p = ${c.bitPattern};\n}`
       }).join(" else ")
       */
      if (val <= 0) {
        p = 0;
      } else if (val < 13) {
        p = 8;
      } else if (val < 23) {
        p = 4;
      } else if (val < 32) {
        p = 12;
      } else if (val < 39) {
        p = 16;
      } else if (val < 47) {
        p = 24;
      } else if (val < 53) {
        p = 20;
      } else if (val < 59) {
        p = 28;
      } else if (val < 79) {
        p = 32;
      } else if (val < 87) {
        p = 40;
      } else if (val < 93) {
        p = 36;
      } else if (val < 99) {
        p = 44;
      } else if (val < 103) {
        p = 48;
      } else if (val < 108) {
        p = 56;
      } else if (val < 112) {
        p = 52;
      } else if (val < 116) {
        p = 60;
      } else if (val < 129) {
        p = 30;
      } else if (val < 136) {
        p = 22;
      } else if (val < 140) {
        p = 14;
      } else if (val < 151) {
        p = 6;
      } else if (val < 160) {
        p = 62;
      } else if (val < 165) {
        p = 54;
      } else if (val < 167) {
        p = 46;
      } else if (val < 174) {
        p = 38;
      } else if (val < 185) {
        p = 26;
      } else if (val < 196) {
        p = 58;
      } else if (val < 202) {
        p = 18;
      } else if (val < 207) {
        p = 50;
      } else if (val < 223) {
        p = 42;
      } else if (val < 228) {
        p = 10;
      } else if (val < 241) {
        p = 34;
      } else if (val <= 255) {
        p = 2;
      }

      bitPattern[i + j * width] = p;
    }
  }

  int depth = 1;

  // Note: This cleary are only 5 text objects that I'm drawing
  // 1
  fill(255, 255, 255, 255); //NU TOUCH!
  drawText(s, bitPattern, depth);
  depth++;

  // 2
  fill(48, 48, 48, 127);
  drawText(s, bitPattern, depth);
  depth++;

  // 3
  fill(86, 86, 86, 40);
  drawText(s, bitPattern, depth);
  depth++;

  // 4
  fill(111, 111, 111, 91);
  drawText(s, bitPattern, depth);
  depth++;

  // 5
  fill(219, 219, 219, 93);
  drawText(s, bitPattern, depth);
  depth++;
}

void drawText(char[] textChars, int[] bitPattern, int depth) {
  for (int i = 0; i < bitPattern.length; i++) {
    int bitValue = (bitPattern[i] >> depth) & 1;
    textChars[i] = offOn[bitValue];
  }
  text(new String(textChars), 0, 0, 400, 400);
}
