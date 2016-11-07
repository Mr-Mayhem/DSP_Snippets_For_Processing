
// Interpolation_Demos, a simple demo of a few low order interpolation functions.
// code translated into java, original source is 
// http://paulbourke.net/miscellaneous/interpolation/

// Interpolation is the addition of new data points in-between existing data points.
// There is a trade-off between smoothness/accuracy, versus computational intensity.
// Interpolation is often used in signal and image processing to improve data smoothness.

// To see one flavor of plot only, simply comment out the interpolation plots you don't want to see.
// number of added points is set by INTERPOLATION_X_MULTIPLIER
// screen width is determined by SCREEN_X_MULTIPLIER

// Linear and cosine interpolation need 2 original data points.
// CubicInterpolate and BreeuwsmaCubicInterpolate need 4 original data points.

// if input and output display out of phase, the outerPtr index can be changed by 1 or 2 in the
// array argument, like "outArray[outerPtr -1]" and adjust the upper/lower limits for the outerPtr.

int WINDOW_HEIGHT = 800;
int SENSOR_PIXELS = 64;  // number of discrete values in the input array
int SCREEN_X_MULTIPLIER = 32;   // ratio of interpolated points to original points. influences screen width
int SCREEN_WIDTH = SENSOR_PIXELS*SCREEN_X_MULTIPLIER; // screen width = total pixels * SCREEN_X_MULTIPLIER

color COLOR_ORIGINAL_DATA = color(0, 255, 255);
color COLOR_LINEAR_INTERP = color(255, 0, 0);
color COLOR_COSINE_INTERP = color(0, 255, 0);
color COLOR_BCOSINE_INTERP = color(0, 0, 255);

// number of inserted data points for each original data point (but we insert one less when we use it)
int INTERPOLATION_X_MULTIPLIER = 32; // Num of points that will be added - 1.

int INTERP_OUT_LENGTH = (SENSOR_PIXELS * INTERPOLATION_X_MULTIPLIER); //number of discrete values in the output array

int outerPtr = 1;          // outer loop pointer 0
float noiseindex = 0.2;    // used for generating smooth noise for data
float muValue = 0;         // 0 to 1 valid. 0 at start location, 1 at stop location.

float[] inArray = new float[SENSOR_PIXELS];       // array for input signal
float[] outArray1 = new float[INTERP_OUT_LENGTH]; // array for linearly interpolated output signal
float[] outArray2 = new float[INTERP_OUT_LENGTH]; // array for cubically interpolated output signal
float[] outArray3 = new float[INTERP_OUT_LENGTH]; // array for Breeuwsma cubically interpolated output signal

void setup() {
  surface.setSize(SCREEN_WIDTH, WINDOW_HEIGHT);
  strokeWeight(2);
  frameRate(10);
  resetData();
}

void DrawLegend() {
  int rectX, rectY, rectWidth, rectHeight;
  
  rectX = 20;
  rectY = 20;
  rectWidth = 10;
  rectHeight = 10;
  
  background(0);
  
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



// fill input array with smooth random noise, higher noiseindex changes = more variation
public void newInputData(){
  for (int c = 0; c < SENSOR_PIXELS; c++) {
    noiseindex = noiseindex + 0.2;
    
    inArray[c] = map(noise(noiseindex), 0, 1, 0, WINDOW_HEIGHT); 
    //numbers[c] = floor(random(height));
   }
}

public void zeroOutputData(){
  for (int c = 0; c < INTERP_OUT_LENGTH; c++) {
    outArray1[c] = 0;
    outArray2[c] = 0;
    outArray3[c] = 0;
   }
}

public void resetData(){
  newInputData(); // make some new ransom noise
  zeroOutputData(); // set to all zeros
  muValue = 0;
 
  if(noiseindex > 100){
    noiseindex = 0.2; // noise generator variable reset to beginning
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

boolean oddframe = true;

 void draw() {
  if (outerPtr ==1) {
    DrawLegend();
  }
  noFill();
  if (oddframe) {
    // plot an original data point (from the noise source)
    stroke(COLOR_ORIGINAL_DATA);
    ellipse(outerPtr*SCREEN_X_MULTIPLIER, WINDOW_HEIGHT-inArray[outerPtr], 5, 5);
    outerPtr++;        // increment the outer loop pointers
    if (outerPtr > SENSOR_PIXELS-3) { // we hit the upper limit
      outerPtr = 1;
      oddframe = false;  // toggle between drawing original data points, and drawing interpolated data points
      //delay(1000);
    }
  } else {
    // plot interpolated points between original points
    
    // The X axis offset starts at a left original data point (where mu = 0), 
    // and ends at a right original data point (where mu would equal 1), 
    // but we stop one step short. 
    // for example, when SCREEN_X_MULTIPLIER = 10 then mu increments in 0.1 size steps.
    // mu is passed into interpolate, and represents the x axis position of the new point to be.
    
    //  a decimal fraction between 0 and 1, representing smaller increment of x position relative to original data points. 
    float muIncrement = 1/float(INTERPOLATION_X_MULTIPLIER);
    muValue=0;
    for (int offset = 0; offset < INTERPOLATION_X_MULTIPLIER; offset++) { // for each new interpolated point, minus one)
      
      muValue+=muIncrement; // increment mu
      
      int combinedIndex = (outerPtr*INTERPOLATION_X_MULTIPLIER) + offset; // the original point, times the spreading, plus the offset
      
      outArray1[combinedIndex] = LinearInterpolate(inArray[ outerPtr], inArray[outerPtr+1], muValue);
      outArray2[combinedIndex] = CubicInterpolate(inArray[ outerPtr-1], inArray[outerPtr], inArray[ outerPtr+1], inArray[outerPtr+2], muValue);
      outArray3[combinedIndex] = Breeuwsma_Catmull_Rom_Interpolate(inArray[ outerPtr-1], inArray[outerPtr], inArray[ outerPtr+1], inArray[outerPtr+2], muValue);
      
      // scale the offset for the screen
      int scaledOffset = round(map(offset, 0, INTERPOLATION_X_MULTIPLIER-1, 0, SCREEN_X_MULTIPLIER-1)); 

      // plot an interpolated point using the scaled x offset
      stroke(COLOR_LINEAR_INTERP); // linear is red
      point((outerPtr*SCREEN_X_MULTIPLIER)+scaledOffset, WINDOW_HEIGHT-outArray1[combinedIndex]);
      
      // plot an interpolated point using the scaled x offset
      stroke(COLOR_COSINE_INTERP); // cubic is green
      point((outerPtr*SCREEN_X_MULTIPLIER)+scaledOffset, WINDOW_HEIGHT-outArray2[combinedIndex]);
      
      // plot an interpolated point using the scaled x offset
      stroke(COLOR_BCOSINE_INTERP); //BreeuwsmaCubic is blue
      point((outerPtr*SCREEN_X_MULTIPLIER)+scaledOffset, WINDOW_HEIGHT-outArray3[combinedIndex]);
      
      
    }
    outerPtr++;        // increment the outer loop pointers
    if (outerPtr > SENSOR_PIXELS-3) { // we hit the upper limit
      outerPtr = 1;
      oddframe = true; // toggle between drawing original data points, and drawing interpolated data points
      resetData(); // we did both the original data and the interpolation cycles, so reset and start over
      DrawLegend();
      delay(5000);
    }
  }
}