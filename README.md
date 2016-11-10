# Processing-Snippets
A growing pile of short Processing code examples related to visualizing signal processing, with the goal of building up
the ingredients for edge detection with subpixel resolution, on data from a linear photodiode array.

Convolution_Demos demonstrates 1d convolution of existing data with a shorter impulse, or "kernel"

Derivatives_of_Gaussian_Bell_Curve generates and plots the first 5 derivatives of a gaussian.

Interpolation_Demos shows how to interpolate, or add new points in between existing points using various methods.
To find an edge, a popular method is to use the 2nd derivative of a gaussian as a smoothing and detection in one loop.
Then fit a parabola to the top 3 points to get subpixel.
