% cal.m:	 Offset and asymmetric, multi-point calibration scaling routine.
% Uses ZOOMTOOL interactively to set zero point and max/min calibration points.

% written by:	Jonathan Jacobs
%					November 1996 - January 2011	 (last mod: 01/20/11)

% 06/26/02 -- it is now possible to cancel entry of rightward or leftward cal point input.
%	 entering 'x' when prompted will cause the program to skip to the next section.
%	 i.e., cancelling rightward cal will jump to the beginning of leftward cal, and cancelling
%	 leftward cal will jump to the calculations and output.
%	 Also: program provides a formatted string to paste directly into 'adjbias.txt'
% 07/18/02 -- the 'sv' plot is now added to the 'st' plot
% 07/18/02 -- need to modify output so that there will always be equal number of leftward and
%	 rightward calibration points, adding dummy values if needed.
% 09/10/02 -- No longer need to use 'pickdata'
% 09/10/02 -- cal is now a function, rather than a script.
% 04/01/03 -- 'cal value' prompt now asks for proper direction (i.e. L, R, U, D, CW or CCW)
% 04/01/03 -- NaNs now reinserted into scaled data
% 04/03/03 -- When working w/data whose uncalibrated values are greatly different than the
%	 calibrated value (e.g. vid sys which uses values in range of 10K), leftward data will be
%	 temporarily rescaled so it can appear in graph at ~same scale as the (now much smaller)
%	 rightward data while rightward cal is being performed.	Then, when performing leftward cal,
%	 rightward data will be shown at original size until 1st leftward cal is done.  At that point
%	 leftward and rightward data should finally be in same range and no more tricks are needed.
% 10/14/03 -- Changed 'xyMatrix', 'xyCtr' to 'xyCur1Mat', 'xyCur1Ctr' to work with updated Zoomtool
% 12/24/03 -- Fixed "scaled display" feature. 
% 01/06/04 -- Scale values display properly after each step (even when canceling w/'x')
% 01/07/04 -- Pos/neg relative scaling should be fixed.	Cal lines properly scale accordingly
%	 and are restored to proper values when left/down/ccw scaling is finished.
% 01/09/04 -- Relative scaled display looks at HEAVILY LP FILTERED data before considering max/min ratio.
%	 This prevents spike artifacts from distorting true max, min values when calculating max(pos)/min(neg), 
%	 and allows us to use a reasonably low value for 'scalelim'.
% 02/02/06 -- Allow user to SKIP any calibration point (will use "1")
% 04/07/09 -- now clears xyCur1Mat indicator in Zoomtool after each accepted calibration point

function null = cal(null);

global lh rh lv rv lt rt st sv xyCur1Mat xyCur1Ctr what_f_array samp_freq

scalelim = 4;	%% determins how many times larger pos (or neg) data can be in relation to
					%% neg (or pos) on plot before we temp rescale to make them appear closer in mag.

% set plot colors: if light background, use darker colors; if black background, use light colors.
tempFigH = figure;
tempFigColor = get(tempFigH,'color');
if tempFigColor(1) == 0.8
	lhColor = 'g';
	rhColor = 'b';
 elseif tempFigColor(1) == 0;
	lhColor = 'y';
	rhColor = 'c';
 else
	lhColor = 'y';
	rhColor = 'c';
end 
close(tempFigH)

i=0;
disp(' 0) --abort--')
if ~isempty(rh), disp(' 1) rh'); end
if ~isempty(lh), disp(' 2) lh'); end
if ~isempty(rv), disp(' 3) rv'); end
if ~isempty(lv), disp(' 4) lv'); end
if ~isempty(rt), disp(' 5) rt'); end
if ~isempty(lt), disp(' 6) lt'); end

whichCh = input('Calibrate which channel? ');

switch whichCh
  case 0, disp('Aborted.'), return
  case 1, pos = rh; whatChStr = 'rh'; dir1str = 'rightward';
			 dir2str = 'leftward'; lcolor = rhColor;
  case 2, pos = lh; whatChStr = 'lh'; dir1str = 'rightward';
			 dir2str = 'leftward'; lcolor = lhColor;
  case 3, pos = rv; whatChStr = 'rv'; dir1str = 'upward';
			 dir2str = 'downward'; lcolor = 'b';
  case 4, pos = lv; whatChStr = 'lv'; dir1str = 'upward';
			 dir2str = 'downward'; lcolor = [0.7 0.3 0];
  case 5, pos = rt; whatChStr = 'rt'; dir1str = 'clockwise';
			 dir2str = 'counter-clockwise'; lcolor = 'c';
  case 6, pos = lt; whatChStr = 'lt'; dir1str = 'clockwise';
			 dir2str = 'counter-clockwise'; lcolor = 'y';
  otherwise, disp('Invalid selection.	Run ''cal'' again.'), return
end

if isempty(pos)
	disp('You have selected an empty data channel.	Please run "cal" again.')
	return
end

[len, numCols] = size( pos );
if numCols > len
	pos = pos';
	[len, numCols] = size( pos );
end

if numCols > 1
	disp('Please use "pickdata" to select only one data channel ')
	disp('from one file and then run "cal" again.') 
	return
end

% How many calibration points?
numcalpts = input('How many calibration point pairs (e.g. +/-15 = one pair)? ');
numMaxCalpts = numcalpts+1; numLcalpts = numcalpts+1;

t = maket(pos);
calfig = figure; 
calaxis = gca;
plotH = plot(t, pos, 'color', lcolor);
if exist('st','var')
	if ~isempty(st), hold on; plot(t,st,'r'); end
end

if exist('sv','var')
	if ~isempty(sv), hold on; plot(t,sv,'g'); end
end
yData = get(plotH, 'Ydata');
zoomtool

% draw a zero line
hold on
lineH = line([0 max(t)],[0 0]);
set(lineH,'Color',[0.6 0.6 0.6]);
set(lineH,'LineStyle','-.');
hold off

% find and store any NaN values in the data
nanarray = find(isnan(pos));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% first do the offset.	This is simply a matter of reading cursor 1's 
% y position and using that value to reset the data and the axis limits.
% If we're not happy with the results, then reset to original dat/lims.
y_or_n = 'n';
while( lower(y_or_n) == 'n' )
	% set plot, lims to original values
	set(plotH, 'Ydata', yData);
	autorange_y(calaxis)

	xyCur1Mat = [];
	xyCur1Ctr = 0;
	cursmatr('cur1_clr')
	while xyCur1Ctr < 1
		disp( ' ' )
		disp( 'Place Cursor One on' )
		disp( 'the new zero point' )
		disp( 'and click the "x,y" button.')  
		temp=input( '	<< Press ENTER to continue, or "q" to quit>> ', 's');
		if strcmp(temp,'q'), return; end
	end

	z_adjust = xyCur1Mat(xyCur1Ctr,2);
	shiftedData = yData - z_adjust;
	set(plotH, 'Ydata', shiftedData);

	% update the plot and the zoomtool y axis
	autorange_y(calaxis)

	y_or_n = lower(input( 'Are you happy with this result (y/n)? ', 's'));
	if isempty(y_or_n), y_or_n = 'y'; end
	if y_or_n == 'q'
		return
	end
end

zeroPtTime = xyCur1Mat(xyCur1Ctr,1)/samp_freq(1);
disp(['Zero offset: ' num2str(z_adjust) '	  Time index: ' num2str( zeroPtTime )])

% find the points that are >=0 and the points that are <0
posPts = find(shiftedData>=0);
negPts = find(shiftedData<0);
posData = shiftedData(posPts);
negData = shiftedData(negPts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Next we take care of scaling the right/up/cw-ward calibration pts.	 Our starting
% point is the now-shifted data from the last loop.  If we make a mistake,
% or are simply not happy with the max-cal points we choose, we reset the data
% and axis limits to those of the shifted data.
% We start by scaling only those points that have POSITIVE values.
% Now properly handles data w/NaNs.

max_cal = (1:numMaxCalpts)+100; 
max_cal(1) = 0;
max_scale = ones(1,numMaxCalpts+1); 
r_cal_time = NaN*zeros(1,numcalpts);
maxUpdatedData = shiftedData;

i=2; % because 0 degrees is entry 1.
while i <= numcalpts+1
	% only want positive (rightward/upward/CW) values
	temp = -1000;
	while (temp<max_cal(i-1)) | isempty(temp)
		disp(' ')
		temp = input( ['Enter ' dir1str ' cal. value #' num2str(i-1) ': '],'s');
		temp = str2num(temp);
		if isempty(temp), temp = -10000; end
	end
	max_cal(i) = temp;

	maxScaledData = zeros(1,len);
	restOfTheData = zeros(1,len);
	
	y_or_n  = 'n';
	while( lower(y_or_n) == 'n' )
		% if the scaled pos data and the unscaled neg data have wildly different
		% scales, the graph will look crappy.	So temporarily scale the leftward
		% data using the rtward scale value. 
		% blinks/dropout artifacts will create artificially large spikes in the data.
		% remove the spikes by LP filtering the crap out of a TEMP copy of the data.
		maxPos = max( lpf(maxUpdatedData,4,samp_freq/100,samp_freq) );
		maxNeg = min( lpf(maxUpdatedData,4,samp_freq/100,samp_freq) );
		%disp('rt cal: scale leftward data -- code block 1')
		displayData = maxUpdatedData;
		if abs(maxNeg/maxPos)>scalelim | abs(maxPos/maxNeg)>scalelim
			% create a temporary array of scaled data for the lower
			% half of the fig.  This way we still see the data in context,
			% instead of only seeing the positive half.	
			displayData(negPts) = negData*max_scale(2);
		end
	
		% set plot, lims to their zero-adjusted values
		set(plotH, 'Ydata', displayData);
		autorange_y(calaxis)

		rAbrtFlag = 0; rSkipFlag = 0;
		xyCur1Mat = []; xyCur1Ctr = 0;
    	cursmatr('cur1_clr')
		while xyCur1Ctr < 1
			disp( ' ' )
			disp( ['Place Cursor One at ' num2str(max_cal(i)) ' degrees and click the "x,y" button.'] )
			disp( [' Press ENTER to continue, "s" to skip this point, ']) % "x" to end ' dir1str ' calibration,'])
			disp( [' or "q" to quit if there is no good ' dir1str ' calibration point: '])
			temp=input(['--> '],'s');
			if strcmp(temp,'q'), return; end
			%if strcmp(temp,'x'), rAbrtFlag = 1; break; end
			if strcmp(temp,'s'), rSkipFlag = 1; break; end
		end
		
		maxScalePts						= find( maxUpdatedData > max_cal(i-1) );
		restPts							= find( maxUpdatedData <= max_cal(i-1) );
		maxScaledData(maxScalePts) = maxUpdatedData(maxScalePts);
		restOfTheData(restPts)		= maxUpdatedData(restPts);

		if rAbrtFlag, numMaxCalpts=i-1; i=numcalpts+2; return; end % prob need min_cal_line stuff here, as below
		if rSkipFlag
			max_scale(i) = 1; maxScaleTime(i) = NaN;
			max_cal_line(i) = line([0 max(t)],[NaN NaN]);
			set(max_cal_line(i),'Color',[0.6 0.6 0.6]);
			set(max_cal_line(i),'LineStyle','-.');
			break;
		end
 
		backedupData = displayData;
		max_scale(i) = (max_cal(i)-max_cal(i-1)) / (xyCur1Mat(xyCur1Ctr,2)-max_cal(i-1));
		maxScaledData(maxScalePts) = ((maxScaledData(maxScalePts)...
											  - max_cal(i-1)) * max_scale(i)) + max_cal(i-1);
		maxUpdatedData = maxScaledData + restOfTheData;
		maxUpdatedData(nanarray) = NaN*ones(size(nanarray));	% reinsert the NaNs
		
		maxPos = max( lpf(maxUpdatedData,4,samp_freq/100,samp_freq) );
		maxNeg = min( lpf(maxUpdatedData,4,samp_freq/100,samp_freq) );
		displayData = maxUpdatedData;
		%disp('rt cal: scale leftward data -- code block 2')
		if abs(maxNeg/maxPos)>scalelim | abs(maxPos/maxNeg)>scalelim
		  displayData(negPts) = negData*max_scale(2);  % since we only need the 1st -- yes '2' is
		end														  % the 1st -- scale value to get pos&neg
																	  % in same range

		% update the plot and the zoomtool y axis
		set(plotH, 'Ydata', displayData);
		autorange_y(calaxis)

		% put up a line at this cal point
		max_cal_line(i) = line([0 max(t)],[max_cal(i) max_cal(i)]);
		set(max_cal_line(i),'Color',[0.6 0.6 0.6]);
		set(max_cal_line(i),'LineStyle','-.');

		y_or_n = lower(input('Are you happy with this result (y/n)? ', 's'));
		if y_or_n == 'n'
			% undo the scaling
			maxUpdatedData = backedupData;
			delete(max_cal_line(i));
		 elseif y_or_n == 'q'
			return
		end

	end
	if ~rSkipFlag
		maxScaleTime(i) = xyCur1Mat(xyCur1Ctr,1);
 		r_cal_time(i-1) = maxScaleTime(i)/samp_freq(1);
 		disp(['Scaling factor for ' num2str(max_cal(i))	 ' deg (' dir1str ') is: ' num2str(max_scale(i)) ...
			'	 Time index: ' num2str( r_cal_time(i-1) )])
	end
	i=i+1;
	
end

posDataFinal = displayData(posPts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now we take care of scaling the left/down/ccw-ward calibration pts.	Our starting
% point is the right-scaled data from the last loop.	If we make a mistake,
% or are simply not happy with the min-cal points we choose, we reset the data
% and axis limits to those of the right-scaled data.
% We finish by scaling only those points that have NEGATIVE values.
% Data with NaNs are now handled properly.

% if the rt/up/cw cal resulted in very different scales for the data we will
% display the unscaled data initially and then after the 1st left/down/ccw 
% cal is applied, we can restore the r/u/c data w/its real scaling applied

minUpdatedData = maxUpdatedData;

min_cal = -100:-1:-(100+numLcalpts); 
min_cal(1) = 0;
l_cal_time = NaN*zeros(1,numcalpts);
min_scale = ones(1,numLcalpts+1); 

i=2; % because 0 degrees is entry 1.
while i <= numcalpts+1

	minScaledData = zeros(1,len); 
	restOfTheData = zeros(1,len); 
	
	% only want negative (leftward) values
	temp = 1000;
	while (temp>min_cal(i-1)) | isempty(temp)
		disp(' ')
		temp = input( ['Enter ' dir2str ' cal. value #' num2str(i-1) ': '],'s');
		temp = str2num(temp);
		if isempty(temp), temp = 10000; end
	end
	min_cal(i) = temp;
	
	y_or_n = 'n';
	while( lower(y_or_n) == 'n' )
		% 1st time we execute this, it sets pos data range to match as-of-yet unscaled
		% negative data range.	We shouldn't have to execute it again, though?
		maxPos = max( lpf(minUpdatedData,4,samp_freq/100,samp_freq) );
		maxNeg = min( lpf(minUpdatedData,4,samp_freq/100,samp_freq) );
		displayData = minUpdatedData;
		%disp('left cal: scale rtward data -- code block 1')
		if abs(maxNeg/maxPos)>scalelim | abs(maxPos/maxNeg)>scalelim
			displayData(posPts) = posData ;			 % set pos data to orig val to match unscaled neg data
		end
		% redraw the max cal lines
		for z = 2:length(max_cal_line)
			if ~isnan(maxScaleTime(z))
				set(max_cal_line(z),'YData',[displayData(maxScaleTime(z)) displayData(maxScaleTime(z)) ]);
			end
		end	


		set(plotH, 'Ydata', displayData);
		autorange_y(calaxis)
			
		lAbrtFlag = 0; lSkipFlag=0;
		xyCur1Mat = []; xyCur1Ctr = 0;
		cursmatr('cur1_clr')
		while xyCur1Ctr < 1
			disp( ' ' )
			disp( ['Place Cursor One at ' num2str(min_cal(i)) ' degrees and click the "x,y" button.'] )
			disp( [' Press ENTER to continue, "s" to skip this point, ']) % "x" to end ' dir2str ' calibration,'])
			disp( [' or "q" to quit if there is no good ' dir2str ' calibration point: '] )
			temp=input(['--> '],'s');
			if strcmp(temp,'q'), return; end
			%if strcmp(temp,'x'), lAbrtFlag = 1; break; end
			if strcmp(temp,'s'), lSkipFlag = 1; break; end
		end

		minScalePts						= find(minUpdatedData < min_cal(i-1));
		restPts							= find(minUpdatedData >= min_cal(i-1));
		minScaledData(minScalePts) = minUpdatedData(minScalePts);
		restOfTheData(restPts)		= minUpdatedData(restPts);

		if lAbrtFlag, numLcalpts=i-1; i=numcalpts+2; return; end % prob need min_cal_line stuff here, as below
		if lSkipFlag
			min_scale(i) = 1; minScaleTime(i) = NaN;
			min_cal_line(i) = line([0 max(t)],[NaN NaN]);
			set(min_cal_line(i), 'Color',[0.6 0.6 0.6]);
			set(min_cal_line(i),'LineStyle','-.');
			break
		end

		backedupData = displayData;
		 min_scale(i) = (min_cal(i)-min_cal(i-1)) / (xyCur1Mat(xyCur1Ctr,2)-min_cal(i-1));
		 minScaledData(minScalePts) = ((minScaledData(minScalePts)...
											  - min_cal(i-1)) * min_scale(i)) + min_cal(i-1);
		 minUpdatedData = minScaledData + restOfTheData;
		 minUpdatedData(nanarray) = NaN*ones(size(nanarray));  % reinsert the NaNs
		
		
		% Adjust displayed data to show results of the calibration.
		% Should only be necessary after setting 1st min cal point.
		maxPos = max( lpf(minUpdatedData,4,samp_freq/100,samp_freq) );
		maxNeg = min( lpf(minUpdatedData,4,samp_freq/100,samp_freq) );
		displayData = minUpdatedData;
		if abs(maxNeg/maxPos)>scalelim | abs(maxPos/maxNeg)>scalelim
			displayData(posPts) = posData * max_scale(2);			% yes, this is MAX scale
		end
		%disp('left cal: scale rtward data -- code block 2')
		for z = 2:length(max_cal_line)
			if ~isnan(maxScaleTime(z))
				set(max_cal_line(z),'YData',[displayData(maxScaleTime(z)) displayData(maxScaleTime(z))] );
			end
		end	

		set(plotH, 'Ydata', displayData);
		autorange_y(calaxis)
	
		% put up a line at this cal point
		min_cal_line(i) = line([0 max(t)],[min_cal(i) min_cal(i)]);
		set(min_cal_line(i), 'Color',[0.6 0.6 0.6]);
		set(min_cal_line(i),'LineStyle','-.');

		y_or_n = lower(input('Are you happy with this result (y/n)? ', 's'));
		if y_or_n == 'n'
			delete(min_cal_line(i));
			minUpdatedData = backedupData;
		 elseif y_or_n == 'q'
			return
		end

	end
	if ~lSkipFlag	 
		minScaleTime(i) = xyCur1Mat(xyCur1Ctr,1);
 		l_cal_time(i-1) = minScaleTime(i)/samp_freq(1);
		disp(['Scaling factor for ' num2str(min_cal(i)) ' ' dir2str ' is: ' num2str(min_scale(i)) ...
			'	 Time index: ' num2str( l_cal_time(i-1) )])
	end
	i=i+1;

end

negDataFinal = displayData(negPts);

xyCur1Mat = [];
xyCur1Ctr = 0;
cursmatr('cur1_clr')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% restore rt/up/cw cal lines to their proper values
% Department of Redundancy Department:
% should have already been done during left/down/cw cal portion.	better safe than sorry.
%finalData(posPts) = posDataFinal;
%finalData(negPts) = negDataFinal;
%set(plotH,'YData',finalData);
for z=2:length(max_cal_line)
	set(max_cal_line(z),'YData',[max_cal(z) max_cal(z)])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Display the zero, max/min cal values in a well-formatted manner
disp( ' ' )
disp( 'These are the adjustment values you have selected.  Enter them ' )
disp( 'into the "adjbias.txt" file for this record''s eye/direction.' )
disp( ' ' )

zStr = num2str(z_adjust);
disp( ['Zero adjustment: ' zStr] )
%disp( ['Zero adjustment: ' zStr '					(time: ' num2str(zeroPtTime) ')'] )

% set R & L equal to max of the two
numMaxCalpts=max(numLcalpts,numMaxCalpts);
numLcalpts=numMaxCalpts;

for i=2:numMaxCalpts
	calPtStr = num2str(max_cal(i));
	scaleStr = num2str(max_scale(i));
	disp([dir1str ' cal factor ' calPtStr ' deg: ' scaleStr] )
	%disp([dir1str ' cal factor ' calPtStr ' deg: ' scaleStr '	 (time: ' num2str(maxScaleTime(i)) ')'] )
end
rStr1 = mat2str(max_cal(2:numMaxCalpts),4);	  % do not include the '0' first entry
rStr2 = mat2str(max_scale(2:numMaxCalpts),4);  % do not include the '0' first entry
if numMaxCalpts == 2
	rStr1 = ['[' rStr1 ']'];  %% mat of len 1 does not add brackets 
 else
	rStr2 = rStr2(2:end-1);	  %% do not want brackets on the scaling data
end
rStr = [ rStr1 '	' rStr2 ];

for i=2:numLcalpts
	calPtStr = num2str(min_cal(i));
	scaleStr = num2str(min_scale(i));
	disp([dir2str ' cal factor ' calPtStr ' deg: ' scaleStr] )
	%disp([dir2str ' cal factor ' calPtStr ' deg: ' scaleStr '	 (time: ' num2str(minScaleTime(i)) ')'] )
end
lStr1 = mat2str(min_cal(2:numLcalpts),4);
lStr2 = mat2str(min_scale(2:numLcalpts),4);
if numLcalpts == 2
	lStr1 = ['[' lStr1 ']'];
 else
	lStr2 = lStr2(2:end-1);
end
lStr = [ lStr1 '	' lStr2 ];			 

disp(' ')
disp('Formatted to paste into ''adjbias.txt'':')
disp([ '%' whatChStr ' times: ' num2str(zeroPtTime) ' ' rStr1 ' ' mat2str(r_cal_time) ' ' ...
			 										   lStr1 ' ' mat2str(l_cal_time) ] )
disp([whatChStr '	 ' zStr '  ' rStr '	' lStr])
disp( ' ' )

return