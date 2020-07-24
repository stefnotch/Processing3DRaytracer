// Raytracer tutorial that I followed https://raytracing.github.io/books/RayTracingInOneWeekend.html
// Pixels
int width = 199;
int height = 200;

// World
float skycolor = 0.2;
// A sphere consists of a vec3 and a radius
float[] spheres = new float[] { 0, 0, -0.95, 1, 0.4, 0.4, -0.8, 1, -0.4, -0.4, -0.8, 1 };

void setup() {
  size(400, 400);
  pixelDensity(1); // Required so that it looks 
  noSmooth();      // the same on all screens
  surface.setLocation(600,100); // So that it doesn't get in my way when coding
  background(0);
  fill(255, 255, 255);

  
  float[][] pixels = new float[width][height];
  
  pixels[10][10] = 1;
  for(int i = 0; i < width; i++) {
    pixels[i][2] = 0.5;
  }
  for(int i = 0; i < height; i++) {
    pixels[3][i] = 0.2;
  }
  
  pathtrace(pixels);
  
  blitToScreen(pixels);
}

void pathtrace(float[][] pixels) {
  int samplesPerPixel = 1;
  float samplesMultiplier = 1.0 / samplesPerPixel;
  float focalLength = 1;
  float[] origin = {0,0,0};
  
  float[] outputColor = {0,0,0};
  float[] rayDirection = {0,0,0};
    
  for(int i = 0; i < width; i++) {
    for(int j = 0; j < height; j++) {      
      // Texture coordinates
      float u = i / (float)(width - 1);
      float v = j / (float)(height - 1);
      // Screenspace coordinates (from -1 to 1)
      float screenX = u * 2 - 1;
      float screenY = v * 2 - 1;
      
      rayDirection[0] = screenX - origin[0];
      rayDirection[1] = screenY - origin[1];
      rayDirection[2] = -focalLength - origin[2];
      
      outputColor[0] = 0;
      outputColor[1] = 0;
      outputColor[2] = 0;
      for(int s = 0; s < samplesPerPixel; s++) {
        outputColor[0] = rayDirection[0];
        outputColor[1] = rayDirection[1];
        
        // TODO: Move this to a function
        for(int sphereIndex = 0; sphereIndex < spheres.length; sphereIndex += 4) {
          boolean hit = rayHitSphere(origin, rayDirection, spheres[sphereIndex], spheres[sphereIndex + 1], spheres[sphereIndex + 2], spheres[sphereIndex + 3]);
          if(hit) {
            outputColor[0] = 1;
            outputColor[1] = 1;
            outputColor[2] = 1;
          }
        }
       
        outputColor[0] *= samplesMultiplier;
        outputColor[1] *= samplesMultiplier;
        outputColor[2] *= samplesMultiplier;
      }
      
      pixels[i][j] = outputColor[0];//+ outputColor[1] + outputColor[2])/3.0;
    }
  }
}

// Manually writing variables here, because structs aren't a thing
float[] sphereCenterToRayStart = {0,0,0};
boolean rayHitSphere(float[] rayCenter, float[] rayDirection, float sphereCenterX, float sphereCenterY, float sphereCenterZ, float sphereRadius) {
  sphereCenterToRayStart[0] = rayCenter[0] - sphereCenterX;
  sphereCenterToRayStart[1] = rayCenter[1] - sphereCenterY;
  sphereCenterToRayStart[2] = rayCenter[2] - sphereCenterZ;
  // Quadratic formula: (-b +- sqrt(b*b - 4*a*c)) / 2*a
  // Damn, it also works for vectors?

  float a = rayDirection[0] * rayDirection[0] + 
    rayDirection[1] * rayDirection[1] + 
    rayDirection[2] * rayDirection[2];
    
  float b = 2 * (rayDirection[0] * sphereCenterToRayStart[0] +
    rayDirection[1] * sphereCenterToRayStart[1] +
    rayDirection[2] * sphereCenterToRayStart[2]
  );
  
  float c = 2 * (sphereCenterToRayStart[0] * sphereCenterToRayStart[0] +
    sphereCenterToRayStart[1] * sphereCenterToRayStart[1] +
    sphereCenterToRayStart[2] * sphereCenterToRayStart[2]
  ) - sphereRadius * sphereRadius;
  
  // Stuff inside the sqrt()
  float n = b*b - 4*a*c;
  if(n < 0) {
    return false; // No solutions, it's a complex number after all
  } else {
    // 1 or 2 solutions
    return true;
  }
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

void blitToScreen(float[][] pixels) {
  //textFont(createFont("Consolas", 2), 2);
  //textFont(createFont("Lucida Sans Typewriter", 4), 4);
  textFont(createFont("Monospaced", 2), 2);
  textLeading(2);
  
  char[] x = new char[] { ' ', '░', '▀', '▒', '█' };
  char[] s = new char[width*height];
  for(int i = 0; i < width; i++) {
    for(int j = 0; j < height; j++) {
      float val = pixels[i][j];
      s[i + j * width] = x[val < 0.2 ? 0 : (val < 0.4 ? 1 : (val < 0.6 ? 2 : (val < 0.8 ? 3 : 4)))]; 
    }
  }
  
  // Note: This cleary is only a single "object" that I'm drawing
  text(new String(s), 0, 0, 400, 400);
}
