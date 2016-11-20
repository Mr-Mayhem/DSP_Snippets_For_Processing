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

int INPUT_DATA_LENGTH = 512;        // number of discrete values in the array
int KERNEL_LENGTH = 0;              // use odd KERNEL_LENGTH to produce an even integer phase offset
int OUTPUT_DATA_LENGTH = 0;           // number of discrete values in the array
int outerPtr = 0;                   // outer loop pointer
float kernelSigma = 6;             // input to kernel creation function, controls spreading of gaussian kernel
float kernelScale = 1;              // rescales output to compensate for kernel bias 
float kernelMultiplier = 100.0;     // multiplies the plotted y values of the kernel, for greater visibility since they are small

float noiseInput = 0.07;            // used for generating smooth noise for original data; lower values are smoother noise
float noiseIncrement = noiseInput;  // the increment of change of the noise input

float[] input = new float[INPUT_DATA_LENGTH];   // array for input signal
float[] kernel = new float[KERNEL_LENGTH];      // array for impulse response
float[] output = new float[OUTPUT_DATA_LENGTH];   // array for output signal

final int SCREEN_X_MULTIPLIER = 2;
int SCREEN_WIDTH = OUTPUT_DATA_LENGTH*SCREEN_X_MULTIPLIER;
final int SCREEN_HEIGHT = 800;
final int HALF_SCREEN_HEIGHT = SCREEN_HEIGHT/2;

void setup() {
  // create the kernel
  
  kernel = makeGaussKernel1d(kernelSigma); // the input argument is the sigma, higher numbers smooth more, via wider kernels
  //kernel = createKernelDirectly1d();

  kernelScale = getKernelScale(kernel);
  KERNEL_LENGTH = kernel.length; // use odd KERNEL_LENGTH to produce an even integer phase offset
  println("KERNEL_LENGTH = " + KERNEL_LENGTH);
  
  // create the input data
  // a single adjustable impluse, useful for verifying kernel for expected output results
  input = setInputSingleImpulse(INPUT_DATA_LENGTH, 50, KERNEL_LENGTH/2, false); 
  INPUT_DATA_LENGTH = input.length;
  println("INPUT_DATA_LENGTH = " + INPUT_DATA_LENGTH);
  
  OUTPUT_DATA_LENGTH = INPUT_DATA_LENGTH + KERNEL_LENGTH; //number of discrete values in the array
  output = new float[OUTPUT_DATA_LENGTH]; // array for output signal gets resized after kernel size is known
  SCREEN_WIDTH = OUTPUT_DATA_LENGTH*SCREEN_X_MULTIPLIER;
  
  surface.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
  background(0);
  frameRate(100);
  resetData();
}
    
 void draw() {
  if (outerPtr >= INPUT_DATA_LENGTH) {
    resetData();
  }
  
  if (outerPtr == 0) {
    // draw the x and y aixs
    background(0);
    drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 8);
    drawLegend();
  }

  // plot original data point
  strokeWeight(1);
  stroke(COLOR_ORIGINAL_DATA);
  point(outerPtr*SCREEN_X_MULTIPLIER, SCREEN_HEIGHT-input[outerPtr]);
  
  // plot the kernel data point
  // draw new kernel point (scaled up for visibility
  if (outerPtr < KERNEL_LENGTH) {
    strokeWeight(1);
    stroke(COLOR_IMPULSE_DATA); // impulse color
    point(outerPtr*SCREEN_X_MULTIPLIER+(width/2)-(KERNEL_LENGTH*SCREEN_X_MULTIPLIER)/2, SCREEN_HEIGHT-150-(int(kernel[outerPtr] *kernelScale * kernelMultiplier)));
  }
  
  for (int innerPtr = 0; innerPtr < KERNEL_LENGTH; innerPtr++) { // increment the inner loop pointer
    // convolution (the magic line)
    output[outerPtr+innerPtr] = output[outerPtr+innerPtr] + input[outerPtr] * kernel[innerPtr]; 
  }

  //plot the output data
  stroke(COLOR_OUTPUT_DATA);
  point((outerPtr-(KERNEL_LENGTH/2))*SCREEN_X_MULTIPLIER, SCREEN_HEIGHT-(output[outerPtr]*kernelScale));
  
  outerPtr++;  // increment the outer loop pointer
}

float [] createKernelDirectly1d() {

  float[] kernel = new float[9]; // odd size

  // Gaussian mask, the "bell curve" shape
  // this impulse response is used to blur or smooth images
  kernel[0] = 0.03607497;
  kernel[1] = 0.13533528;
  kernel[2] = 0.41111228;
  kernel[3] = 0.8007374;
  kernel[4] = 1;
  kernel[5] = 0.8007374;
  kernel[6] = 0.41111228;
  kernel[7] = 0.13533528;
  kernel[8] = 0.03607497;
  
  return kernel;
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
 
  // create the kernel
  int center = (int) (3.0 * sigma);
  float[] kernel = new float [2*center+1]; // odd size
  
  // fill the kernel
  double sigmaSquared = sigma * sigma;
  for (int i=0; i<kernel.length; i++) {
    double r = center - i;
    kernel[i] = (float) Math.exp(-0.5 * (r*r)/ sigmaSquared);
  }
  
  return kernel;
}

float getKernelScale(float[] kernel) {
  float scale = 1.0;
  float sum = 0.0;
  
  for (int i=0; i<kernel.length; i++){
    sum += kernel[i];
    println("kernel[" + i + "]:" + kernel[i]); // print the kernel value.
  }
  
  if (sum!=0.0){
    scale = 1.0/sum;
  }
  //for (int i=0; i<kernel.length; i++){
  //  kernel[i] = kernel[i] * scale;
  //  println("scaled kernel[" + i + "]:" + kernel[i]); // print the kernel value.
  //}
  
  println("sum:" + sum); // print the kernel sum.
  println("kernel scale:" + scale); // print the kernel scale.
  return scale;
}

public void zeroOutputData(){
  for (int c = 0; c < OUTPUT_DATA_LENGTH; c++) {
    output[c] = 0;
   }
}

public void resetData(){
  outerPtr = 0;
  //setInputRandomData(); // uncomment to make some new random noise and put it into inputData
  zeroOutputData();
  
  if(noiseInput > 100){
    noiseInput = noiseIncrement;
  }
}

float[] setInputSingleImpulse(int dataLength, int pulseWidth, int offset, boolean positivePolarity){
  
  if (pulseWidth < 2) {
    pulseWidth = 2;
  }
 
  int center = dataLength/2+offset;
  
  int halfPositives = pulseWidth /2;
  int startPos = center - halfPositives;
  int stopPos = center + halfPositives;
  
  float[] data = new float[dataLength];// even size
  
  // head
  for (int c = 0; c < startPos; c++) {
    data[c] = HALF_SCREEN_HEIGHT;;
  }
  
  // pulse
  if (positivePolarity){
    for (int c = startPos; c < stopPos; c++) {
      data[c] = HALF_SCREEN_HEIGHT+150;
    }
  }else{
    for (int c = startPos; c < stopPos; c++) {
      data[c] = HALF_SCREEN_HEIGHT-150;
    }
  }
   
   // tail
   for (int c = stopPos; c < dataLength; c++) {
     data[c] = HALF_SCREEN_HEIGHT;
   }
   return data;
}

public void setInputRandomData(){

  for (int c = 0; c < INPUT_DATA_LENGTH; c++) {
    noiseInput = noiseInput + noiseIncrement;  // adjust smoothness with noise input
    input[c] = map(noise(noiseInput), 0, 1, 0, SCREEN_HEIGHT);  // perlin noise
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