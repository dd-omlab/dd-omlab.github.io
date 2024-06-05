% applybias.m:
% Apply the offset and scaling factor found by 'getbias/readbias' to the data.

% written by: Jonathan Jacobs
%             February 2004  (last mod: 03/13/17)

% 14 Apr 2012: Can now apply scaling even if header channels are not in the
%   same order as the adjbias channels.
% 14 Feb 2024: Added try/catch around finding st_ind, sv_ind so if the channel
%   name is empty, it won't crash.

function scaled_data = applybias(data,adjbiasvals)

if isstruct(data)
   try
      data=data.newdata;
   catch
      fprintf('Input data is a structure, but is missing "newdata" field!\n');
      keyboard
   end
   [~,chan_count]=size(data);
   % if no chnums field, assume everything is in order.   
   try
      chnums=data.chnums;
   catch
      chnums=1:chan_count;
   end
end

scaled_data=data;
% clear the eyelink blinks
%newdata=deblink(newdata);  % BIG problem with deblink is that
% many MATLAB routines choke on NaNs.  Dumb.
% So-so sol'n: use 'zeronans' and 'renanify' on
% either side of troubled routines.

z_adj     = adjbiasvals.z_adj;
max_adj   = adjbiasvals.max_adj;
min_adj   = adjbiasvals.min_adj;
maxcalpt  = adjbiasvals.maxcalpt;
mincalpt  = adjbiasvals.mincalpt;
rectype   = lower(adjbiasvals.rectype);
chName    = adjbiasvals.chName;
numcalpts = size(max_adj,2);

%{
%doScaling = enviroG(3);
%if ~doScaling
%   return
%end

% if the data file does not have its own stored channel names, we will use the ones
% read in from the bias file.
% if ~exist('chnlstr2','var')
%    chnlstr2='';
%    for i=1:length(chName)
%       chnlstr2 = [chnlstr2 char(chName(i)) ','];
%    end
%    chnlstr2=chnlstr2(1:end-1);
% end

% parse the channel list to find channel names, in particular which is hor stim
% and which is vert stim.
% there should be chan_count-1 commas separating the channel names
%seplist = findstr(chnlstr2, ',');
%if length(seplist) ~= chan_count-1
%	disp(chnlstr2)
%	disp('Error!  Channel list malformed?')
%	return % break?
%end

%hor_stm=[]; vrt_stm=[];
%rem = strtrim(lower(chnlstr));
%}

% create a vector with st, sv as first two entries so that they are calibrated first
% and therefore available for the other data channels to refer to for the smooth cal
try
   st_ind = find(contains(chName(:,1),'st'));
catch
   st_ind = [];
end
try
   sv_ind = find(contains(chName(:,1),'sv'));
catch
   sv_ind = [];
end

neworder = 1:chan_count;
if ~isempty(sv_ind)
   neworder(sv_ind)=[];
   neworder=[sv_ind neworder];
end
if ~isempty(st_ind)
   neworder(st_ind)=[];
   neworder=[st_ind neworder];
end
neworder=stripnan(neworder);


% We now have the data and the needed offset/scaling factors,
% so let's do the offset and scaling.
% 'chnums' is mapping between (if exists) header chans and adjbias chans.

%scalemethod = lower(input('Use old piecewise (l)inear or new (s)mooth scaling? ','s'));
%scalemethod = 'l';
for ii = neworder
   if lower(rectype(1)) == 'c' || lower(rectype(1)) == 's'
      scaled_data(:,ii) = data(:,ii) - z_adj(chnums(ii));
      scaled_data(:,ii) = data(:,ii) / max_adj(chnums(ii),1);
      
   elseif lower(rectype(1)) == 'r'
      scaled_data(:,ii) = sincorrect( data(:,ii), z_adj(chnums(ii)), ...
         max_adj(chnums(ii),1), maxcalpt(chnums(ii),1) );
      
   elseif lower(rectype(1)) == 'i' || lower(rectype(1)) == 'v'
      if numcalpts == 1
         % standard calibration
         scaled_data(:,ii) = adj(data(:,ii), z_adj(chnums(ii)),...
            maxcalpt(chnums(ii),:), max_adj(chnums(ii),:), ...
            mincalpt(chnums(ii),:), min_adj(chnums(ii),:));
      else
         % extended calibration
         %unscaled = newdata(:,i);
         scaled_data(:,ii) = adj(data(:,ii), z_adj(chnums(ii)),...
            maxcalpt(chnums(ii),:), max_adj(chnums(ii),:), ...
            mincalpt(chnums(ii),:), min_adj(chnums(ii),:));
         
         %{
         if (0) %if strcmp( scalemethod(1),'s' )
            % the smooth scaling will only be applied to eye-movement data channels
            % we leave stim channels alone because there is no reason to use it.
            if ( strcmp(chName{ii},'rh') || strcmp(chName{ii},'lh') ) %#ok<UNRCH>
               % which plane are we working in, and which is the corresponding stim?
               temp = chName{ii};
               plane = temp(2);
               if strcmp(plane, 'h')
                  stim = hor_stm;
               elseif strcmp(plane,'v')
                  stim = vrt_stm;
               else
                  disp('Error!  Data''s plane is unknown.')
                  return
               end
               
               % Simplest simple solution: apply old-style cal to a vector of [-lim ... lim]
               % and then pick out the points that have scaled to match the calibration points.
               % Perform the cal here, pass the result to smoothscale and do the real work there.
               testvect = (mincalpt(ii,end):0.01:maxcalpt(ii,end))';
               scaled_vect = adj(testvect, 0,...
                  maxcalpt(ii,:), max_adj(ii,:), mincalpt(ii,:), min_adj(ii,:));
               newdata(:,ii) = smoothscale( scaled_vect, newdata(:,ii), z_adj(ii),...
                  maxcalpt(ii,:), mincalpt(ii,:), stim );
            end
         end % if scalemethod
            %}
            
      end % numcalpts
   end  % if rectype
end

% back to rd.m for the grand finale.
end % function applybias

%%%
%{
for ii=1:chan_count
   if strcmp('st', chName{ii}), hor_ind=ii; end
   if strcmp('sv', chName{ii}), vrt_ind=ii; end
end

%if exist('hor_ind','var')
%   hor_stm = newdata(:,hor_ind);
%   hor_stm = hor_stm - hor_stm(1);
%end

%if exist('vrt_ind','var')
%   vrt_stm = newdata(:,vrt_ind);
%   vrt_stm = vrt_stm - vrt_stm(1);
%end
%}

%{
neworder = 1:chan_count;
if exist('hor_ind','var')
   neworder(hor_ind) = NaN;
else
   hor_ind = NaN;
end

if exist('vrt_ind','var')
   neworder(vrt_ind) = NaN;
else
   vrt_ind = NaN;
end

neworder = [hor_ind vrt_ind neworder];
%}

