/*
Interpolation_Demos_2.pde, a simple Processing sketch demo of a few low-order 
interpolation functions.
Created by Douglas Mayhew, November 12, 2016.
Released into the public domain.
See: https://github.com/Mr-Mayhem/Processing-Snippets

Interpolation functions were translated into java by Douglas Mayhew, 
For original interpolation functions source code and explanation, see: 
http://paulbourke.net/miscellaneous/interpolation/

Interpolation is the addition of new data points in-between existing data points.
There is a trade-off between smoothness/accuracy, versus computational intensity.
Interpolation is often used in signal and image processing to improve data smoothness.

To see one flavor of plot only, simply comment out the interpolation plots you don't want to see.
number of simulated(pen noise) original data points is set by SENSOR_PIXELS
number of added points is set by NUM_INTERP_POINTS
screen width is determined by SCREEN_X_MULTIPLIER

Linear and cosine interpolation need 2 original data points.
CubicInterpolate and BreeuwsmaCubicInterpolate need 4 original data points.

If the interpolated points are of phase, the outerPtr index can be changed by 1 or 2 in the
array argument, like "outArray[outerPtr -1]" 
Also you may need to adjust the upper/lower limits for the outerPtr.
 
An older version, Interpolation_Demos.pde is also available.
 
This V2 is improved in the sense that inputs to the interpolation function are indexed
backwards in time, useful when running this on live sensor data, because then
you don't have the luxury of examining any data more recent than what just arrived.
That version is also a bit better thought out.
 
*/

int SCREEN_HEIGHT = 800;
int SENSOR_PIXELS =  8;           // number of discrete values in the input array
int SCREEN_X_MULTIPLIER = 128;    // ratio of interpolated points to original points. influences screen width
int SCREEN_WIDTH = SENSOR_PIXELS*SCREEN_X_MULTIPLIER; // screen width = total pixels * SCREEN_X_MULTIPLIER

color COLOR_ORIGINAL_DATA = color(0, 255, 255);
color COLOR_LINEAR_INTERP = color(255, 255, 0);
color COLOR_COSINE_INTERP = color(0, 255, 0);
color COLOR_BCOSINE_INTERP = color(0, 255, 255);

// number of inserted data points for each original data point (but we insert one less when we use it)
int NUM_INTERP_POINTS = 9; // Num of points that will be added per original data point.

int RAW_DATA_SPACING = NUM_INTERP_POINTS + 1;  //spacing of original data in the array

int INTERP_OUT_LENGTH = (SENSOR_PIXELS * RAW_DATA_SPACING) - NUM_INTERP_POINTS; //number of discrete values in the output array

int outerPtr = 0;          // outer loop pointer 0
int Raw_Data_Ptr_A = 0;    //indexes for original data, feeds interpolation function inputs
int Raw_Data_Ptr_B = 0;
int Raw_Data_Ptr_C = 0;    // use for linear or cosine, also edit 'outerPtr-2' in inner loop to 'outerPtr'
int Raw_Data_Ptr_D = 0;    // use for linear or cosine, also edit 'outerPtr-2' in inner loop to 'outerPtr'

float noiseindex = 0.25;   // used for generating smooth noise for data

//  a decimal fraction between 0 and 1, representing smaller increment of x position 
// relative to original data points. 
float muIncrement = 1/float(RAW_DATA_SPACING);
float muValue = 0;         // 0 to 1 valid. 0 at start location, 1 at stop location.

int[] inArray = new int[INTERP_OUT_LENGTH];       // array for input signal
void setup() {
  surface.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
  strokeWeight(2);
  frameRate(10);
  background(0);
  resetData();
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
  stroke(COLOR_LINEAR_INTERP);
  fill(COLOR_LINEAR_INTERP);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("Linear Interpolation", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_COSINE_INTERP);
  fill(COLOR_COSINE_INTERP);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("Cosine Interpolation", rectX+20, rectY+10);
  
  rectY+=20;
  stroke(COLOR_BCOSINE_INTERP);
  fill(COLOR_BCOSINE_INTERP);
  rect(rectX, rectY, rectWidth, rectHeight);
  fill(255);
  text("Breeuwsma's Catmull-Rom Interpolation", rectX+20, rectY+10);
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

// fill input array with smooth random noise, higher noiseindex changes = more variation
public void newInputData() {

  for (int outerIndex = 0; outerIndex < SENSOR_PIXELS; outerIndex++) {
    int outerIndexMulti = outerIndex * RAW_DATA_SPACING; //<>//
    // create one point of perlin noise
    noiseindex = noiseindex + 0.25; // drives the perlin noise generator
    // perlin noise generator (makes smoothed noise for simulated data)
    inArray[outerIndexMulti] = int(map(noise(noiseindex), 0, 1, 0, height));  
   }

   //for (int c = 0; c < INTERP_OUT_LENGTH; c++) {
   //  println("original data inArray[" + c + "] = " + inArray[c]);
   //}
   //println(""); 
}

public void resetData(){
  newInputData(); // make some new ransom noise
  //zeroOutputData(); // set to all zeros
  muValue = 0;
  outerPtr = 0;

  if(noiseindex > 100){
    noiseindex = 0.25; // noise generator variable reset to beginning
  }
}

float LinearInterpolate(float y1, float y2, float mu)
{
   return(y1*(1-mu)+y2*mu);
}

public float CosineInterpolate(float y1, float y2, float mu) {
   float mu2;

   mu2 = (1-cos(mu*PI))/2;
   return(y1*(1-mu2)+y2*mu2);
}

float CubicInterpolate(float y0,float y1, float y2,float y3, float mu)
{
   float a0,a1,a2,a3,mu2;

   mu2 = mu*mu;
   a0 = y3 - y2 - y0 + y1;
   a1 = y0 - y1 - a0;
   a2 = y2 - y0;
   a3 = y1;

   return(a0*mu*mu2+a1*mu2+a2*mu+a3);
}

float Breeuwsma_Catmull_Rom_Interpolate(float y0,float y1, float y2,float y3, float mu)
{
  
  // Originally from Paul Breeuwsma http://www.paulinternet.nl/?page=bicubic
  // "We could simply use derivative 0 at every point, but we obtain 
  // smoother curves when we use the slope of a line between the 
  // previous and the next point as the derivative at a point. In that 
  // case the resulting polynomial is called a Catmull-Rom spline."
  // Copied from version at http://paulbourke.net/miscellaneous/interpolation/

   float a0,a1,a2,a3,mu2;
   mu2 = mu*mu;
   a0 = -0.5*y0 + 1.5*y1 - 1.5*y2 + 0.5*y3;
   a1 = y0 - 2.5*y1 + 2*y2 - 0.5*y3;
   a2 = -0.5*y0 + 0.5*y2;
   a3 = y1;

   return(a0*mu*mu2+a1*mu2+a2*mu+a3);
}

void draw() {
  if (outerPtr >= SENSOR_PIXELS) { // we hit the upper limit
    //for (int c = 0; c < INTERP_OUT_LENGTH; c++) {
    //  println("Final inArray[" + c + "] = " + inArray[c]);
    //}
    delay(3000);
    resetData();
    background(0);
  } else 
  {
    if (outerPtr ==0) {
      // draw the x and y aixs
      drawGrid(SCREEN_WIDTH, height, 8);
      drawLegend();
    }
    
    Raw_Data_Ptr_A = (outerPtr - 3) * RAW_DATA_SPACING;
    Raw_Data_Ptr_B = (outerPtr - 2) * RAW_DATA_SPACING;   
    Raw_Data_Ptr_C = (outerPtr - 1) * RAW_DATA_SPACING;
    Raw_Data_Ptr_D = outerPtr * RAW_DATA_SPACING;
  
    //println("outerPtr: " + outerPtr + " Raw_Data_Ptr_A: " + Raw_Data_Ptr_A + " Raw_Data_Ptr_B: " + Raw_Data_Ptr_B + " Raw_Data_Ptr_C: " + Raw_Data_Ptr_C + " Raw_Data_Ptr_D: " + Raw_Data_Ptr_D);
   
    noFill();
    // plot an original data point (from the noise source)
    strokeWeight(1);
    stroke(COLOR_ORIGINAL_DATA);
    ellipse(outerPtr*SCREEN_X_MULTIPLIER, height-inArray[Raw_Data_Ptr_D], 5, 5);
    //text((outerPtr*SCREEN_X_MULTIPLIER) + ", " + inArray[Raw_Data_Ptr_B], outerPtr*SCREEN_X_MULTIPLIER, height-inArray[Raw_Data_Ptr_B]);
    
    if (Raw_Data_Ptr_A > -1) {
      muValue=0;
      for (int innerPtr = 1; innerPtr < RAW_DATA_SPACING; innerPtr++) {
        muValue = muIncrement * innerPtr; // increment mu
        int interpPtr = Raw_Data_Ptr_A + innerPtr;
        //println("innerPtr: " + innerPtr + " interpPtr: " + interpPtr + " muValue: " + muValue);
        inArray[interpPtr] = int(Breeuwsma_Catmull_Rom_Interpolate(inArray[Raw_Data_Ptr_A], inArray[Raw_Data_Ptr_B], inArray[Raw_Data_Ptr_C], inArray[Raw_Data_Ptr_D], muValue));
        //println("inArray[" + interpPtr + "] = " + inArray[interpPtr]);
        //outArray2[combinedIndex] = CubicInterpolate(inArray[ outerPtr-1], inArray[outerPtr], inArray[ outerPtr+1], inArray[outerPtr+2], muValue);
        //outArray3[combinedIndex] = Breeuwsma_Catmull_Rom_Interpolate(inArray[ outerPtr-1], inArray[outerPtr], inArray[ outerPtr+1], inArray[outerPtr+2], muValue);
        
        // scale the offset for the screen
        int scaledOffset = int(map(innerPtr, 0, RAW_DATA_SPACING, 0, SCREEN_X_MULTIPLIER)); 
        
        //strokeWeight(2);
        
        // plot an interpolated point using the scaled x offset
        stroke(COLOR_LINEAR_INTERP);
        point(((outerPtr-2)*SCREEN_X_MULTIPLIER)+scaledOffset, height-inArray[interpPtr]);
        // text(((outerPtr*SCREEN_X_MULTIPLIER)+scaledOffset) + ", " + inArray[interpPtr], (outerPtr*SCREEN_X_MULTIPLIER)+scaledOffset, height-inArray[interpPtr]);
        //// plot an interpolated point using the scaled x offset
        //stroke(COLOR_COSINE_INTERP); // cubic is green
        //point((outerPtr*SCREEN_X_MULTIPLIER)+scaledOffset, SCREEN_HEIGHT-outArray2[combinedIndex]);
        
        //// plot an interpolated point using the scaled x offset
        //stroke(COLOR_BCOSINE_INTERP); //BreeuwsmaCubic is blue
        //point((outerPtr*SCREEN_X_MULTIPLIER)+scaledOffset, SCREEN_HEIGHT-outArray3[combinedIndex]);
        }
    }
    outerPtr++;  // increment the outer loop pointer
  }
}