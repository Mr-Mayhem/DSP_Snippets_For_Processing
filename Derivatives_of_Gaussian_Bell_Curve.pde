/*
  Derivatives_of_Gaussian_Bell_Curve.pde 
  A Processing sketch for plotting a bell curve and 
  its first 5 derivatives in the same plot.
  
  Created by Douglas Mayhew, November 9, 2016.
  Released into the public domain.
  See: https://github.com/Mr-Mayhem/DSP_Snippets_For_Processing
  
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

color COLOR_ORIGINAL_DATA = color(255);
color COLOR_D1 = color(255, 0, 0);
color COLOR_D2 = color(0, 255, 0);
color COLOR_D3 = color(0, 0, 255);
color COLOR_D4 = color(0, 255, 255);
color COLOR_D5 = color(255, 0, 255);

int SCREEN_HEIGHT = 1000;
int SCREEN_WIDTH = 1000;
int NUM_OF_DATA_POINTS = 1000;
int HALF_SCREEN_HEIGHT = SCREEN_HEIGHT/2;

float[] floatArray0 = new float[NUM_OF_DATA_POINTS];
float[] floatArray1 = new float[NUM_OF_DATA_POINTS];
float[] floatArray2 = new float[NUM_OF_DATA_POINTS];
float[] floatArray3 = new float[NUM_OF_DATA_POINTS];
float[] floatArray4 = new float[NUM_OF_DATA_POINTS];
float[] floatArray5 = new float[NUM_OF_DATA_POINTS];
int oloopMax = 1000;
int ii = 1000;
boolean flip = true;

Gaussian Gaussian1;
void setup() {
  surface.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
  Gaussian1 = new Gaussian();
  strokeWeight(1);
  noFill();
  background(0);
  //smooth();
}

void draw() {
  background(0); // uncomment this to see the whole series; comment to see current set only
  Gaussian1.calc(ii, NUM_OF_DATA_POINTS);
  //for (int i = 250; i < 500; i++) {  // try other original data shapes
  //  floatArray[i] = i-250;
  //  floatArray[i+250] = 500+(-i);
  //}
  
   drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 8);
   drawLegend();
  // a for loop that plots the data...
  
  for (int i = 1; i < (NUM_OF_DATA_POINTS)-1; i++) {
    float x = i; 
    float y = map(floatArray0[i], 0, 1, HALF_SCREEN_HEIGHT-2, 2); // original data, a gaussian bell curve
    
    floatArray1[i] = floatArray0[i+1]-floatArray0[i]; // 1st derivative, the y difference between adjacent x points of original
    floatArray2[i] = floatArray1[i+1]-floatArray1[i]; // 2nd derivative, the y difference between adjacent x points of d1
    floatArray3[i] = floatArray2[i+1]-floatArray2[i]; // 3nd derivative, the y difference between adjacent x points of d2
    floatArray4[i] = floatArray3[i+1]-floatArray3[i]; // 4th derivative, the y difference between adjacent x points of d3
    floatArray5[i] = floatArray4[i+1]-floatArray4[i]; // 5th derivative, the y difference between adjacent x points of d4
    
    // scale x for the screen width
    int scaledX = round(map(x, 0, NUM_OF_DATA_POINTS-1, 0, SCREEN_WIDTH-1)); 
      
    stroke(COLOR_ORIGINAL_DATA);
    point(scaledX, y); // plot original data, a gaussian bell curve
    
    stroke(COLOR_D1);
    point(scaledX, map(floatArray1[i], 0, 1, HALF_SCREEN_HEIGHT - 1, 1)); // plot 1st derivative
    
    stroke(COLOR_D2);
    point(scaledX, map(floatArray2[i], 0, 1, HALF_SCREEN_HEIGHT - 1, 1)); // plot 2nd derivative (used for edge detection)
    
    stroke(COLOR_D3);
    point(scaledX, map(floatArray3[i], 0, 1, HALF_SCREEN_HEIGHT - 1, 1)); // plot 3nd derivative
    
    stroke(COLOR_D4);
    point(scaledX, map(floatArray4[i], 0, 1, HALF_SCREEN_HEIGHT - 1, 1)); // plot 4th derivative
    
    stroke(COLOR_D5);
    point(scaledX, map(floatArray5[i], 0, 1, HALF_SCREEN_HEIGHT - 1, 1)); // plot 5th derivative
  }
  
  if (!flip){
    if (ii < 0) {
      flip = true;
      delay(2000);
      background(0);
    }
    ii--;
  } else 
  {
    if (ii > oloopMax) {
      flip = false;
      delay(2000);
      background(0);
    }
    ii++;
  }
}

class Gaussian {
  float e = 2.71828183;  //"e", see http://mathforum.org/dr.math/faq/faq.e.html for more info
  float m = 0;           //default mean of 0 
  float sd = 1;          //standard deviation based on mouseX

  Gaussian () {  
  }
  
  void calc(float sigma, int numOfXPoints) {
    sd = map(sigma,0,numOfXPoints, 0.001, 1);     //standard deviation based on sigma mapped to numOfXPoints
    for (int i = 0; i < numOfXPoints; i++) {
      float xcoord = map(i,0,numOfXPoints,-3,3);
      float sq2pi = sqrt(2*PI);                   //square root of 2 * PI
      float xmsq = -1*(xcoord-m)*(xcoord-m);      //-(x - mu)^2
      float sdsq = sd*sd;                         //variance (standard deviation squared)
      floatArray0[i] = (1 / (sd * sq2pi)) * (pow(e, (xmsq/sdsq)));  //P(x) function
    }
  } 
}

void drawLegend() {
  int rectX, rectY, rectWidth, rectHeight;
  
  rectX = 20;
  rectY = 20;
  rectWidth = 10;
  rectHeight = 10;
 
  // draw a legend showing what each color represents
  strokeWeight(1);
  
  stroke(COLOR_ORIGINAL_DATA);
  fill(COLOR_ORIGINAL_DATA);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("Original Data", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_D1);
  fill(COLOR_D1);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("1st derivative", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_D2);
  fill(COLOR_D2);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("2nd derivative", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_D3);
  fill(COLOR_D3);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("3rd derivative", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_D4);
  fill(COLOR_D4);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("4th derivative", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_D5);
  fill(COLOR_D5);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("5th derivative", rectX+20, rectY+10);
}

void drawGrid(int gWidth, int gHeight, int divisor)
{
  int widthSpace = gWidth/divisor; // Number of Vertical Lines
  int heightSpace = gHeight/divisor; // Number of Horozontal Lines
  strokeWeight(1);
  stroke(25,25,25); // White Color
  // Draw vertical
  for(int i=0; i<gWidth; i+=widthSpace){
    line(i,0,i,gHeight);
   }
   // Draw Horizontal
   for(int w=0; w<gHeight; w+=heightSpace){
     line(0,w,gWidth,w);
   }
}