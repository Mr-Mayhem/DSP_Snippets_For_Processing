
// Interpolation_Demos, a simple demos of a few low order interpolation techniques.
// code translated into java, original source is 
// http://paulbourke.net/miscellaneous/interpolation/

// Interpolation is the addition of new data points in-between existing data points.
// There is a trade-off between smoothness/accuracy, versus computational intensity.
// often used in signal and image processing to improve resolution somewhat beyond that 
// of the original capture device.

// BreeuwsmaCubicInterpolate() is default method. 
// Try the other interpolation functions by swapping them out. 
// The first two, linear and cosine interpolation need 2 original data points
// the last two,  CubicInterpolate and BreeuwsmaCubicInterpolate need 4 original data 
// points, and indexes need to be adjused accordingly

// if input and output display out of phase, the outerPtr index can be changed by 1 or 2 in the
// array argument, like "outArray[outerPtr -1]" and adjust the upper/lower limits for the outerPtr.

int windowHeight = 800;
int inputDataLength = 64; //number of discrete values in the input array
int interpPtsPerDataPt = 16;   // Number of new interpolated points for each data point, influences screen width
int outputDataLength = inputDataLength * interpPtsPerDataPt; //number of discrete values in the output array
int outerPtr = 2;          // outer loop pointer

float noiseindex = 0.2;           // used for generating smooth noise for data
float flinterpPtsPerDataPt = float(interpPtsPerDataPt);   // convert interpPtsPerDataPt to float
float muIncrement = 1/flinterpPtsPerDataPt;    // 1 divided by flinterpPtsPerDataPt = one step of change x from 0 to 1
float muValue = 0;         // 0 to 1 valid. 0 at start location, 1 at stop location.

float[] inArray = new float[inputDataLength];   // array for input signal
float[] outArray = new float[outputDataLength]; // array for output signal


void setup() {
  surface.setSize(outputDataLength, windowHeight);
  resetData();
  strokeWeight(1);
  frameRate(10);
  noFill();
  background(0);
}

// fill input array with smooth random noise, higher noiseindex changes = more variation
public void newInputData(){
  for (int c = 0; c < inputDataLength; c++) {
    noiseindex = noiseindex + 0.2;
    
    inArray[c] = map(noise(noiseindex), 0, 1, 0, windowHeight); 
    //numbers[c] = floor(random(height));
   }
}

public void zeroOutputData(){
  for (int c = 0; c < outputDataLength; c++) {
    outArray[c] = 0;
   }
}

public void resetData(){
  newInputData(); // make some new ransom noise
  zeroOutputData(); // set to all zeros
  muValue = 0;
  background(0);
  
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

float BreeuwsmaCubicInterpolate(float y0,float y1, float y2,float y3, float mu)
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
  if (oddframe) {
    // plot an original data point (from the noise source)
    stroke(0, 255, 255);
    fill(255);
    ellipse((outerPtr)*interpPtsPerDataPt, windowHeight-inArray[outerPtr], 5, 5);
    outerPtr++;  // increment the outer loop pointer
    if (outerPtr > inputDataLength-2) {
      oddframe = false;
      //delay(1000);
      outerPtr = 2;
    }
  } else {
    // plot an output data point
    stroke(255);
    muValue=0;
    for (int innerPtr = 0; innerPtr < interpPtsPerDataPt; innerPtr++) { // for each new added point -1
      int combinedIndex = ((outerPtr-1)*interpPtsPerDataPt) + innerPtr;
      outArray[combinedIndex] = BreeuwsmaCubicInterpolate(inArray[outerPtr-2], inArray[outerPtr-1], inArray[outerPtr], inArray[outerPtr+1], muValue);
      point(combinedIndex, windowHeight-outArray[combinedIndex]);
      muValue+=muIncrement;
    }
    outerPtr++;  // increment the outer loop pointer
    if (outerPtr > inputDataLength-2) {
      oddframe = true;
      //delay(1000);
      outerPtr = 2;
      resetData();
    }
  }
}