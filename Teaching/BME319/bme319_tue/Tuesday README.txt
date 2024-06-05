BME 319 Lab
Fall 2013

J.B. Jacobs, Ph.D.

Monday, September 17, 2013

---
SESSION NOTES: 

There are some major dropouts in the data (large spiky sections).  Sometimes they affect the left eye data (lh), sometimes the right.  Examine files 1-4 and decide which eye gives you the best-quality data and use that eye for your analyses for Question 1.  Then do the same for files 5-8 to decide which eye to use for Question 2.

For the feedback experiment data (files 11-20), the eye position data is offset to the left by several degrees.  This is not going to affect your analyses.  Concentrate on your simulation of what you would expect the eye and target to do in the ideal experimental situation, and compare that to the qualitative data (i.e., what sort of oscillation you saw, if any), and if they do not agree, why do you think that was.

For part 2, remember that the chair signal (st) is VELOCITY, while the sampled eye data are POSITION (lh and rh).  I have included eye VELOCITY data (lhv and rhv) that have been derived from the position data by a central-point differentiator.


---
COMPUTER DATA

For instructions on any MATLAB command, type help followed by the name of the command: 'help load' will tell you how to load files.

At least one member of your group should bring a flash drive with at least 30 MB of available space.

At the end of the lab session you will copy the following directory: MAT data

You should also get Zoomtool from the laboratory webpage.
   
1) 'MAT data' contains 28 files with the digitized data from the Smooth Pursuit, Feedback and Saccadic Latency trials as follows:

	1-4: trapezoid
	5-8: sine
	9-10: imaginary tracking
	11-15: positive feedback (0.25, 0.5, 1.0, 1.5, 2.0)
	16-20: negative feedback (0.25, 0.5, 1.0, 1.5, 2.0)
	21: Saccadic latency
	22-27: VOR tests
	28: VOR Chair calibration (CCW/CW 20 deg/sec)


Copy the data to your computer.  In MATLAB, use 'cd' to change to the directory with the data.  Load these files with the 'load' command.  Type 'whos' to verify that you now have the following variables in memory: rh, lh, st.  (There may be additional ones such as rhv or lhv which are velocity data created from the position data.)  

The data sampling rate is 500 Hz.

Create a time vector, t, as follows:  t=(1:length(rh))/500;  where 500 is the sampling frequency, and rh(end) is the number of samples in rh (which should also be the number of samples in lh, and st).	

Plot the data: plot(t,lh,'g', t,rh,'c', t,st,'r')  will draw the right eye data in light blue, the left eye data in green and the target data in red.  Other color choices are 'w' (white), 'y' (yellow), 'm' (magenta), 'b' (dark blue), 'k' (black).

2) The 'Zoomtool' directory contains MATLAB files that need to be on your MATLAB path to operate. Type 'help path' to learn how to add directories to your MATLAB path.  You can verify that zoomtool is installed by typing 'zoomtest'.  Type 'help zoomtool' for more information on using zoomtool.