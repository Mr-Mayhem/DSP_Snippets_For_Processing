/*
  Derivatives_of_Gaussian_Bell_Curve.pde 
  A Processing sketch for plotting a bell curve and 
  its first 5 derivatives in the same plot.
  
  Created by Douglas Mayhew, November 9, 2016.
  Released into the public domain.

 Core bell curve code originally from
 Daniel Shiffman
 The Nature of Code
 http://www.shiffman.net/

  Notes: Comment "background(0);" in the loop to see the whole series combined together, 
  creating a hyperbola.
  
  Comment the 
  point(x, y);
  lines to hide derivatives so the uncommented ones are less cluttered.
  
  Note that the second derivative of a Gaussian bell curve is often used as an 
  inpulse or "kernel" ingredent to perform image processing edge detection via 
  convolution, in one loop, instead of two seperate loops as with other methods.
  
  It is this angle I am investigating for use in my convolution.pde Processing sketch.
  */
  
int HEIGHT = 800;
int WIDTH = 800;
int numHeights = 800;
int HALF_HEIGHT = HEIGHT/2;
float[] heights = new float[numHeights];
float[] d1heights = new float[numHeights];
float[] d2heights = new float[numHeights];
float[] d3heights = new float[numHeights];
float[] d4heights = new float[numHeights];
float[] d5heights = new float[numHeights];
int oloopMax = 500;
int ii = 0;
boolean flip = true;

Gaussian Gaussian1;
void setup() {
  surface.setSize(WIDTH, HEIGHT);
  Gaussian1 = new Gaussian();
  strokeWeight(1);
  noFill();
  background(0);
  //smooth();
}

void draw() {
  background(0); // uncomment this to see the whole series; comment to see current set only
  Gaussian1.calc(ii, numHeights);
  //for (int i = 250; i < 500; i++) {  // try other original data shapes
  //  heights[i] = i-250;
  //  heights[i+250] = 500+(-i);
  //}
  

  // a little for loop that draws a line between each point on the graph
  
  for (int i = 1; i < (numHeights)-1; i++) {
    float x = i; 
    float y = map(heights[i], 0, 1, HALF_HEIGHT-2, 2); // original data, a gaussian bell curve
    d1heights[i] = heights[i+1]-heights[i];     // 1st derivative, the difference between adjacent x points of original
    d2heights[i] = d1heights[i+1]-d1heights[i]; // 2nd derivative, the difference between adjacent x points of d1
    d3heights[i] = d2heights[i+1]-d2heights[i]; // 3nd derivative, the difference between adjacent x points of d2
    d4heights[i] = d3heights[i+1]-d3heights[i]; // 4th derivative, the difference between adjacent x points of d3
    d5heights[i] = d4heights[i+1]-d4heights[i]; // 5th derivative, the difference between adjacent x points of d4
    stroke(255);
    point(x, y);
    
    stroke(255, 0, 255);
    point(x, map(d1heights[i], 0, 1, HALF_HEIGHT - 2, 2));
    
    stroke(255, 255, 0);
    point(x, map(d2heights[i], 0, 1, HALF_HEIGHT - 2, 2));
    
    stroke(0, 255, 0);
    point(x, map(d3heights[i], 0, 1, HALF_HEIGHT - 2, 2));
    
    stroke(0, 0, 255);
    point(x, map(d4heights[i], 0, 1, HALF_HEIGHT - 2, 2));
    
    stroke(255, 0, 255);
    point(x, map(d5heights[i], 0, 1, HALF_HEIGHT - 2, 2));
  }
  
  if (flip){
    if (ii > oloopMax) {
      flip = false;
      delay(3000);
      background(0);
    }
    ii++;
  } else 
  {
    if (ii < 0) {
      flip = true;
      delay(1000);
      background(0);
    }
    ii--;
  }
}

class Gaussian {
  float e = 2.71828183;  //"e", see http://mathforum.org/dr.math/faq/faq.e.html for more info
  float m = 0;           //default mean of 0 
  float sd = 1;          //standard deviation based on mouseX

  Gaussian () {  
  }
  
  void calc(float sigma, int len) {
    sd = map(sigma,0,len,0.001, 3);     //standard deviation based on mouseX
    for (int i = 0; i < len; i++) {
      float xcoord = map(i,0,len,-3,3);
      float sq2pi = sqrt(2*PI);                   //square root of 2 * PI
      float xmsq = -1*(xcoord-m)*(xcoord-m);      //-(x - mu)^2
      float sdsq = sd*sd;                         //variance (standard deviation squared)
      heights[i] = (1 / (sd * sq2pi)) * (pow(e, (xmsq/sdsq)));  //P(x) function
    }
  } 
}