# Processing-Snippets
A growing pile of short Processing (Java) sketches related to visualizing steps involved in signal processing, with the goal of building up the ingredients for edge detection with subpixel resolution, on pixel data originating from a linear photodiode array sensor.

"Convolution_Demos.pde" demonstrates 1d convolution of existing data with a shorter impulse, or "kernel"
Kinda basic, but I will be improving it.

"Derivatives_of_Gaussian_Bell_Curve.pde" generates and plots the first 5 derivatives of a gaussian.
To find an edge in the pixels, a popular method is to use the 2nd derivative of a gaussian as a smoothing and detection 
in one 'for loop'.  Then fit a parabola to the top 3 points to get subpixel resolution, aka quadradic polynomial interpolation.

"Interpolation_Demos.pde" shows how to interpolate, or add new points in between existing points, using various methods.

