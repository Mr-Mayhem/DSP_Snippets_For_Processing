# Processing-Snippets
A growing pile of short Processing (Java) sketches related to visualizing steps involved in signal processing, with the goal of building up the ingredients for edge detection of narrow shadows cast upon the sensor window, with subpixel resolution, on pixel data originating from a linear photodiode array sensor.

"Convolution_Demos.pde" demonstrates 1d convolution of existing data with a shorter impulse, or "kernel"
Kinda basic, but I will be improving it.

"Derivatives_of_Gaussian_Bell_Curve.pde" generates and plots the first 5 derivatives of a gaussian.

"Interpolation_Demos.pde" shows how to interpolate, or add new points in between existing points, using various methods.


Just chasing the main ingredients now as I learn about them, then will combine to a final Processing sketch, and an Arduino sketch, for use with the sensors.

The analog pixel values can be sampled a few times and averaged, to reduce noise. 
Or not, if speed more the concern vs accuracy. Maybe a balance can be found by experiment, or maybe 1 sample is clean enough.

Interpolation can be applied to the data prior to edge detection, for higher resolution, but may not be necessary or is too high a speed or noise cost. Also, different flavors of interpolation can interfere with seeing clean 2nd derivatives, essential for the next step.

Next, to find an edge in the pixels, a popular method is to use the 2nd derivative of a gaussian as a smoothing and edge detection in one 'for loop' step.  

Finally, the computer program would fit a parabola to the top three samples of the two main resulting peaks/troughs, to find center of the edges with subpixel resolution in the x axis, aka quadradic polynomial interpolation. And there is a version of this which takes 4 inputs, rather than 3, and is claimed to be much more accurate, but again at a speed cost.

Then the subpixel x axis difference between the two results is the center of a shadow cast upon the sensor.

Left out a few things, like thresholding. Also, the sigma or 'narrowness' of the gaussian kernel used in convolution step, sets how agressive the smoothing is. Narrow tall ones make less blurred results, wide ones make more blurred results, with higher frequencies suppressed more.
