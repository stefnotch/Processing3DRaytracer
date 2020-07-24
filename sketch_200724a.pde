import java.util.Random; 

// Pixels
int width = 199;
int height = 200;

// World
float skycolor = 0.2;
float[] spheres = new float[] { 0, 0, 0, 1 };

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

void setup() {
  size(400, 400);
  pixelDensity(1); // Required so that it looks 
  noSmooth();      // the same on all screens
  background(0);
  fill(255, 255, 255);

  /*
  float[][] pixels = new float[width][height];
  
  pixels[10][10] = 1;
  for(int i = 0; i < width; i++) {
    pixels[i][2] = 0.5;
  }
  for(int i = 0; i < height; i++) {
    pixels[3][i] = 0.2;
  }
  
  pathtrace(pixels);
  
  blitToScreen(pixels);*/
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
