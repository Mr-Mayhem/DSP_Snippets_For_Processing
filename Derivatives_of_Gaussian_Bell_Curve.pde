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
color COLOR_ORIGINAL_DATA = color(255);
color COLOR_D1 = color(255, 0, 0);
color COLOR_D2 = color(0, 255, 0);
color COLOR_D3 = color(0, 0, 255);
color COLOR_D4 = color(0, 255, 255);
color COLOR_D5 = color(200, 200, 200);

int SCREEN_HEIGHT = 800;
int SCREEN_WIDTH = 800;
int numSCREEN_HEIGHTs = 800;
int HALF_SCREEN_HEIGHT = SCREEN_HEIGHT/2;
float[] SCREEN_HEIGHTs = new float[numSCREEN_HEIGHTs];
float[] d1SCREEN_HEIGHTs = new float[numSCREEN_HEIGHTs];
float[] d2SCREEN_HEIGHTs = new float[numSCREEN_HEIGHTs];
float[] d3SCREEN_HEIGHTs = new float[numSCREEN_HEIGHTs];
float[] d4SCREEN_HEIGHTs = new float[numSCREEN_HEIGHTs];
float[] d5SCREEN_HEIGHTs = new float[numSCREEN_HEIGHTs];
int oloopMax = 500;
int ii = 500;
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
  Gaussian1.calc(ii, numSCREEN_HEIGHTs);
  //for (int i = 250; i < 500; i++) {  // try other original data shapes
  //  SCREEN_HEIGHTs[i] = i-250;
  //  SCREEN_HEIGHTs[i+250] = 500+(-i);
  //}
  
   drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 8);
   drawLegend();
  // a little for loop that draws a line between each point on the graph
  
  for (int i = 1; i < (numSCREEN_HEIGHTs)-1; i++) {
    float x = i; 
    float y = map(SCREEN_HEIGHTs[i], 0, 1, HALF_SCREEN_HEIGHT-2, 2); // original data, a gaussian bell curve
    d1SCREEN_HEIGHTs[i] = SCREEN_HEIGHTs[i+1]-SCREEN_HEIGHTs[i];     // 1st derivative, the difference between adjacent x points of original
    d2SCREEN_HEIGHTs[i] = d1SCREEN_HEIGHTs[i+1]-d1SCREEN_HEIGHTs[i]; // 2nd derivative, the difference between adjacent x points of d1
    d3SCREEN_HEIGHTs[i] = d2SCREEN_HEIGHTs[i+1]-d2SCREEN_HEIGHTs[i]; // 3nd derivative, the difference between adjacent x points of d2
    d4SCREEN_HEIGHTs[i] = d3SCREEN_HEIGHTs[i+1]-d3SCREEN_HEIGHTs[i]; // 4th derivative, the difference between adjacent x points of d3
    d5SCREEN_HEIGHTs[i] = d4SCREEN_HEIGHTs[i+1]-d4SCREEN_HEIGHTs[i]; // 5th derivative, the difference between adjacent x points of d4
    
    stroke(COLOR_ORIGINAL_DATA);
    point(x, y);
    
    stroke(COLOR_D1);
    point(x, map(d1SCREEN_HEIGHTs[i], 0, 1, HALF_SCREEN_HEIGHT - 2, 2));
    
    stroke(COLOR_D2);
    point(x, map(d2SCREEN_HEIGHTs[i], 0, 1, HALF_SCREEN_HEIGHT - 2, 2));
    
    stroke(COLOR_D3);
    point(x, map(d3SCREEN_HEIGHTs[i], 0, 1, HALF_SCREEN_HEIGHT - 2, 2));
    
    stroke(COLOR_D4);
    point(x, map(d4SCREEN_HEIGHTs[i], 0, 1, HALF_SCREEN_HEIGHT - 2, 2));
    
    stroke(COLOR_D5);
    point(x, map(d5SCREEN_HEIGHTs[i], 0, 1, HALF_SCREEN_HEIGHT - 2, 2));
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
  
  void calc(float sigma, int len) {
    sd = map(sigma,0,len,0.001, 1);     //standard deviation based on mouseX
    for (int i = 0; i < len; i++) {
      float xcoord = map(i,0,len,-3,3);
      float sq2pi = sqrt(2*PI);                   //square root of 2 * PI
      float xmsq = -1*(xcoord-m)*(xcoord-m);      //-(x - mu)^2
      float sdsq = sd*sd;                         //variance (standard deviation squared)
      SCREEN_HEIGHTs[i] = (1 / (sd * sq2pi)) * (pow(e, (xmsq/sdsq)));  //P(x) function
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
  int SCREEN_WIDTHSpace = gWidth/divisor; // Number of Vertical Lines
  int SCREEN_HEIGHTSpace = gWidth/divisor; // Number of Horozontal Lines
  strokeWeight(1);
  stroke(25,25,25); // White Color
  // Draw vertical
  for(int i=0; i<gWidth; i+=SCREEN_WIDTHSpace){
    line(i,0,i,gHeight);
   }
   // Draw Horizontal
   for(int w=0; w<gHeight; w+=SCREEN_HEIGHTSpace){
     line(0,w,gWidth,w);
   }
}