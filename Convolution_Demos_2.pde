/*
Convolution_Demos.pde, a demo of convolution, with a special function that dynamically creates the kernel coefficients 
just prior to use.

Created by Douglas Mayhew, November 17, 2016.
Released into the public domain, except:
 * The function, 'makeGaussKernel1d' is made available as part of the book 
 * "Digital Image * Processing - An Algorithmic Introduction using Java" by Wilhelm Burger
 * and Mark J. Burge, Copyright (C) 2005-2008 Springer-Verlag Berlin, Heidelberg, New York.
 * Note that this code comes with absolutely no warranty of any kind.
 * See http://www.imagingbook.com for details and licensing conditions. 

See: https://github.com/Mr-Mayhem/DSP_Snippets_For_Processing

Convolution loop code originally from //http://www.dspguide.com/ch6/3.htm
translated into Processing (java) by Douglas Mayhew
*/

color COLOR_ORIGINAL_DATA = color(255);
color COLOR_IMPULSE_DATA = color(255, 255, 0);
color COLOR_OUTPUT_DATA = color(0, 255, 255);

int inputDataLength = 1080; //number of discrete values in the array
int impulseDataLength = 0; // use odd impulseDataLength to produce an even integer phase offset
int outputDataLength = 0; //number of discrete values in the array
int outerPtr = 1; // outer loop pointer
int impulsePtr = 0; // outer loop pointer

float ii = 0.02; // used for generating smooth noise for original data
float impulseSum = 0;
int PixelsPerPoint = 1;
int SCREEN_HEIGHT = 800;
int SCREEN_WIDTH = 0;

float[] x = new float[inputDataLength]; // array for input signal
float[] h = new float[0]; // array for impulse response
float[] y = new float[0]; // array for output signal

void setup() {
  h = makeGaussKernel1d(10);
  impulseDataLength = h.length; // use odd impulseDataLength to produce an even integer phase offset
  println("impulseDataLength = " + impulseDataLength);
  outputDataLength = inputDataLength + impulseDataLength; //number of discrete values in the array
  y = new float[outputDataLength]; // array for output signal
  SCREEN_WIDTH = outputDataLength*PixelsPerPoint;
  surface.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
  background(0);
  frameRate(100);
  resetData();
}
    
 void draw() {
  if (outerPtr >= inputDataLength) {
    resetData();
    drawLegend();
  }
  
  if (outerPtr == 1) {
    // draw the x and y aixs
    background(0);
    drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 8);
    drawLegend();
  }
  
  drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 8);
  
  // erase the points of the previous impulse by coloring them the background color
  strokeWeight(2);
  for (int innerPtr = 0; innerPtr < impulseDataLength; innerPtr++) { // increment the inner loop pointer
    // erase a previous impulse data point
    stroke(0); // background color
    point((outerPtr+innerPtr-2)*PixelsPerPoint, SCREEN_HEIGHT-100-(h[innerPtr]*10));
  }

  // plot original data point
  strokeWeight(1);
  stroke(COLOR_ORIGINAL_DATA);
  point((outerPtr-1)*PixelsPerPoint, SCREEN_HEIGHT-x[outerPtr]);
  
  for (int innerPtr = 0; innerPtr < impulseDataLength; innerPtr++) { // increment the inner loop pointer //<>//
    //delay(5);
    //plot impulse data point
    stroke(COLOR_IMPULSE_DATA); // impulse color
    point((outerPtr+innerPtr-1)*PixelsPerPoint, SCREEN_HEIGHT-100-(h[innerPtr]*10));  // draw new impulse point
    y[outerPtr+innerPtr-1] = y[outerPtr+innerPtr-1] + x[outerPtr-1] * h[innerPtr];  //convolve (the magic line)
  }

  //plot the output data
  stroke(COLOR_OUTPUT_DATA);
  point((outerPtr-(impulseDataLength/2)-1)*PixelsPerPoint, SCREEN_HEIGHT-y[outerPtr]/impulseSum);
  outerPtr++;  // increment the outer loop pointer
}

public void newInputData(){
  for (int c = 0; c < inputDataLength; c++) {
    ii = ii + 0.02;
    x[c] = map(noise(ii), 0, 1, 0, SCREEN_HEIGHT);
    //numbers[c] = floor(random(height));
   }
}

float [] makeGaussKernel1d(double sigma) {
  
 /**
 * This sample code is made available as part of the book "Digital Image
 * Processing - An Algorithmic Introduction using Java" by Wilhelm Burger
 * and Mark J. Burge, Copyright (C) 2005-2008 Springer-Verlag Berlin, 
 * Heidelberg, New York.
 * Note that this code comes with absolutely no warranty of any kind.
 * See http://www.imagingbook.com for details and licensing conditions.
 * 
 * Date: 2007/11/10
 
 code found also at:
 https://github.com/biometrics/imagingbook/blob/master/src/gauss/GaussKernel1d.java
 */

  // clear the sum used for normalizing the kernel
  impulseSum = 0;  // added this to normalize the plot
  
  // create the kernel
  int center = (int) (3.0 * sigma);
  float[] kernel = new float [2*center+1]; // odd size
  
  // fill the kernel
  double sigma2 = sigma * sigma; // sigma squared
  for (int i=0; i<kernel.length; i++) {
    double r = center - i;
    kernel[i] = (float) Math.exp(-0.5 * (r*r)/ sigma2);
    impulseSum+=kernel[i]; // added this to normalize the drawn points.
    println("kernel[" + i + "]:" + kernel[i]); // print the kernel as we save it into the array.
  }
  
  // sum of all elements, could be made to = 1 in an alternative normalization method.
  println("impulseSum:" + impulseSum); 
  return kernel;
}

public void zeroOutputData(){
  for (int c = 0; c < outputDataLength; c++) {
    y[c] = 0;
   }
}

public void resetData(){
  outerPtr = 1;
  impulsePtr = 0;
  newInputData(); // make some new ransom noise
  zeroOutputData();
  
  if(ii > 100){
    ii = 0.02;
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
  stroke(COLOR_IMPULSE_DATA);
  fill(COLOR_IMPULSE_DATA);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("Impulse Data (aka, the 'Kernel')", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_OUTPUT_DATA);
  fill(COLOR_OUTPUT_DATA);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("Smoothed output data, shifted back into original phase", rectX+20, rectY+10);
  
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