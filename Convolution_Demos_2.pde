/*
Convolution_Demos_2.pde, a demo of convolution, with a special function that dynamically creates the kernel coefficients 
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
color COLOR_DERIVATIVE_1 = color(0, 255, 0);
color COLOR_OUTPUT_DATA = color(255, 0, 255);
color COLOR_EDGES = color(0, 255, 0);

int INPUT_DATA_LENGTH = 0;           // number of discrete values in the input array
int KERNEL_LENGTH = 0;               // number of discrete values in the kernel array, set in setup()
int OUTPUT_DATA_LENGTH = 0;          // number of discrete values in the output array, set in setup()
int outerPtr = 0;                    // outer loop pointer
int kernelDrawYOffset = 100;         // height above bottom of screen to draw the kernel data points

float gaussianKernelSigma = 1.5;     // input to kernel creation function, controls spreading of gaussian kernel
float loGKernelSigma = 1.4;          // input to kernel creation function, controls spreading of loG kernel
float kernelMultiplier = 100.0;      // multiplies the plotted y values of the kernel, for greater visibility since they are small
float noiseInput = 0.05;             // used for generating smooth noise for original data; lower values are smoother noise
float noiseIncrement = noiseInput;   // the increment of change of the noise input

final int SCREEN_X_MULT = 4;
final int SCREEN_HEIGHT = 800;
final int HALF_SCREEN_HEIGHT = SCREEN_HEIGHT/2;
final int QTR_SCREEN_HEIGHT = SCREEN_HEIGHT/4;

int SCREEN_WIDTH = 0;

// a menu of various kernels, example: kernel = setArray(gaussian); // remember to comment out the other kernel makers
private float [] gaussian = {0.0048150257, 0.028716037, 0.10281857, 0.22102419, 0.28525233, 0.22102419, 0.10281857, 0.028716037, 0.0048150257};
private float [] sorbel = {1, 0, -1};
private float [] gaussianLaplacian = {2, 6, 0, -24, -40, -24, 0, 6, 2};
private float [] laplacian = {1,-2, 1}; 

int[] input = new int[0];        // array for input signal
float[] kernel = new float[0];       // array for impulse response, or kernel
float[] output = new float[0];       // array for output signal
float[] output2 = new float[0];       // array for output signal

void setup() {
  
  // create a kernel
  //kernel = setArray(gaussian); // set the kernel, choose from above
  //kernel = setArray(sorbel); // set the kernel, choose from above
  //kernel = setArray(gaussianLaplacian); // set the kernel, choose from above
  //kernel = setArray(laplacian); // set the kernel, choose from above
  
  kernel = makeGaussKernel1d(gaussianKernelSigma); 
  // Gaussian Laplacian (combination of Gaussian and Laplacian, the 'Mexican Hat Filter')
  //kernel = createLoGKernal1d(loGKernelSigma); 
  
  KERNEL_LENGTH = kernel.length; 
  //KERNEL_LENGTH = 0;
  println("KERNEL_LENGTH = " + KERNEL_LENGTH);
  
  // A menu of various input data sources and waveforms, leave one un-commented
  // random noise option is commented out in resetData(), uncomment to set random data input
  
  input = setHardCodedSensorData(0.125);
  
  // a single adjustable step impulse, useful for verifying the kernel is doing what it should.
  //input = setInputSingleImpulse(INPUT_DATA_LENGTH, 150, 20, KERNEL_LENGTH/2, false); 
  
  // an adjustable square wave
  //input = setInputSquareWave(INPUT_DATA_LENGTH, 50, 50);
  
  INPUT_DATA_LENGTH = input.length;
  println("INPUT_DATA_LENGTH = " + INPUT_DATA_LENGTH);
  
  // number of discrete values in the output array
  OUTPUT_DATA_LENGTH = INPUT_DATA_LENGTH + KERNEL_LENGTH;
  
  // arrays for output signals, get resized after kernel size is known
  output = new float[OUTPUT_DATA_LENGTH];                 
  output2 = new float[OUTPUT_DATA_LENGTH];
                    
  // the data length times the number of pixels per data point
  SCREEN_WIDTH = OUTPUT_DATA_LENGTH*SCREEN_X_MULT;

  // set the screen dimentions
  surface.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
  background(0);
  frameRate(100);
  resetData();
  
  println("SCREEN_WIDTH: " + SCREEN_WIDTH);
  println("SCREEN_HEIGHT: " + SCREEN_HEIGHT);
}
    
void draw() {
  if (outerPtr >= OUTPUT_DATA_LENGTH) {
    delay(2000);
    resetData();
  }
  
  if (outerPtr == 0) {
    // draw the x and y aixs
    background(0);
    drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 8);
    drawLegend();
  }
  // some indexes for scaling plotted data to screen X axis (width)
  int scrOuterPtr = outerPtr*SCREEN_X_MULT;
  int scrShiftedOuterPtr = (outerPtr-(KERNEL_LENGTH/2))*SCREEN_X_MULT;
  float scrDshiftedOuterPtr = ((outerPtr-0.5)-(KERNEL_LENGTH/2))*SCREEN_X_MULT;
  
  // plot the kernel data point
  // draw new kernel point (scaled up for visibility
  if (outerPtr < KERNEL_LENGTH) {
    strokeWeight(1);
    stroke(COLOR_IMPULSE_DATA); // impulse color
    point(scrOuterPtr+(width/2)-(KERNEL_LENGTH*SCREEN_X_MULT)/2, 
    SCREEN_HEIGHT-kernelDrawYOffset-(kernel[outerPtr] * kernelMultiplier));
  }
  
  // plot original data point
  strokeWeight(1);
  stroke(COLOR_ORIGINAL_DATA);
  if (outerPtr < INPUT_DATA_LENGTH){
    point(scrOuterPtr, HALF_SCREEN_HEIGHT-input[outerPtr]);
    // draw section of greyscale bar showing the 'color' of original data values
    greyscaleBarMapped(scrOuterPtr, 0, input[outerPtr]);
    
    // convolution inner loop
    for (int innerPtr = 0; innerPtr < KERNEL_LENGTH; innerPtr++) { // increment the inner loop pointer
      // convolution (the magic line)
      output[outerPtr+innerPtr] = output[outerPtr+innerPtr] + input[outerPtr] * kernel[innerPtr]; 
    }
  }
  
  // plot the output data
  stroke(COLOR_OUTPUT_DATA);
  point(scrShiftedOuterPtr, HALF_SCREEN_HEIGHT-(output[outerPtr]));
  //println("output[" + outerPtr + "]" +output[outerPtr]);
 
  // draw section of greyscale bar showing the 'color' of output data values
  greyscaleBarMapped(scrShiftedOuterPtr, 11, output[outerPtr]);
 
  // find 1st derivative, the difference between adjacent points in the output[] array
  if (outerPtr > 0) {
    stroke(COLOR_DERIVATIVE_1);
    if (outerPtr > 0){
      output2[outerPtr] = output[outerPtr] - output[outerPtr-1];
      point(scrDshiftedOuterPtr, HALF_SCREEN_HEIGHT-output2[outerPtr]);
      // draw section of greyscale bar showing the 'color' of output2 data values
      greyscaleBarMappedAbs(scrShiftedOuterPtr, 22, output2[outerPtr]);
    }
  }

  outerPtr++;  // increment the outer loop pointer
}

void greyscaleBarDirect(float x, float y, float pColor) {
  
  byte bColor = byte(pColor);
  
  noStroke();
  fill(bColor, bColor, bColor);
  rect(x, y, SCREEN_X_MULT, 10);
}

void greyscaleBarMapped(float x, float y, float value) {
  // prepare color to correspond to sensor pixel reading
  byte bColor = byte(map(value, 0, QTR_SCREEN_HEIGHT, 0, 255));
  // Plot a row of pixels near the top of the screen ,
  // and color them with the 0 to 255 greyscale sensor value
  
  noStroke();
  fill(bColor, bColor, bColor);
  rect(x, y, SCREEN_X_MULT, 10);
}

void greyscaleBarMappedAbs(float x, float y, float value) {
  // prepare color to correspond to sensor pixel reading
  byte bColor = byte(abs(map(value, 0, QTR_SCREEN_HEIGHT, 0, 255)));
  // Plot a row of pixels near the top of the screen ,
  // and color them with the 0 to 255 greyscale sensor value
  
  noStroke();
  fill(bColor, bColor, bColor);
  rect(x, y, SCREEN_X_MULT, 10);
}


float [] setArray(float [] inArray) {
  
  float[] kernel = new float[inArray.length]; // set to an odd value for an even integer phase offset
  kernel = inArray;
  
  for (int i = 0; i < kernel.length; i++) {
    println("setArray kernel[" + i + "] = " + kernel[i]);
  }
  
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

  // scaling variables
  double sum = 0;
  double scale = 1;
  
  // create the kernel
  int center = (int) (3.0 * sigma);
  // using a double internally for greater precision
  // set to an odd value for an even integer phase offset
  double[] kernel = new double [2*center+1]; 
  // using a float for the final return value
  float[] fkernel = new float [2*center+1];
  
  // fill the kernel
  double sigmaSquared = sigma * sigma;
  for (int i=0; i<kernel.length; i++) {
    double r = center - i;
    kernel[i] = (double) Math.exp(-0.5 * (r*r)/ sigmaSquared);
    sum += kernel[i];
    println("gaussian kernel[" + i + "] = " + kernel[i]);
  }
  
  if (sum!=0.0){
    scale = 1.0/sum;
  } else {
    scale = 1;
  }
  
  println("gaussian kernel scale = " + scale); // print the scale.
  sum = 0; // clear the previous sum
  // scale the kernel values
  for (int i=0; i<kernel.length; i++){
    kernel[i] = kernel[i] * scale;
    fkernel[i] = (float) kernel[i];
    sum += kernel[i];
    // print the kernel value.
    println("scaled gaussian kernel[" + i + "]:" + fkernel[i]); 
  }
  
  if (sum!=0.0){
    scale = 1.0/sum;
  } else {
    scale = 1;
  }
  
  // print the new scale. Should be very close to 1.
  println("gaussian kernel new scale = " + scale); 
  return fkernel;
}

float[] createLoGKernal1d(double deviation) {
  int center = (int) (4 * deviation);
  int kSize = 2*center+1; // set to an odd value for an even integer phase offset
  // using a double internally for greater precision
  double[] kernel = new double[kSize];
  // using a float for the final return value
  float[] fkernel = new float [kSize];  // float version for return value
  double first = 1.0 / (Math.PI * Math.pow(deviation, 4.0));
  double second = 2.0 * Math.pow(deviation, 2.0);
  double third;
  int r = kSize / 2;
  int x;
  for (int i = -r; i <= r; i++) {
      x = i + r;
      third = Math.pow(i, 2.0) / second;
      kernel[x] = (double) (first * (1 - third) * Math.exp(-third));
      fkernel[x] = (float) kernel[x];
      println("LoG kernel[" + x + "] = " + kernel[x]);
  }
  return fkernel;
}

public void zeroOutputData(){
  for (int c = 0; c < OUTPUT_DATA_LENGTH; c++) {
    output[c] = 0;
   }
}

public void resetData(){
  outerPtr = 0;
  
  // uncomment to make some new random noise for each draw loop
  // setInputRandomData(); 
  
  zeroOutputData();
  
  if(noiseInput > 100){
    noiseInput = noiseIncrement;
  }
}

void setInputRandomData(){
  
  for (int c = 0; c < INPUT_DATA_LENGTH; c++) {
    // adjust smoothness with noise input
    noiseInput = noiseInput + noiseIncrement;  
    // perlin noise
    input[c] = int(map(noise(noiseInput), 0, 1, -QTR_SCREEN_HEIGHT, QTR_SCREEN_HEIGHT));  
    //println (noise(noiseInput));
   }
   
}

int[] setHardCodedSensorData(float scale){
  // set this to the number of bits in each Teensy ADC value read from the sensor
  int NBITS_ADC = 12;
  int HIGHEST_ADC_VALUE = int(pow(2.0, float(NBITS_ADC))-1);
  int HALF_HIGHEST_ADC_VALUE = HIGHEST_ADC_VALUE / 2;
  int len = 70;
  int[] data = new int[len];
  data[0] = 3343;
  data[1] = 3305;
  data[2] = 3327;
  data[3] = 3388;
  data[4] = 3459;
  data[5] = 3429;
  data[6] = 3414;
  data[7] = 3425;
  data[8] = 3430;
  data[9] = 3425;
  data[10] = 3362;
  data[11] = 3317;
  data[12] = 3418;
  data[13] = 3402;
  data[14] = 3282;
  data[15] = 3370;
  data[16] = 3439;
  data[17] = 3373;
  data[18] = 3445;
  data[19] = 3363;
  data[20] = 3290;
  data[21] = 2947;
  data[22] = 2327;
  data[23] = 1824;
  data[24] = 1603;
  data[25] = 1314;
  data[26] = 1022;
  data[27] = 513;
  data[28] = 331;
  data[29] = 323;
  data[30] = 297;
  data[31] = 280;
  data[32] = 286;
  data[33] = 263;
  data[34] = 260;
  data[35] = 270;
  data[36] = 257;
  data[37] = 249;
  data[38] = 248;
  data[39] = 260;
  data[40] = 245;
  data[41] = 236;
  data[42] = 240;
  data[43] = 254;
  data[44] = 236;
  data[45] = 238;
  data[46] = 240;
  data[47] = 271;
  data[48] = 313;
  data[49] = 856;
  data[50] = 1331;
  data[51] = 1701;
  data[52] = 2093;
  data[53] = 2403;
  data[54] = 2753;
  data[55] = 3144;
  data[56] = 3296;
  data[57] = 3283;
  data[58] = 3285;
  data[59] = 3298;
  data[60] = 3337;
  data[61] = 3299;
  data[62] = 3338;
  data[63] = 3366;
  data[64] = 3405;
  data[65] = 3371;
  data[66] = 3356;
  data[67] = 3370;
  data[68] = 3378;
  data[69] = 3304;
  
  for (int i = 0; i < len; i++) {
    // map so the midpoint of the range falls on zero, and multiply by decimal fraction scale to fit on screen.
    data[i] = int(map(data[i], 0, HIGHEST_ADC_VALUE, -HALF_HIGHEST_ADC_VALUE * scale, HALF_HIGHEST_ADC_VALUE * scale));
  }
  
  return data;
}

int[] setInputSingleImpulse(int dataLength, int pulseHeight, int pulseWidth, int offset,boolean positivePolarity){
  
  if (pulseWidth < 2) {
    pulseWidth = 2;
  }
 
  int center = dataLength/2+offset;
  
  int halfPositives = pulseWidth /2;
  int startPos = center - halfPositives;
  int stopPos = center + halfPositives;
  
  int[] data = new int[dataLength];// even size
  
  // head
  for (int c = 0; c < dataLength; c++) {
    data[c] = 0;
  }
  
  // pulse
  if (positivePolarity){
    for (int c = startPos; c < stopPos; c++) {
      data[c] = pulseHeight;
    }
  }else{
    for (int c = startPos; c < stopPos; c++) {
      data[c] = -pulseHeight;
    }
  }
   
   // tail
   for (int c = stopPos; c < dataLength; c++) {
     data[c] = 0;
   }
   return data;
}

int[] setInputSquareWave(int dataLength, int wavelength, int waveHeight){
  
  double sinPoint = 0;
  double squarePoint = 0;
  int data[] = new int[dataLength];
  
  for( int i = 0; i < data.length; i++ )
  {
     sinPoint = Math.sin(2 * Math.PI * i/wavelength);
     squarePoint = Math.signum(sinPoint);
     //println(squarePoint);
     data[i] =(int)(squarePoint) * waveHeight;
  }
  return data;
}

void drawLegend() {
  int rectX, rectY, rectWidth, rectHeight;
  
  rectX = 30;
  rectY = 45;
  rectWidth = 10;
  rectHeight = 10;
 
  // draw a legend showing what each color represents
  strokeWeight(1);
  
  stroke(COLOR_ORIGINAL_DATA);
  fill(COLOR_ORIGINAL_DATA);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("Original input Data", rectX+20, rectY+10);
  
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
  
  rectY+=20;
  stroke(COLOR_DERIVATIVE_1);
  fill(COLOR_DERIVATIVE_1);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("1st derivative (slope of output data)", rectX+20, rectY+10);
  
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
} //<>//