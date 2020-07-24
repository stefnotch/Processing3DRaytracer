int width = 199;
int height = 200;
void setup() {
  size(400, 400);
  pixelDensity(1);
  noSmooth();
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
  blitToScreen(pixels);
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
