/*
Convolution+Demos.pde, a simple Processing sketch demo of a few low-order 
interpolation functions.

Created by Douglas Mayhew, November 7, 2016.

Released into the public domain.

See: https://github.com/Mr-Mayhem/DSP_Snippets_For_Processing

convolution code originally from //http://www.dspguide.com/ch6/3.htm
translated into Processing (java) by Douglas Mayhew
*/
color COLOR_ORIGINAL_DATA = color(0, 255, 0); // green
color COLOR_IMPULSE_DATA = color(255, 255, 0); //yellow
color COLOR_OUTPUT_DATA = color(255); // white

int inputDataLength = 256; //number of discrete values in the array
int impulseDataLength = 19; // use odd impulseDataLength to produce an even integer phase offset
int outputDataLength = inputDataLength + impulseDataLength; //number of discrete values in the array
int outerPtr = 1; // outer loop pointer
int impulsePtr = 0; // outer loop pointer

float ii = 0.05; // used for generating smooth noise for original data
float[] x = new float[inputDataLength]; // array for input signal
float[] h = new float[impulseDataLength]; // array for impulse response
float[] y = new float[outputDataLength]; // array for output signal
float impulseSum = 0;
int PixelsPerPoint = 4;
int SCREEN_HEIGHT = 800;
int SCREEN_WIDTH = outputDataLength*PixelsPerPoint;

void setup() {
  surface.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
  impulseSum = newImpulseData(1); // must be > 0 I don't see much difference over a wide range
  background(0);
  frameRate(30);
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
  }
    drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 8);
    drawLegend();
  
  strokeWeight(4);
  for (int innerPtr = 0; innerPtr < impulseDataLength; innerPtr++) { // increment the inner loop pointer
    // erase a previous impulse data point
    stroke(0); // background color
    point((outerPtr+innerPtr-2)*PixelsPerPoint, SCREEN_HEIGHT-100-(h[innerPtr]*10));
  }

  // plot original data point
  stroke(COLOR_ORIGINAL_DATA);
  point((outerPtr-1)*PixelsPerPoint, SCREEN_HEIGHT-x[outerPtr]);
  
  strokeWeight(2);
  for (int innerPtr = 0; innerPtr < impulseDataLength; innerPtr++) { // increment the inner loop pointer
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
    ii = ii + 0.05;
    x[c] = map(noise(ii), 0, 1, 0, SCREEN_HEIGHT);
    //numbers[c] = floor(random(height));
   }
}

 float newImpulseData(float scalingFactor) {
   float sum = 0;
  
  // set all data values to zero
  for (int c = 0; c < impulseDataLength; c++) {
     h[c] = 0;
  }
  // Laplacian of Gaussian mask, the "mexican hat" shape
  // this impulse response smooths the data for edge detection
  h[0] = 0;
  h[1] = -0.1 * scalingFactor;
  h[2] = -0.1 * scalingFactor;
  h[3] = -0.3 * scalingFactor;
  h[4] = -0.3 * scalingFactor;
  h[5] = -0.3 * scalingFactor;
  h[6] = 0.4 * scalingFactor;
  h[7] = 1.2 * scalingFactor;
  h[8] = 2.1 * scalingFactor;
  h[9] = 2.4 * scalingFactor;
  h[10] = 2.1 * scalingFactor;
  h[11] = 1.2 * scalingFactor;
  h[12] = 0.4 * scalingFactor;
  h[13] = -0.3 * scalingFactor;
  h[14] = -0.3 * scalingFactor;
  h[15] = -0.3 * scalingFactor;
  h[16] = -0.1 * scalingFactor;
  h[17] = -0.1 * scalingFactor;
  h[18] = 0;
  
  for (int c = 0; c < 19; c++) {
    sum+=h[c]; 
  }
 // used later to normalize the output data back down to it's original range
  return sum;
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
    ii = 0.05;
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