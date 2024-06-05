BME 319 Lab
Fall 2013

J.B. Jacobs, Ph.D.
Wednesday, September 18, 2013
(last updated: xx Sep 2013, xx:xx PM)

---
SESSION NOTES: 




---
COMPUTER DATA

At least one member of your group should bring a flash drive with at least 30 MB of available space.

At the end of the lab session you will copy the following directories:
	ASCII data
	Zoomtool (download from the lab webpage)
   
1) 'ASCII data' contains 28 files with the digitized data from the Smooth Pursuit, Feedback and Saccadic Latency trials as follows:

	1-4: trapezoid
	5-8: sine
	9-10: imaginary tracking
	11-15: positive feedback (0.25, 5, 1.0, 1.5, 2.0)
	16-20: negative feedback (0.25, 5, 1.0, 1.5, 2.0)
	21: Saccadic latency
	22-27: VOR tests
	28: VOR Chair calibration (CCW/CW 20 deg/sec)

Copy the data to your computer.  In MATLAB, use 'cd' to change to the directory with the data.  Load these files with the 'load' command .  This will create a variable with the same name as the file that you loaded.  For instructions on any MATLAB command, type help followed by the name of the command (e.g. 'help load' will tell you how to load text files).

The data sampling rate is 500 Hz.
The data are in 3 columns:
	Left Eye Horizontal (rh)
	Right Eye Horizontal (lh)
	Stimulus (st)

Using MATLAB, you can separate the channels as follows:
	lh = bme091813_1(:,1);
	rh = bme091813_1(:,2);
	st = bme091813_1(:,3);
	
Create a time vector, t, as follows:  t=(1:length(rh))/500;  where 500 is the sampling frequency, and rh(end) is the number of samples in rh (which should also be the number of samples in lh, and st).	

Plot the data: plot(t,lh,'g', t,rh,'c', t,st,'r')  will draw the right eye data in light blue, the left eye data in green and the target data in red.  Other color choices are 'w' (white), 'y' (yellow), 'm' (magenta), 'b' (dark blue), 'k' (black).

2) The 'Zoomtool' directory contains MATLAB files that need to be on your MATLAB path to operate. Type 'help path' to learn how to add directories to your MATLAB path.  You can verify that zoomtool is installed by typing 'zoomtest'.  Type 'help zoomtool' for more information on using zoomtool.