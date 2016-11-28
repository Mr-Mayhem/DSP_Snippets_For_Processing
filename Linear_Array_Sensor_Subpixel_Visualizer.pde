/*
Linear_Array_Sensor_Subpixel_Visualizer.pde, a demo of edge detection in one dimension

Created by Douglas Mayhew, November 20, 2016.
Released into the public domain, except:
 * The function, 'makeGaussKernel1d' is made available as part of the book 
 * "Digital Image * Processing - An Algorithmic Introduction using Java" by Wilhelm Burger
 * and Mark J. Burge, Copyright (C) 2005-2008 Springer-Verlag Berlin, Heidelberg, New York.
 * Note that this code comes with absolutely no warranty of any kind.
 * See http://www.imagingbook.com for details and licensing conditions. 

See: https://github.com/Mr-Mayhem/DSP_Snippets_For_Processing

Convolution loop code originally from //http://www.dspguide.com/ch6/3.htm
translated into Processing (java) by Douglas Mayhew

 For more info on 3 point quadratic interpolation, see the subpixel edge finding method described in F. Devernay,
 A Non-Maxima Suppression Method for Edge Detection with Sub-Pixel Accuracy
 RR 2724, INRIA, nov. 1995
 http://dev.ipol.im/~morel/Dossier_MVA_2011_Cours_Transparents_Documents/2011_Cours1_Document1_1995-devernay--a-non-maxima-suppression-method-for-edge-detection-with-sub-pixel-accuracy.pdf

 quadratic interpolation subpixel code is my hodge-podge of looking at many 'remixes' of the 
 Filament Width Sensor Prototype by flipper, as well as my own refactoring of many bits and pieces.
 
 see Filament Width Sensor Prototype by flipper:
 https://www.thingiverse.com/thing:454584
 
 Another example filament width sensor with quadratic interpolation subpixel code is the "Zabe Width Sensor"
 see Filament Width Sensor - TSL1402R + Arduino Mega (Work-in-progress):
 https://www.thingiverse.com/thing:668377

 This sketch is able to run the subpixel position code against various data sources. 
 The sketch can synthesize some input data like square impulses, to verify that the output is 
 doing what it should. It also works with live sensor data from a TSL1402R or TSL1410R linear photodiode array, 
 arriving via USB serial port. To do this,
 see my 2 projects:
 
 Read-TSL1402R-Optical-Sensor-using-Teensy-3.x
 https://github.com/Mr-Mayhem/Read-TSL1402R-Optical-Sensor-using-Teensy-3.x
 
 and...
 
 Read-TSL1410R-Optical-Sensor-using-Teensy-3.x
 https://github.com/Mr-Mayhem/Read-TSL1410R-Optical-Sensor-using-Teensy-3.x
 
 This is a work in progress, but the subpixel code works nicely, and looks like it is proper.
 If you find any bugs, let me know via github or the Teensy forums in the following thread:
 https://forum.pjrc.com/threads/39376-New-library-and-example-Read-TSL1410R-Optical-Sensor-using-Teensy-3-x
 
 We still have some more refactoring and features yet to apply. I want to add:
 windowing and thresholding to reduce the workload of processing all data to processing only some data
 interpolation is not yet in this one.
 Bringing the core of the position and subpixel code into Arduino for Teensy 3.6, so it can
 1. Send shadow position and width instead of raw data, which is slower.
 2. Send a windowed section containing only the interesting data, rather than all the data.
 3. Auto-Calibration using drill bits, dowel pins, etc.
 4. Multiple angles of led lights shining on the target, so multiple exposures may be compared 
    for additional subpixel accuracy
*/
// ==============================================================================================
// imports:

import processing.serial.*;

// ==============================================================================================
// colors

color COLOR_ORIGINAL_DATA = color(255);
color COLOR_KERNEL_DATA = color(255, 255, 0);
color COLOR_DERIVATIVE1_OF_OUTPUT = color(0, 255, 0);
color COLOR_OUTPUT_DATA = color(255, 0, 255);
color COLOR_EDGES = color(0, 255, 0);
// ==============================================================================================
// Constants:

final int ADC_BIT_DEPTH = 12; // the number of bits data values consist of
final int HIGHEST_ADC_VALUE = int(pow(2.0, float(ADC_BIT_DEPTH))-1); // this value is 4095 for 12 bits
final int PREFIX = 0xFF; // unique byte used to sync the filling of byteArray to the incoming serial stream
// ==============================================================================================
// Arrays:

byte[] byteArray = new byte[0];  // array of raw serial data bytes
int[] input = new int[0];        // array for input signal
float[] kernel = new float[0];   // array for impulse response, or kernel
int[] output = new int[0];       // array for output signal
int[] output2 = new int[0];      // array for output signal
int[] edges = new int[0];        // array for edges signal

// a menu of various one dimensional kernels, example: kernel = setArray(gaussian); 
private float [] gaussian = {0.0048150257, 0.028716037, 0.10281857, 0.22102419, 0.28525233, 0.22102419, 0.10281857, 0.028716037, 0.0048150257};
private float [] sorbel = {1, 0, -1};
private float [] gaussianLaplacian = {-7.474675E-4, -0.0123763615, -0.04307856, 0.09653235, 0.31830987, 0.09653235, -0.04307856, -0.0123763615, -7.474675E-4};
private float [] laplacian = {1, -2, 1}; 
// ==============================================================================================
// Global Variables:

int dataSource = 0;         // selects a data source
int kernelSource = 0;       // selects a kernel
int SENSOR_PIXELS = 0;      // number of discrete values in the input array, 1 per linear array sensor pixel
int N_BYTES_PER_SENSOR_FRAME = 0; // we use 2 bytes to represent each sensor pixel
int N_BYTES_PER_SENSOR_FRAME_PLUS1 = 0; // the data bytes + the PREFIX byte
int SCALE_X = 8;
int SCREEN_HEIGHT = int(HIGHEST_ADC_VALUE * 0.25); // scales screen height relative to highest data value
int HALF_SCREEN_HEIGHT = SCREEN_HEIGHT/2;
int KERNEL_LENGTH = 0;      // number of discrete values in the kernel array, set in setup() 
int HALF_KERNEL_LENGTH = 0; // Half the kernel length, used to correct convoltion phase shift
int OUTPUT_DATA_LENGTH = 0; // number of discrete values in the output array, set in setup()
int outerPtrX = 0;          // outer loop pointer
int innerPtrX = 0;          // inner loop pointer for convolution
int kernelDrawYOffset = 50; // height above bottom of screen to draw the kernel data points
int markSize = 3;           // diameter of drawn subpixel marker circles
int bytesRead = 0;          // number of bytes actually read out from the serial buffer
int availableBytesDraw = 0; // used to show the number of bytes present in the serial buffer

float SCALE_Y = 0.12;                        // scales plotted data height, and is a decimal fraction of HIGHEST_ADC_VALUE
float gaussianKernelSigma = 1.5;             // input to kernel creation function, controls spreading of gaussian kernel
float loGKernelSigma = 1.0;                  // input to kernel creation function, controls spreading of loG kernel
float kernelMultiplier = 100.0;              // multiplies the plotted y values of the kernel, for greater visibility since they are small
float noiseInput = 0.05;                     // used for generating smooth noise for original data; lower values are smoother noise
float noiseIncrement = noiseInput;           // the increment of change of the noise input
float sensorPixelSpacing = 0.0635;           // 63.5 microns
float sensorPixelsPerMM = 15.74803149606299; // number of pixels per mm in sensor TSL1402R and TSL1410R
float sensorWidthAllPixels = 16.256;         // millimeters

// used to count sensor data frames
int chartRedraws = 0;

// width
int SCREEN_WIDTH = 0;
int HALF_SCREEN_WIDTH = 0;

// phase correction drawing pointers
int drawPtrX = 0;
int drawPtrXLessK = 0;
float drawPtrXLessKandD1 = 0;

// ==============================================================================================
// Set Objects
Serial myPort;  
// ==============================================================================================

void setup() {
// ==============================================================================================
  // Set the data & screen scaling:
  
  SCALE_X = 1;                                    // set x pixels (width) per data point
  SCALE_Y = 0.0625;                                // set y size (height) is shrunk by this decimal fraction multiplier
  SCREEN_HEIGHT = int(HIGHEST_ADC_VALUE * 0.125); // set screen height relative to the highest ADC value, 4095 for 12 bits
  HALF_SCREEN_HEIGHT = SCREEN_HEIGHT/2;           // leave alone. Used in many places to center data at middle height
  
// ==============================================================================================
  // Choose a kernel source:
  kernelSource = 0;
// ==============================================================================================  
  
  switch (kernelSource) {
    case 0:
      // a dynamically created gaussian bell curve kernel
      kernel = makeGaussKernel1d(gaussianKernelSigma); 
      break;
    case 1:
      // a hard-coded gaussian kernel
      kernel = setArray(gaussian);
      break;
    default:
      // a hard-coded gaussian kernel, hard to mess up.
      kernel = setArray(gaussian);
  }
  
  KERNEL_LENGTH = kernel.length; 
  println("KERNEL_LENGTH: " + KERNEL_LENGTH);
  HALF_KERNEL_LENGTH = KERNEL_LENGTH / 2;
  
  // some other kernels we experimented with, but don't need here because our preferred subpixel edge detection method is decided.
  
  // A hard-coded Sorbel kernel
  // kernel = setArray(sorbel);
  
  // Laplacians are used to find edges using the 2nd derivative method, by looking for zero-crossings after running it.
  // but our preferred method of fitting a parabola to the peaks of the 1st derivative is more accurate, it being a sub-pixel method.
  
  // A hard-coded Laplacian kernel
  // kernel = setArray(laplacian);
  
  // A hard-coded Gaussian-Laplacian kernel
  // This kernel saves a convolution step by combining two kernels which would otherwise be run seperately, into one.
  // kernel = setArray(gaussianLaplacian);

  // A dynamically created Gaussian Laplacian kernel (combination of Gaussian and Laplacian, the 'Mexican Hat Filter')
  // This kernel saves a convolution step by combining two kernels which would otherwise be run seperately, into one.
  // kernel = createLoGKernal1d(loGKernelSigma); 
  
// ==============================================================================================
  // Choose a data source:
  dataSource = 3;
// ==============================================================================================
  
  switch (dataSource) {
    case 0: // hard-coded sensor data containing a shadow edge profile
      input = setHardCodedSensorData(); 
      SENSOR_PIXELS = input.length;
      break;
    case 1:
      // a single adjustable step impulse, (square pos or neg pulse) 
      // useful for verifying the kernel is doing what it should.
      input = setInputSingleImpulse(32, 1023, 10, (KERNEL_LENGTH/2)+1, false);
      SENSOR_PIXELS = input.length;
      break;
    case 2: // an adjustable square wave
      input = setInputSquareWave(128, 40, 1023);
      SENSOR_PIXELS = input.length;
      break;
    case 3: // Serial Data from Teensy 3.6 driving TSL1402R or TSL1410R linear photodiode array
      SENSOR_PIXELS = 1280; // Number of pixel values, 256 for TSL1402R sensor, and 1280 for TSL1410R sensor
      N_BYTES_PER_SENSOR_FRAME = SENSOR_PIXELS * 2; // we use 2 bytes to represent each sensor pixel
      N_BYTES_PER_SENSOR_FRAME_PLUS1 = N_BYTES_PER_SENSOR_FRAME + 1; // the data bytes + PREFIX byte
      byteArray = new byte[N_BYTES_PER_SENSOR_FRAME_PLUS1]; // array of raw serial data bytes
      input = new int[SENSOR_PIXELS];
      break;
    default:
      // hard-coded sensor data containing a shadow edge profile
      input = setHardCodedSensorData(); 
      SENSOR_PIXELS = input.length;
  }
  
  // random noise option is commented out in resetData(), uncomment to set random data input

  println("SENSOR_PIXELS = " + SENSOR_PIXELS);
  
  // number of discrete values in the output array
  OUTPUT_DATA_LENGTH = SENSOR_PIXELS + KERNEL_LENGTH-1;
  println("OUTPUT_DATA_LENGTH = " + OUTPUT_DATA_LENGTH);
  
  // arrays for output signals, get resized after kernel size is known
  output = new int[OUTPUT_DATA_LENGTH];                 
  output2 = new int[OUTPUT_DATA_LENGTH];
   
  // array for edge detector output, get resized after kernel size is known
  //edges = new int[OUTPUT_DATA_LENGTH];                    
  
  // the data length times the number of pixels per data point
  SCREEN_WIDTH = (OUTPUT_DATA_LENGTH) * SCALE_X;
  HALF_SCREEN_WIDTH = SCREEN_WIDTH / 2;
  
  // set the screen dimentions
  surface.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
  background(0);
  frameRate(20);
  resetData();
  
  println("SCREEN_WIDTH: " + SCREEN_WIDTH);
  println("SCREEN_HEIGHT: " + SCREEN_HEIGHT);
  
  if (dataSource == 3){
    noLoop();
    // Set up serial connection
    myPort = new Serial(this, "COM5", 12500000);
    // the serial port will buffer until prefix (unique byte that equals 255) and then fire serialEvent()
    myPort.bufferUntil(PREFIX);
  }
}

void serialEvent(Serial p) { 
  // copy one complete sensor frame of data, plus the prefix byte, into byteArray[]
  bytesRead = p.readBytes(byteArray);
  redraw();
} 

void draw() {
  chartRedraws++;
  if (chartRedraws >= 60) {
     chartRedraws = 0;
   // save a sensor data frame to a text file every 60 sensor frames
   //String[] stringArray = new String[SENSOR_PIXELS];
   //for(outerPtrX=0; outerPtrX < SENSOR_PIXELS; outerPtrX++) { 
   //   stringArray[outerPtrX] = str(output[outerPtrX]);
   //}
   //   saveStrings("Pixel_Values.txt", stringArray);
  }
  background(0);
  fill(255);
  
  // Counts 1 to 60 and repeats
  text(chartRedraws, 10, 50);

  // draw grid, legend, and kernel
  drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 8);
  drawLegend();
  drawKernel();
  
  // Plot the Data
  if (dataSource == 3){             // Plot using Serial Data //<>//
    DrawHeadFromSerialData();       // from 0 to SENSOR_PIXELS-1
    DrawTail();                     // from SENSOR_PIXELS to (SENSOR_PIXELS + KERNEL_LENGTH)-1
  }else
  {                                 // Plot using Simulated Data
    DrawHeadFromSimulatedData();    // from 0 to SENSOR_PIXELS-1
    DrawTail();                     // from SENSOR_PIXELS to (SENSOR_PIXELS + KERNEL_LENGTH)-1
  }
   calcAndDisplaySensorShadowPos(); // Subpixel calculation
   resetData();                     // reset the pointer, new random data if used.
}

void drawKernel(){
  
  // plot kernel data point
  strokeWeight(2);
  stroke(COLOR_KERNEL_DATA);
  
  for (outerPtrX = 0; outerPtrX < KERNEL_LENGTH; outerPtrX++) { 
    // shift outerPtrX left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
    drawPtrXLessK = (outerPtrX - HALF_KERNEL_LENGTH) * SCALE_X; 

    // draw new kernel point (y scaled up by kernelMultiplier for better visibility)
    point(drawPtrXLessK+HALF_SCREEN_WIDTH, 
    SCREEN_HEIGHT-kernelDrawYOffset-(kernel[outerPtrX] * kernelMultiplier));
   }
}

void DrawHeadFromSerialData(){
  
  // increment the outer loop pointer from 0 to SENSOR_PIXELS-1
  for (outerPtrX = 0; outerPtrX < SENSOR_PIXELS; outerPtrX++) {
    
    // receive serial port data into the input[] array
    
    // Read a pair of bytes from the byte array, convert them into an integer, 
    // shift right 2 places(divide by 4), and copy result into data_Array[]
    input[outerPtrX] = (byteArray[outerPtrX<<1]<< 8 | (byteArray[(outerPtrX<<1) + 1] & 0xFF))>>2;
    
    // Below we prepare 3 indexes to phase shift the x axis down (to the left as drawn), which corrects 
    // for convolution shift, and then multiply by the x scaling variable.
    
    // the outer pointer to the data arrays
    drawPtrX = outerPtrX * SCALE_X;
    
    // shift left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
    drawPtrXLessK = (outerPtrX - HALF_KERNEL_LENGTH) * SCALE_X; 
    
    // shift left by half the kernel length and,
    // shift left by half a data point increment for aligning all plots involving data of the 1st derivative 
    // (differences between data points are drawn in-between, or phase shifted to the left by 0.5 increments.
    // Note, this is a float to accomodate the fractional decimals. Processing accepts floats for screen coordinates,
    // but you don't see any difference compared to an integer until you spread the data points out from one
    // another on the screen in the X axis (the width related axis).
    drawPtrXLessKandD1 = (outerPtrX - HALF_KERNEL_LENGTH -0.5) * SCALE_X;
 
    // plot original data point
    strokeWeight(1);
    stroke(COLOR_ORIGINAL_DATA);
    
    point(drawPtrX, HALF_SCREEN_HEIGHT-(input[outerPtrX]*SCALE_Y));
    // draw section of greyscale bar showing the 'color' of original data values
    greyscaleBarMapped(drawPtrX, 0, input[outerPtrX]*SCALE_Y);
    
    // convolution inner loop
    for (int innerPtrX = 0; innerPtrX < KERNEL_LENGTH; innerPtrX++) { // increment the inner loop pointer
      // convolution (that magic line which can do so many different things depending on the kernel)
      output[outerPtrX+innerPtrX] = int(output[outerPtrX+innerPtrX] + input[outerPtrX] * kernel[innerPtrX]); 
    }

    // plot the output data
    stroke(COLOR_OUTPUT_DATA);
    point(drawPtrXLessK, HALF_SCREEN_HEIGHT-((output[outerPtrX]*SCALE_Y)));
    //println("output[" + outerPtrX + "]" +output[outerPtrX]);
   
    // draw section of greyscale bar showing the 'color' of output data values
    greyscaleBarMapped(drawPtrXLessK, 11, output[outerPtrX]*SCALE_Y);
  
    // find 1st derivative of the convolved data, the difference between adjacent points in the input[] array
    if (outerPtrX > 0){
      stroke(COLOR_DERIVATIVE1_OF_OUTPUT);
      output2[outerPtrX] = output[outerPtrX] - output[outerPtrX-1];
      point(drawPtrXLessKandD1, HALF_SCREEN_HEIGHT-(output2[outerPtrX]*SCALE_Y));
      // draw section of greyscale bar showing the 'color' of output2 data values
      greyscaleBarMappedAbs(drawPtrXLessKandD1, 22, output2[outerPtrX]*SCALE_Y);
    }
  }
}

void DrawHeadFromSimulatedData(){
  
  // increment the outer loop pointer from 0 to SENSOR_PIXELS-1
  for (outerPtrX = 0; outerPtrX < SENSOR_PIXELS; outerPtrX++) {
    
    // Below we prepare 3 indexes to phase shift the x axis down (to the left as drawn), which corrects 
    // for convolution shift, and then multiply by the x scaling variable.
    
    // the outer pointer to the data arrays
    drawPtrX = outerPtrX * SCALE_X;
    
    // shift left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
    drawPtrXLessK = (outerPtrX - HALF_KERNEL_LENGTH) * SCALE_X; 
    
    // shift left by half the kernel length and,
    // shift left by half a data point increment for aligning all plots involving data of the 1st derivative 
    // (differences between data points are drawn in-between, or phase shifted to the left by 0.5 increments.
    // Note, this is a float to accomodate the fractional decimals. Processing accepts floats for screen coordinates,
    // but you don't see any difference compared to an integer until you spread the data points out from one
    // another on the screen in the X axis (the width related axis).
    drawPtrXLessKandD1 = (outerPtrX - HALF_KERNEL_LENGTH -0.5) * SCALE_X;
 
    // plot original data point
    strokeWeight(1);
    stroke(COLOR_ORIGINAL_DATA);
    
    point(drawPtrX, HALF_SCREEN_HEIGHT-(input[outerPtrX]*SCALE_Y));
    // draw section of greyscale bar showing the 'color' of original data values
    greyscaleBarMapped(drawPtrX, 0, input[outerPtrX]*SCALE_Y);
    
    // convolution inner loop
    for (int innerPtrX = 0; innerPtrX < KERNEL_LENGTH; innerPtrX++) { // increment the inner loop pointer
      // convolution (that magic line which can do so many different things depending on the kernel)
      output[outerPtrX+innerPtrX] = int(output[outerPtrX+innerPtrX] + input[outerPtrX] * kernel[innerPtrX]); 
    }

    // plot the output data
    stroke(COLOR_OUTPUT_DATA);
    point(drawPtrXLessK, HALF_SCREEN_HEIGHT-((output[outerPtrX]*SCALE_Y)));
    //println("output[" + outerPtrX + "]" +output[outerPtrX]);
   
    // draw section of greyscale bar showing the 'color' of output data values
    greyscaleBarMapped(drawPtrXLessK, 11, output[outerPtrX]*SCALE_Y);
  
    // find 1st derivative of the convolved data, the difference between adjacent points in the input[] array
    if (outerPtrX > 0){
      stroke(COLOR_DERIVATIVE1_OF_OUTPUT);
      output2[outerPtrX] = output[outerPtrX] - output[outerPtrX-1];
      point(drawPtrXLessKandD1, HALF_SCREEN_HEIGHT-(output2[outerPtrX]*SCALE_Y));
      // draw section of greyscale bar showing the 'color' of output2 data values
      greyscaleBarMappedAbs(drawPtrXLessKandD1, 22, output2[outerPtrX]*SCALE_Y);
    }
  }
}

void DrawTail(){
  
  // increment the outer loop pointer from SENSOR_PIXELS to (SENSOR_PIXELS + KERNEL_LENGTH)-1
  for (outerPtrX = SENSOR_PIXELS; outerPtrX < OUTPUT_DATA_LENGTH; outerPtrX++) { 
    // println("output[" + outerPtrX + "]" +output[outerPtrX]);
    
    // plot the output data
    stroke(COLOR_OUTPUT_DATA);
    point(drawPtrXLessK, HALF_SCREEN_HEIGHT-((output[outerPtrX]*SCALE_Y)));
    
   
    // draw section of greyscale bar showing the 'color' of output data values
    greyscaleBarMapped(drawPtrXLessK, 11, output[outerPtrX]*SCALE_Y);
  
    // find 1st derivative of the convolved data, the difference between adjacent points in the input[] array
    stroke(COLOR_DERIVATIVE1_OF_OUTPUT);
    output2[outerPtrX] = output[outerPtrX] - output[outerPtrX-1];
    point(drawPtrXLessKandD1, HALF_SCREEN_HEIGHT-(output2[outerPtrX]*SCALE_Y));
    // draw section of greyscale bar showing the 'color' of output2 data values
    greyscaleBarMappedAbs(drawPtrXLessKandD1, 22, output2[outerPtrX]*SCALE_Y);
  }
}

void greyscaleBarMapped(float x, float y, float value) {
  // prepare color to correspond to sensor pixel reading
  int bColor = int(map(value, 0, SCREEN_HEIGHT, 0, 255));

  // Plot a row of pixels near the top of the screen ,
  // and color them with the 0 to 255 greyscale sensor value
  
  noStroke();
  fill(bColor, bColor, bColor);
  rect(x, y, SCALE_X, 10);
}

void greyscaleBarMappedAbs(float x, float y, float value) {
  // prepare color to correspond to sensor pixel reading
  int bColor = int(abs(map(value, 0, SCREEN_HEIGHT, 0, 255)));
  // Plot a row of pixels near the top of the screen ,
  // and color them with the 0 to 255 greyscale sensor value
  
  noStroke();
  fill(bColor, bColor, bColor);
  rect(x, y, SCALE_X, 10);
}
 //<>//

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
    //println("gaussian kernel[" + i + "] = " + kernel[i]);
  }
  
  if (sum!=0.0){
    scale = 1.0/sum;
  } else {
    scale = 1;
  }
  
  //println("gaussian kernel scale = " + scale); // print the scale.
  sum = 0; // clear the previous sum
  // scale the kernel values
  for (int i=0; i<kernel.length; i++){
    kernel[i] = kernel[i] * scale;
    fkernel[i] = (float) kernel[i];
    sum += kernel[i];
    // print the kernel value.
   // println("scaled gaussian kernel[" + i + "]:" + fkernel[i]); 
  }
  
  if (sum!=0.0){
    scale = 1.0/sum;
  } else {
    scale = 1;
  }
  
  // print the new scale. Should be very close to 1.
  //println("gaussian kernel new scale = " + scale); 
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
     // println("LoG kernel[" + x + "] = " + fkernel[x]);
  }
  return fkernel;
}

public void zeroOutputData(){
  for (int c = 0; c < OUTPUT_DATA_LENGTH; c++) {
    output[c] = 0;
   }
}

public void resetData(){
  outerPtrX = 0;
  
  // uncomment setInputRandomData below, to make some new random noise for each draw loop
  
   //setInputRandomData(); 
  
  zeroOutputData();
  
  if(noiseInput > 100){
    noiseInput = noiseIncrement;
  }
}

void setInputRandomData(){
  
  for (int c = 0; c < SENSOR_PIXELS; c++) {
    // adjust smoothness with noise input
    noiseInput = noiseInput + noiseIncrement;  
    // perlin noise
    input[c] = int(map(noise(noiseInput), 0, 1, 0, HIGHEST_ADC_VALUE * SCALE_Y));  
    //println (noise(noiseInput));
   }
   
}

int[] setHardCodedSensorData(){

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
  data[27] = 513; //<>//
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
  
  return data;
}

int[] setInputSingleImpulse(int dataLength, int pulseHeight, int pulseWidth, int offset, boolean positivePolarity){
  
  if (pulseWidth < 2) {
    pulseWidth = 2;
  }
 
  int center = (dataLength/2)+offset;
  
  int halfPositives = pulseWidth /2;
  int startPos = center - halfPositives;
  int stopPos = center + halfPositives;
  
  int[] data = new int[dataLength];
  
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

void calcAndDisplaySensorShadowPos()

{
  int NegStep, PosStep;                    // peak values, y axis (height centric)
  int NegStepLoc, PosStepLoc;              // array index of peak locations, x axis (width centric)
  int SubPixelStartPos = 12;               // loop array traversal start point, set a little beyond first few pixels,
                                           // to avoid false positive from d1 peak at beginning
  int SubPixelEndPos = SENSOR_PIXELS;      // loop end point
  
  float a1, b1, c1, a2, b2, c2;           // sub pixel quadratic interpolation input variables, 3 per D1 peak, one negative, one positive
  float m1, m2;                           // sub pixel quadratic interpolation output variables, 1 per D1 peak, one negative, one positive
  float widthSubPixel = 0;                // filament width is still here if you need it
  float filPrecisePos = 0;                // final output before conversion to mm
  float filPreciseMMPos = 0;              // final mm output
  
  float filWidth = 0;
  float XCoord = 0;
  float YCoord = 0;
  
  NegStep = 0;
  PosStep = 0;
  NegStepLoc = 1280; // one past the last pixel, to prevent false positives
  PosStepLoc = 1280; // one past the last pixel, to prevent false positives
   
  //clear the sub-pixel buffers
  a1 = b1 = c1 = a2 = b2 = c2 = 0;
  m1 = m2 = 0;
 // we should have already ran a gaussian smoothing routine over the data, and 
 // also already saved the 1st derivative of the smoothed data into an array.
 // Therefore, all we do here is find the peaks on the 1st derivative data.
 
 // find the the tallest negative peak in 1st derivative data, 
 // which is the point of steepest negative slope in the smoothed original data)
 for (int i = SubPixelStartPos; i < SubPixelEndPos - 1; i++) {
    if (output2[i] < NegStep) {
      NegStep = output2[i];
      NegStepLoc = i;
    }
  }
 
 // find the the tallest positive peak in 1st derivative data, 
 // which is the point of steepest positive slope in the smoothed original data)
 for (int i = SubPixelStartPos; i < SubPixelEndPos - 1; i++) {
    if (output2[i] > PosStep) {
      PosStep = output2[i];
      PosStepLoc = i;
    }
  }

  // store the 1st derivative values to simple variables
  c1=output2[NegStepLoc+1];  // tallest negative peak array index location plus 1
  b1=output2[NegStepLoc];    // tallest negative peak array index location
  a1=output2[NegStepLoc-1];  // tallest negative peak array index location minus 1
  
  c2=output2[PosStepLoc+1];  // tallest positive peak array index location plus 1
  b2=output2[PosStepLoc];    // tallest positive peak array index location
  a2=output2[PosStepLoc-1];  // tallest positive peak array index location minus 1
    
  if (NegStep<-16 && PosStep>16)  // check for significant threshold
  {
    filWidth=PosStepLoc-NegStepLoc;
  } else 
  {
    filWidth=0;
  }
  
  // check for width out of range (15.7pixels per mm, 65535/635=103)
  if(filWidth > 8 && filWidth < 103)
  {
    
    // sub-pixel edge detection using interpolation
    // from Accelerated Image Processing blog, posting: Sub-Pixel Maximum
    // https://visionexperts.blogspot.com/2009/03/sub-pixel-maximum.html
    m1 = 0.5 * (a1 - c1) / (a1 - 2 * b1 + c1);
    m2 = 0.5 * (a2 - c2) / (a2 - 2 * b2 + c2);
    
    // m1=((a1-c1) / (a1+c1-(b1*2)))/2;
    // m2=((a2-c2) / (a2+c2-(b2*2)))/2;
    
    //check for a measurement > cutoff value  otherwise treat as noise and output a 0
  
    widthSubPixel = filWidth + m2 - m1; 
    // widthSubPixelLP = widthSubPixelLP * 0.9 + widthSubPixel * 0.1;
  
    filPrecisePos = (((NegStepLoc + m1) + (PosStepLoc + m2)) / 2);
    filPreciseMMPos = filPrecisePos * sensorPixelSpacing;
    
    // Mark m1 with red line
    noFill();
    strokeWeight(1);
    stroke(255, 0, 0);
    XCoord = (NegStepLoc + m1 - 0.5 - HALF_KERNEL_LENGTH) * SCALE_X;
    YCoord = HALF_SCREEN_HEIGHT;
    line(XCoord, 100, XCoord, YCoord);
      
    // Mark m2 with green line
    stroke(0, 255, 0);
    XCoord = (PosStepLoc + m2 -0.5 - HALF_KERNEL_LENGTH) * SCALE_X;
    YCoord = HALF_SCREEN_HEIGHT;
    line(XCoord, YCoord, XCoord, 100);
      
    // Mark subpixel center with white line
    stroke(255);
    XCoord = (filPrecisePos - 0.5 - HALF_KERNEL_LENGTH) * SCALE_X;
    YCoord = HALF_SCREEN_HEIGHT;
    line(XCoord, 100, XCoord, YCoord); 
      
    // Mark minsteploc 3 pixel cluster with one red circle each
    stroke(255, 0, 0);
    ellipse(((NegStepLoc - 1.5) - HALF_KERNEL_LENGTH)  * SCALE_X, HALF_SCREEN_HEIGHT - (a1 * SCALE_Y), markSize, markSize);
    ellipse((NegStepLoc - 0.5 - HALF_KERNEL_LENGTH) * SCALE_X, HALF_SCREEN_HEIGHT - (b1 * SCALE_Y), markSize, markSize);
    ellipse(((NegStepLoc + 0.5) - HALF_KERNEL_LENGTH) * SCALE_X, HALF_SCREEN_HEIGHT - (c1 * SCALE_Y), markSize, markSize);
   
    // Mark maxsteploc 3 pixel cluster with one green circle each
    stroke(0, 255, 0);
    ellipse(((PosStepLoc - 1.5) - HALF_KERNEL_LENGTH) * SCALE_X, HALF_SCREEN_HEIGHT - (a2 * SCALE_Y), markSize, markSize);
    ellipse((PosStepLoc - 0.5 - HALF_KERNEL_LENGTH) * SCALE_X, HALF_SCREEN_HEIGHT - (b2 * SCALE_Y), markSize, markSize);
    ellipse(((PosStepLoc + 0.5) - HALF_KERNEL_LENGTH) * SCALE_X, HALF_SCREEN_HEIGHT - (c2 * SCALE_Y), markSize, markSize);
    
    YCoord = SCREEN_HEIGHT-10;
    fill(255);
    text("NegStepLoc = " + NegStepLoc, 0, YCoord);
    text("PosStepLoc = " + PosStepLoc, 100, YCoord);
    text("m1 = " + String.format("%.3f", m1), 200, YCoord);
    text("m2 = " + String.format("%.3f", m2), 275, YCoord);
    text("widthSubPixel = " + String.format("%.3f", widthSubPixel), 375, YCoord);
    text("filPrecisePos = " + String.format("%.3f", filPrecisePos), 650, YCoord);
    text("filPreciseMMPos =  " + String.format("%.4f", filPreciseMMPos), 800, YCoord);
  } //<>//
} //<>//

void drawLegend() {
  int rectX, rectY, rectWidth, rectHeight;
  
  rectX = 10;
  rectY = 65;
  rectWidth = 10;
  rectHeight = 10;
 
  // draw a legend showing what each color represents
  strokeWeight(1);
  
  stroke(COLOR_ORIGINAL_DATA);
  fill(COLOR_ORIGINAL_DATA);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("Original input data", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_KERNEL_DATA);
  fill(COLOR_KERNEL_DATA);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("Convolution kernel", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_OUTPUT_DATA);
  fill(COLOR_OUTPUT_DATA);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("Convolution output data, shifted back into original phase", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_DERIVATIVE1_OF_OUTPUT);
  fill(COLOR_DERIVATIVE1_OF_OUTPUT);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("1st derivative of convolution output data", rectX+20, rectY+10);
  
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