# Processing-Snippets
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

Check for updates once in a while, because we are tweaking the code over time as we better learn the techniques and refactor the code, etc.

=========================================================================================
Description of Edge Detection in under a minute:
=========================================================================================

The analog pixel values can be sampled a few times and averaged, to reduce noise. 
Or not, if speed more the concern vs accuracy. Maybe a balance can be found by experiment, or maybe 1 sample is clean enough.

Interpolation can be applied to the data prior to edge detection, for higher resolution, but may not be necessary or is too high a speed or noise cost. Also, different flavors of interpolation can interfere with seeing clean 2nd derivatives, essential for the next step.

Next, to find an edge in the pixels, a popular method is to use the 2nd derivative of a gaussian as a smoothing and edge detection in one 'for loop' step.  

Finally, the computer program would fit a parabola to the top three samples of the two main resulting peaks/troughs, to find center of the edges with subpixel resolution in the x axis, aka quadradic polynomial interpolation. And there is a version of this which takes 4 inputs, rather than 3, and is claimed to be much more accurate, but again at a speed cost. I will sort these out after I get the basic 3 point one working ok.

Then the subpixel x axis difference between the two results is the center of a shadow cast upon the sensor.

Left out a few things, like thresholding. Also, the sigma or 'narrowness' of the gaussian kernel used in convolution step, sets how agressive the smoothing is. Narrow tall ones make less blurred results, wide ones make more blurred results, with higher frequencies suppressed more. Too narrow, and the data is noisy and accuracy is lost that way. Too wide, and the sharpness of the peaks is smeared out too much, and accuracy is lost that way. This is otherwise known as the scaling problem in edge detection.

This commercial software website explains edge detection:
http://docs.adaptive-vision.com/curr...Detection.html

and sub-pixel resolution method, by fitting a parabola
http://docs.adaptive-vision.com/curr..._Subpixel.html

This book chapter explains a bunch of 2d (camera) edge finding techniques.
I am working on 1d versions (a line of pixel values, rather than an area).

Machine Vision Edge Detection
http://www.cse.usf.edu/~r1k/MachineV...n_Chapter5.pdf

