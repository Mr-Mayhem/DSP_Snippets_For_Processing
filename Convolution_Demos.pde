/* //<>//
Convolution_Demos.pde, a simple Processing sketch demo of convolution.
See also Convolution_Demos_2.pde, which is a later version with more features,
including dymanic creation of the convolution kernel.

Created by Douglas Mayhew, November 7, 2016.

Released into the public domain.

See: https://github.com/Mr-Mayhem/DSP_Snippets_For_Processing

convolution loop code originally from //http://www.dspguide.com/ch6/3.htm
translated into Processing (java) by Douglas Mayhew
*/
color COLOR_ORIGINAL_DATA = color(255, 255, 255); 
color COLOR_IMPULSE_DATA = color(255, 255, 0);
color COLOR_OUTPUT_DATA = color(0, 255, 0); 

int inputDataLength = 256; //number of discrete values in the array
int impulseDataLength = 9; // use odd impulseDataLength to produce an even integer phase offset
int outputDataLength = inputDataLength + impulseDataLength; //number of discrete values in the array
int outerPtr = 1; // outer loop pointer
int impulsePtr = 0; // outer loop pointer

float noiseInput = 0.07;     // used for generating smooth noise for original data
float noiseIncrement = noiseInput; // the increment of change of the noise input

float[] x = new float[inputDataLength]; // array for input signal
float[] h = new float[impulseDataLength]; // array for impulse response
float[] y = new float[outputDataLength]; // array for output signal

int PixelsPerPoint = 4;
int SCREEN_HEIGHT = 800;
int SCREEN_WIDTH = outputDataLength*PixelsPerPoint;

void setup() {
  surface.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
  newKernelData();
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
    drawLegend();
  }
    
    drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 8);
   
  // erase the points of the previous impulse by coloring them the background color
  strokeWeight(2);
  for (int innerPtr = 0; innerPtr < impulseDataLength; innerPtr++) { // increment the inner loop pointer
    // erase a previous impulse data point
    stroke(0); // background color
    point((outerPtr+innerPtr-2)*PixelsPerPoint, SCREEN_HEIGHT-100-(h[innerPtr]*100));
  }
  
  strokeWeight(1);
  // plot original data point
  stroke(COLOR_ORIGINAL_DATA);
  point((outerPtr-1)*PixelsPerPoint, SCREEN_HEIGHT-x[outerPtr]);
  
  for (int innerPtr = 0; innerPtr < impulseDataLength; innerPtr++) { // increment the inner loop pointer
    //delay(5);
    //plot impulse data point
    stroke(COLOR_IMPULSE_DATA); // impulse color
    point((outerPtr+innerPtr-1)*PixelsPerPoint, SCREEN_HEIGHT-100-(h[innerPtr]*100));  // draw new impulse point
    y[outerPtr+innerPtr-1] = y[outerPtr+innerPtr-1] + x[outerPtr-1] * h[innerPtr];  //convolve (the magic line)
  }

  //plot the output data
  stroke(COLOR_OUTPUT_DATA);
  point((outerPtr-(impulseDataLength/2)-1)*PixelsPerPoint, SCREEN_HEIGHT-y[outerPtr]);
  outerPtr++;  // increment the outer loop pointer
}

public void newInputData(){
  for (int c = 0; c < inputDataLength; c++) {
    noiseInput = noiseInput + noiseIncrement;
    x[c] = map(noise(noiseInput), 0, 1, 0, SCREEN_HEIGHT);
    //numbers[c] = floor(random(height));
   }
}

void newKernelData() {
  float kernelSum = 0;        
  float kernelSumNormal = 0; 
  
  // set all data values to zero
  for (int c = 0; c < impulseDataLength; c++) {
     h[c] = 0;
  }

  // Gaussian mask, the "bell curve" shape
  // this impulse response is used to blur or smooth images
  h[0] = 0.03607497;
  h[1] = 0.13533528;
  h[2] = 0.41111228;
  h[3] = 0.8007374;
  h[4] = 1;
  h[5] = 0.8007374;
  h[6] = 0.41111228;
  h[7] = 0.13533528;
  h[8] = 0.03607497;
  
  for (int c = 0; c < impulseDataLength; c++) {
    kernelSum+=h[c]; 
  }
 
   // normalization of the kernel values to make them range from 0 to 1.
  for (int i=0; i<h.length; i++) 
  {
    if (h[i] != 0) 
    {
      h[i] = h[i] / kernelSum; // could have used map(), but this works ok to normalize
      
      // added this to verify we properly normalized the plot, final sum should be very close to 1
      kernelSumNormal+= h[i];
      
      println("normalized kernel[" + i + "]:" + h[i]); // print the normalized kernel value.
    }else 
    {
      println("normalized kernel[" + i + "]:" + h[i]); // print the zero kernel value.
    }
  }
  
  println("kernelSum:" + kernelSum); 
  println("kernelSumNormal:" + kernelSumNormal);
}

public void zeroOutputData(){
  for (int c = 0; c < outputDataLength; c++) {
    y[c] = 0;
   }
}

public void resetData(){
  outerPtr = 1;
  impulsePtr = 0;
  newInputData(); // make some new random noise
  zeroOutputData();
  
  if(noiseInput > 100){
    noiseInput = noiseIncrement;
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
  text("Output data, shifted back into original phase", rectX+20, rectY+10);
  
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