// Raytracer tutorial that I followed https://raytracing.github.io/books/RayTracingInOneWeekend.html
// Pixels
int width = 399;
int height = 400;
char[] offOn = new char[] { ' ', '█' };

// World
float skycolor = 0.2;
// A sphere consists of a vec3 and a radius
float[] spheres = new float[] { 0, 0, -0.95, 1, 0.4, 0.4, -0.8, 1, -0.4, -0.4, -0.8, 1 };

void setup() {
  size(400, 400);
  pixelDensity(1); // Required so that it looks 
  noSmooth();      // the same on all screens
  surface.setLocation(700,100); // So that it doesn't get in my way when coding
  
  float[][] pixels = new float[width][height];
  
  /*
  pixels[10][10] = 1;
  for(int i = 0; i < width; i++) {
    pixels[i][2] = 0.5;
  }
  for(int i = 0; i < height; i++) {
    pixels[3][i] = 1;
  }*/
  
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
  textFont(createFont("Monospaced", 1), 1);
  textLeading(1);
  background(0);
  
  int[] bitPattern = new int[width*height];
  char[] s = new char[width*height];
  
  for(int i = 0; i < width; i++) {
    for(int j = 0; j < height; j++) {
      float val = pixels[i][j] * 255;
      int p = 0;
      // Generated using
      /* 
        res = { colors: [ ], ... }
        res.colors.map(c =>{
          return `if(val < ${Math.round(c.color)}) {\n  p = ${c.bitPattern};\n}`
        }).join(" else ")
      */
      if(val < 0) {
  p = 0;
} else if(val < 13) {
  p = 8;
} else if(val < 23) {
  p = 4;
} else if(val < 32) {
  p = 12;
} else if(val < 39) {
  p = 16;
} else if(val < 47) {
  p = 24;
} else if(val < 53) {
  p = 20;
} else if(val < 59) {
  p = 28;
} else if(val < 79) {
  p = 32;
} else if(val < 87) {
  p = 40;
} else if(val < 93) {
  p = 36;
} else if(val < 99) {
  p = 44;
} else if(val < 103) {
  p = 48;
} else if(val < 108) {
  p = 56;
} else if(val < 112) {
  p = 52;
} else if(val < 116) {
  p = 60;
} else if(val < 129) {
  p = 30;
} else if(val < 136) {
  p = 22;
} else if(val < 140) {
  p = 14;
} else if(val < 151) {
  p = 6;
} else if(val < 160) {
  p = 62;
} else if(val < 165) {
  p = 54;
} else if(val < 167) {
  p = 46;
} else if(val < 174) {
  p = 38;
} else if(val < 185) {
  p = 26;
} else if(val < 196) {
  p = 58;
} else if(val < 202) {
  p = 18;
} else if(val < 207) {
  p = 50;
} else if(val < 223) {
  p = 42;
} else if(val < 228) {
  p = 10;
} else if(val < 241) {
  p = 34;
} else if(val < 255) {
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
  for(int i = 0; i < bitPattern.length; i++) {
    int bitValue = (bitPattern[i] >> depth) & 1;
    textChars[i] = offOn[bitValue]; 
  }
  text(new String(textChars), 0, 0, 400, 400); 
}

/*
{
  "score": 86.34264156837436,
  "colors": [
    {
      "color": 0,
      "depth": 0,
      "bitPattern": 0
    },
    {
      "color": 13,
      "depth": 3,
      "bitPattern": 8
    },
    {
      "color": 23,
      "depth": 2,
      "bitPattern": 4
    },
    {
      "color": 32,
      "depth": 3,
      "bitPattern": 12
    },
    {
      "color": 39,
      "depth": 4,
      "bitPattern": 16
    },
    {
      "color": 47,
      "depth": 4,
      "bitPattern": 24
    },
    {
      "color": 53,
      "depth": 4,
      "bitPattern": 20
    },
    {
      "color": 59,
      "depth": 4,
      "bitPattern": 28
    },
    {
      "color": 79,
      "depth": 5,
      "bitPattern": 32
    },
    {
      "color": 87,
      "depth": 5,
      "bitPattern": 40
    },
    {
      "color": 93,
      "depth": 5,
      "bitPattern": 36
    },
    {
      "color": 99,
      "depth": 5,
      "bitPattern": 44
    },
    {
      "color": 103,
      "depth": 5,
      "bitPattern": 48
    },
    {
      "color": 108,
      "depth": 5,
      "bitPattern": 56
    },
    {
      "color": 112,
      "depth": 5,
      "bitPattern": 52
    },
    {
      "color": 116,
      "depth": 5,
      "bitPattern": 60
    },
    {
      "color": 129,
      "depth": 4,
      "bitPattern": 30
    },
    {
      "color": 136,
      "depth": 4,
      "bitPattern": 22
    },
    {
      "color": 140,
      "depth": 3,
      "bitPattern": 14
    },
    {
      "color": 151,
      "depth": 2,
      "bitPattern": 6
    },
    {
      "color": 160,
      "depth": 5,
      "bitPattern": 62
    },
    {
      "color": 165,
      "depth": 5,
      "bitPattern": 54
    },
    {
      "color": 167,
      "depth": 5,
      "bitPattern": 46
    },
    {
      "color": 174,
      "depth": 5,
      "bitPattern": 38
    },
    {
      "color": 185,
      "depth": 4,
      "bitPattern": 26
    },
    {
      "color": 196,
      "depth": 5,
      "bitPattern": 58
    },
    {
      "color": 202,
      "depth": 4,
      "bitPattern": 18
    },
    {
      "color": 207,
      "depth": 5,
      "bitPattern": 50
    },
    {
      "color": 223,
      "depth": 5,
      "bitPattern": 42
    },
    {
      "color": 228,
      "depth": 3,
      "bitPattern": 10
    },
    {
      "color": 241,
      "depth": 5,
      "bitPattern": 34
    },
    {
      "color": 255,
      "depth": 1,
      "bitPattern": 2
    }
  ],
  "iterationValues": [
    255,
    255,
    48,
    127,
    86,
    40,
    111,
    91,
    219,
    93
  ]
}
*/
