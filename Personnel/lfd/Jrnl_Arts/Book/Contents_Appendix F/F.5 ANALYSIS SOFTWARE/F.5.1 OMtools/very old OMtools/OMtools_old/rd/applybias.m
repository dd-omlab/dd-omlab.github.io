% applybias.m:  
% Apply the offset and scaling factor(s) found by 'getbias' to the data being loaded.

% written by: Jonathan Jacobs
%             February 2004  (last mod: 01/25/04)

% clear the eyelink blinks
%newdata=deblink(newdata);  %% BIG problem with deblink is that
                            %% many MATLAB routines choke on NaNs.  Dumb.
                            %% So-so sol'n: use 'zeronans' and 'renanify' on
                            %% either side of troubled routines.

% we now know the channel names, so we can
% read in the unfolding file, if it exists, and apply the fixes.
unfold 

if ~doScaling
   return
end

% if the data file does not have its own stored channel names, we will use the ones
% read in from the bias file.
if ~exist('chnlstr2')
	chnlstr2='';
	for i=1:length(chName)
	  chnlstr2 = [chnlstr2 char(chName(i,:)) ','];
    end 
    chnlstr2=chnlstr2(1:end-1);
end

% parse the channel list to find channel names, in particular which is hor stim
% and which is vert stim.
% there should be numChan-1 commas separating the channel names
seplist = findstr(chnlstr2, ',');
if length(seplist) ~= numChan-1
	disp(chnlstr2)
	disp('Error!  Channel list malformed?')
	return %% break?
end

channel = {}; hor_stm=[]; vrt_stm=[];
rem = strtrim(lower(chnlstr2));
for i=1:numChan,
	[channel{i}, rem] = strtok(rem, ',');
	if strcmp('st', channel{i} ), hor_ind=i; end
	if strcmp('sv', channel{i} ), vrt_ind=i; end
end

if exist('hor_ind')
   hor_stm = newdata(:,hor_ind);
   hor_stm = hor_stm - hor_stm(1);
end

if exist('vrt_ind')
   vrt_stm = newdata(:,vrt_ind);
   vrt_stm = vrt_stm - vrt_stm(1);
end

% create a vector with st, sv as first two entries so that they are calibrated first
% and therefore available for the other data channels to refer to for the smooth cal
neworder = [1:numChan];
if exist('hor_ind')
   neworder(hor_ind) = NaN;
  else
   hor_ind = NaN;
end

if exist('vrt_ind')
   neworder(vrt_ind) = NaN;
  else
   vrt_ind = NaN;
end

neworder = [hor_ind vrt_ind neworder];
neworder=stripnan(neworder);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we now have the data and the needed offset/scaling factors.
% so let's do the offset and scaling
rectype = lower(rectype);
%scalemethod = lower(input('Use old piecewise (l)inear or new (s)mooth scaling? ','s'));
scalemethod = 'l';

for i = neworder;
   if lower(rectype(1)) == 'c' | lower(rectype(1)) == 's'
      newdata(:,i) = newdata(:,i) - z_adj(i);
      newdata(:,i) = newdata(:,i) / c_scale(i);     

    elseif lower(rectype(1)) == 'r'
      newdata(:,i) = sincorrect( newdata(:,i), r_offset(i), r_scale(i), r_calpt(i) );

    elseif lower(rectype(1)) == 'i' | lower(rectype(1)) == 'v'
      if numcalpts == 1
         % standard calibration
         newdata(:,i) = adj(newdata(:,i), z_adj(i),...
                            maxcalpt(i,:), max_adj(:,i), mincalpt(i,:), min_adj(:,i));
       else
         % extended calibration
         unscaled = newdata(:,i);
		   newdata(:,i) = adj(newdata(:,i), z_adj(i),...
			      maxcalpt(i,:), max_adj(:,i), mincalpt(i,:), min_adj(:,i));

         if (0) %if strcmp( scalemethod(1),'s' )
         	% the smooth scaling will only be applied to eye-movement data channels
         	% we leave stim channels alone because there is no reason to use it.
	         if ( strcmp(channel{i},'rh') | strcmp(channel{i},'lh') )
					% which plane are we working in, and which is the corresponding stim?
					temp = channel{i};
					plane = temp(2);
					if strcmp(plane, 'h')
						stim = hor_stm;
					  elseif strcmp(plane,'v')
						stim = vrt_stm;
					  else
						disp('Error!  Data''s plane is unknown.')
						return
					end
					
					%% Simplest simple solution: apply old-style cal to a vector of [-lim ... lim]
					%% and then pick out the points that have scaled to match the calibration points.
					%% Perform the cal here, pass the result to smoothscale and do the real work there.
					testvect = [mincalpt(i,end) : 0.01 : maxcalpt(i,end)]';
					
					scaled_vect = adj(testvect, 0,...
			      		maxcalpt(i,:), max_adj(:,i), mincalpt(i,:), min_adj(:,i));
			      		
					newdata(:,i) = smoothscale( scaled_vect, newdata(:,i), z_adj(i),...
							maxcalpt(i,:), mincalpt(i,:), stim );
				end
				
			end %% if scalemethod
			
      end %% numcalpts
   end  %% if rectype
end

%return  % back to RD.M for the grand finale...