# DSP_Snippets_For_Processing
A growing pile of short Processing (Java) sketches related to visualizing steps involved in edge detection with sub-pixel resolution. I am simply chasing the main ingredients to do edge detection as I learn about them, and I will combine the whole process in a final Processing sketch, and an Arduino sketch, for use with linear array photo sensors. 

"Convolution_Demos.pde" demonstrates 1d convolution of existing data with a shorter impulse, or "kernel"
Kinda basic, but I will be improving it. 
Code translated into java from http://www.dspguide.com/ch6/3.htm

Also, see https://en.wikipedia.org/wiki/Convolution

"Derivatives_of_Gaussian_Bell_Curve.pde" generates and plots the first 5 derivatives of a gaussian.

"Interpolation_Demos.pde" shows how to interpolate, or add new points in between existing points, using various methods.

"Interpolation_Demos_2.pde" is improved over the original, in the sense that inputs to the interpolation function are indexed
backwards in time from the most recent data point, useful when running interpolation on live sensor data, because then
you don't have the luxury of examining any data more recent than what just arrived.
This version is also a bit better thought out.

Check for updates once in a while, because we are tweaking the code over time as we better learn the techniques and refactor the code, etc. We will insert the significant discoveries into the linear photodiode array sensor examples and libraries over time as we perfect them.

=========================================================================================
Description of Edge Detection in under 3 minutes: (was 1 minute, but we added quite a bit)
=========================================================================================

The analog pixel values can be sampled a few times and averaged, to reduce noise. Or not, if speed more the concern vs accuracy. A balance can be found by experiment; perhaps 1 sample is noise-free enough.

The raw sample data can be stored in an array, or processed as it becomes available, depending on if it has to be
sent somewhere first, or other priorities. 

The less loops we use for processing, the faster. In other words, the more DSP steps we can perform in one loop, the faster the results get generated, due to relatively less overhead. 

There is an art to accomplishing extreme efficiency in digital signal processing; the programmer is always tweaking the code as new stunts are learned. I am kinda re-inventing the wheel here for the sake of learning, pitfalls and all. This way, when you learn something, you really know it, as opposed to nebulous theories, or unverified textbook claims on how something works. 

It's a simple yet ideal learning method: Construct test beds sketches. Paradox, bang head on desk in frusturation, resolve paradox into solution, celebrate, repeat aggressively. Once the dust settles, plug the new functionality into the main software.

Now we get to work, below is my current DSP recipe for 1d edge finding, which will probably change as I learn more:  

1st, using a 'maximum slope detector' loop, we should identify lower and upper indexes to a window of data which contains slopes caused by a narrow shadow cast upon the sensor from a wire, etc. This way, the steps which follow do not have to do extra work on data which contains no edges, a waste multiplied by each subsequent operation. 

So the system is going to perform slope finding on the original data first, which will set an upper and lower limit to what data will be sub-processed. I think this would problematic for detecting weak edges, but the instrument we have in mind will be sensing a single, clean shadow of a wire, using an LED background light which almost saturates the sensor. So, a pretty ideal signal for isolating/windowing.

2nd, a popular method to cleanly identify edges in the data is to convolve a '2nd derivative of a gaussian' with the interesting data, as a smoothing (aka blurring) / edge detection all-in-one step. 
Convolution runs in a loop, one sample at a time. The output from convolution shows a negative peak corresponding to bright-to-dark gradents in the original data, and a positive peak for dark-to-bright gradients.

3rd, interpolation can be applied to the convolution output data to further smooth it. 

4th, a parabola can be fit to the top three samples of the two main resulting peaks/troughs, to find center of the edges with subpixel resolution in the x axis, aka quadradic polynomial interpolation. And there is a version of this which takes 4 inputs, rather than 3, and is claimed to be much more accurate, but again at a speed cost. I will sort these out after I get the basic 3 point one working ok.

Then the subpixel x axis difference between the two results is the center of a shadow cast upon the sensor.

On the topic of how much smoothing to apply, the 'wideness / 'narrowness' of the gaussian kernel used in the convolution, aka 'Sigma', sets how agressive the smoothing (blurring) is. This is otherwise known as the scaling problem in edge detection, and it's about finding a best compromise between aggressive smoothing vs light smoothing. Too little smoothing, and noise remains in the data, which reduces edge-finding accuracy. Too much smoothing, and the major edges themselves are blurred, which reduces accuracy. So, there is a sweet spot which must be set by adjustment of the kernel's sigma.

Thresholding ignores edges which fall below a certain steepness of gradient, etc. Again, its all about tweaking it so it rejects noise, but not desired edges.

Then there is the balance between smoothing and thresholding, which is subtle and depends on the particular situation.
Also, thresholding may be used more than once, and at different scales to further refine the sensitivity of the system.

That's all I got for ya now.

This commercial software website explains edge detection:
http://docs.adaptive-vision.com/curr...Detection.html

and sub-pixel resolution method, by fitting a parabola
http://docs.adaptive-vision.com/curr..._Subpixel.html

This book chapter explains a bunch of 2d (camera) edge finding techniques.
I am working on 1d versions (a line of pixel values, rather than an area).

Machine Vision Edge Detection
http://www.cse.usf.edu/~r1k/MachineV...n_Chapter5.pdf

