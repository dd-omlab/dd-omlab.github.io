% edf2bin.m: convert an EDF file to a MATLAB-readable binary formatted file.
% usage:  numrecs = edf2bin(fn,pn,options)
% OUTPUT: numrecs = number of distinct recordings in the EDF file
% INPUT:  fn,pn: name and path of the EDF file to be read.
%         (fn can incorporate the path, leaving pn empty.)
%         options: 'pupil' will save pupil data.
% NOTE:   Input arguments are optional. If no file/path is specified, you'll
%         be prompted to select the EDF file using a "Get File" dialog.
%
% As a default, data is arranged in the following column order: [lh rh lv rv],
% but other configurations (including pupil data) are possible.
%
% Exporting data from EDF format requires the 'edf2asc' program from SR Research.
% It is freely available to registered users from their support website at:
% https://www.sr-support.com/forums/index.php
% Select the 'EyeLink Display Software' topic and from there download the
% Developers Kit for your computer's operating system.
%
% This program directly commands edf2asc to export the data to a '.bin'
% file with the same name as the original .EDF file, and in the same directory.
% It is done using the following command: edf2asc xxxx.edf -s -y -miss NaN
%
% Dropped sample points are saved as 'NaN' (IEEE-speak for 'Not a Number').
% Eye-movement events (saccades, fixations and blinks), and other useful
% Eyelink configuration (e.g., screen size and pixels/deg) are saved into a
% MATLAB file with the same name as the EDF plus '_extras.mat'.
%
% Creates the following files:
% .bin
%    File containing the raw data points
% _extras.mat
%    Contains important info about how data was taken. Combine
%    these values with those in _results.mat (created by your 
%    experiment app, e.g. 'omrec.m')
%       .start_times  -- Eyelink time of first data sample ("t0")
%          (NOTE that t0 is NOT the same as app.r.times.rec_startEL)
%       .stop_times   -- Eyelink time of final data sample
%       .out_type     
%       .numsamps     -- # of data samples per channel
%       .samptype     --
%       .sampfreq     --
%       .h_pix_z      -- Center horizontal pixel
%       .v_pix_z      --
%       .h_pix_deg    --  
%       .v_pix_deg    --
%       .t_el.first   --
%       .t_el.last    --
% _events.asc
%    List of fixes, saccades, blinks detected by the EL
% _msgs.asc
%    Messages generated within EL, or sent to it by your experiment app.
% 
% Please see additional comments in edf2bin.m file for additional important
% information about the limitations inherent in the fix/sacc/blink
% structures' position data.

%%% NOTE: Because this is performed on data from EDF file, it is only
%%% "EL-calibrated", i.e., it doesn't have the benefit of the post-facto
%%% calibration calculated by 'cal' and applied during 'rd'. Therefore the
%%% position data in the fix, sacc, and blink structures is only as good as
%%% the Eyelink calibration. 
%%% We should use it in any analysis code that uses these structures ONLY IF
%%% if there is no better-calibrated data available.
%%% Do this by getting timestamp of EL fix/sacc/blink events and convert it
%%% to index into pos data arrays to extract post-hoc calibrated values.

%%% 07 Jun 2022
%%% NOTE: SR's EDF2ASC executable always gives POSITIVE values for
%%% ampl and peak vel!!! Considering correcting it below (approx line 567)
%%% This is (prob) because sacc ampl is sqrt(x^2 +y^2), without separate
%%% x,y values. 

% Written by:  Jonathan Jacobs
% Created:     August 2000

% 05 Apr 12 -- EDF files containing multiple trials will now be properly saved
%              in .bin format
%              Can now deal with channels in different order than default
% 09 Apr 12 -- Now can directly read .EDF files without requiring user
%              intervention and modifications of intermediate .ASC file.
% 15 Apr 13 -- Fixed for case when EDF time (col 1) changes from 6 digits to 7
% 31 Jan 17 -- Oh so many new things!
% 03 Jul 17 -- Fixed for when there is more than 1 record, find the
%              h_pix_deg & v_pix_deg for each record.
%			      Saccades, fixations, blinks, and video frames are also now
%			      separated by record and saved in the proper _extras.mat file
% 07 Jul 17 -- Calls to edf2asc executable should now work for Linux and maybe Windows.
%              Detects if Eyelink Dev Kit has installed edf2asc and directs user to
%              SR-support website if platform-appropriate edf2asc was not present.
% 24 Jul 18 -- Now properly handles EDFs with multiple sub-recordings that have
%              different channels in each record
% 03 Feb 19 -- Added option to save pupil data to a file
% 15 May 20 -- Now recognizes and imports data with head pos ('hh','hv')
% 05 Dec 20 -- If 'edf2bin' is installed, but not in "rd", ask to copy it.
% 24 Mar 21 -- Pupil data incorporated into emData record as rp,lp channels.
%              Minor code cleanup and cosmetic fixes.
% 29 Mar 21 -- Workaround for EDF files with illegal event time stamps.
%              More robust error message guidance.
%              Now detects failure to import EVENT and MSG data. Croaks gracefully.
% 28 May 21 -- Timestamp-error detection fixed for multi-trial EDF records.
% 02 Aug 21 -- Now detects illegal names when selecting EDF file to read.
% 26 Now 21 -- Fixed: detects illegal names when selecting EDF file to read.
% 28 Dec 21 -- Direct detection of SACC, FIX, BLINK starts, rather than 
%              subtracting DUR from END. (could be off by one sample.)
% 11 Jan 22 -- Additional documentation.
% 25 Feb 22 -- Now detects corrupt EDF files. Warns and aborts.
% 01 Mar 22 -- Warn and abort if the file's pathname contains a space.
% 22 Apr 22 -- Detect and optionally delete pre-existing "edf_error.txt" file.
% 12 Jun 22 -- Calculate separate H,V ampl for saccades, and 2D angle.
%              Saved as sacc.dH, .dV and .theta


function numfiles = edf2bin(varargin)

curdir=pwd;
cd(findomtools); cd('rd')
rddir=pwd;

% SR-created directory that contains the edf2asc binary:
% Mac:    /Applications/Eyelink/EDF_Access_API/Example/
% Window: "C:\Program Files (x86)\SR Research\EyeLink\EDF_Access_API\Example\"
% Linux:  /usr/share/edfapi/EDF_Access_API/Example/
fsp = filesep;
secret=0;
%bindir_err=0;
if isunix
   if ismac
      edf2asc_name = 'edf2asc';  % removed the trailing spaces 04/13/20
      bindir='/Applications/Eyelink/EDF_Access_API/Example/';
      secret=exist('edf2asc','file');
      if secret==2, bindir=[pwd fsp]; end
   else
      bindir='/usr/share/edfapi/EDF_Access_API/Example/';
      edf2asc_name = 'edf2asc';
   end
elseif ispc
   edf2asc_name = 'edf2asc.exe';
   bindir='C:\Program Files (x86)\SR Research\EyeLink\EDF_Access_API\Example\';
   %secret=0;
   secret=~isempty(dir('edf2asc*'));
   if secret==1, bindir=[pwd fsp]; end
end

%% 'edf2asc' is NOT initially present in 'rd'.
% If it exists in SR folder, copy to 'rd'.
if secret<1
   % Is EL devkit installed?
   fprintf('I need to copy "edf2asc" from SR binary dir to OMtools\n');
   try
      cd(bindir)
      fprintf('SR bindir exists: %s\n',bindir)
   catch
      %bindir_err=1;
      disp(['The directory ' bindir ' does not exist.'])
      disp('Make sure that you have installed the Eyelink Developers Kit for')
      disp('for your platform. Login to the SR Support web site at:')
      disp('https://www.sr-support.com/forum/downloads/eyelink-display-software')
      return
   end
   % Does 'edf2asc' exist?
   if (exist(edf2asc_name,'file') ~= 2)
      %binfile_err=1;
      disp([edf2asc_name ' does not exist in' bindir])
      disp('Make sure that you have installed the Eyelink Developers Kit for')
      disp('for your platform. Login to the SR Support web site at:')
      disp('https://www.sr-support.com/forum/downloads/eyelink-display-software')
   else
      %binfile_err=0;
      fprintf('"edf2asc" binary found in SR bindir.\n')
   end
   
   % Let's try to copy edf2asc to 'rd'
   yorn=input('Should I copy "edf2asc" into "rd"? (y/n) ','s');
   if strcmpi(yorn,'y')
      if isunix % mac or glx
         cmdstr=sprintf('cp %sedf2asc %s/edf2asc',bindir,rddir);
         try    system(cmdstr);
         catch, disp('Could not copy. Don''t know why.'); return; end
      else
         %is win
         %fprintf('Sorry. Not ready yet.\n');
         cmdstr=sprintf('cp %sedf2asc.exe %s/edf2asc.exe',bindir,rddir);
         try    system(cmdstr);
         catch, disp('Could not copy. Don''t know why.'); return; end
      end
   else
      fprintf('I will not copy "edf2asc" into "rd". Quitting.\n');
      return
   end
end

cd(rddir)
try
   cd(bindir)
catch
   fprintf('Still cannot get to the SR edf2asc binaries. Aborting.\n')
   beep;pause(0.33);beep;pause(0.33);beep
   return
end

%% Start
%
% Special macOS exception for modified edf2asc that properly handles
% video ett stuff. (Built by Peggy Skelly and Jonathan Jacobs 2017.)
binfile=[bindir edf2asc_name];
[rdp,~,~] = fileparts(which(mfilename));
if exist([rdp fsp edf2asc_name],'file')
   binfile=[rdp fsp edf2asc_name ]; % edf2asc_name includes trailing space!
else
end

try    cd(curdir);
catch, cd(matlabroot); end

%savepupils=0;
savepupils=1;

if nargin==0
   fn=[]; pn=[];
else
   savepupils=find(contains(lower(varargin),'pupil'));
   is_pn = find(contains(varargin,filesep));
   is_fn = find(contains(varargin,'.'));
   
   if is_fn, fn=varargin{is_fn};
   else,     fn=[]; end
   if is_pn, pn=varargin{is_pn};
   else,     pn=pwd; end
   
   if all(is_pn==is_fn) && any(is_fn)
      % do we care?
   end
end

if isempty(fn)
   fprintf('Open an EDF file to export:\n');
   [fn,pn]=uigetfile({'*.edf; *.EDF'}, 'Select an EDF file to load');
   if fn==0, disp('Aborted.'); return, end
end

% CHECK PATH NAME FOR SPACES!!!
if contains(pn,' ')
   spc = strfind(pn,' ');
   pos1 = max(spc-20,1);
   pos2 = min(spc+20,length(pn));
   fprintf('No directory on the datafile path is allowed to contain spaces!\n')
   fprintf('Space found at: %s\n',pn(pos1:pos2));
   fprintf('Please rename to remove the space and try again.\n')
   return
end
   
% File name must be a legal MATLAB variable name.
[fn2, ~] = strtok(fn,'.');
if ~isvarname(fn2)
   beep;pause(0.33);beep;pause(0.33);beep
   fprintf('"%s" is not a legal MATLAB variable name. It must begin\n', fn2);
   fprintf('with a letter, and contain only letters, digits, or underscores.\n');
   fprintf('Please rename it and try to run "edf2bin" again.\n');
   return
end

tic
fname = strtok(fn,'.');

%stripped_uscore = 0;
subjstr=fname;
%if subjstr(end)=='_'
%   subjstr = subjstr(1:end-1);
%   stripped_uscore = 1;
%end
inputfile  = fullfile(pn,fn);
msgsfile   = fullfile(pn,[fname '_msgs'] );
datafile   = fullfile(pn,[fname '_data'] );
eventsfile = fullfile(pn,[fname '_events'] );

% For Scenelink info, edf2asc must be called in the same folder that
% has the *.ett file. That's just edf2asc.
cd(findomtools); cd('rd')
try
   cd(pn)
catch
   fprintf('Could not change dir to %s\n.',pn);
end

% HREF is not supported yet, so I'm commenting out the option to ask for it
% Probably NOT worth implementing, as we can derive eye-in-head values from
% gaze-in-space and head-camera angles.
%{
disp('')
disp('Export samples as [G]aze (eye in space) or [H]REF (eye in head)?')
horg = input('-> ','s');
if strcmpi(horg,'h')
   disp('Exporting HREF data')
   exp = ' -sh ';
   samptype = 'HREF';
elseif strcmpi(horg,'g')
   disp('Exporting Gaze data')
   exp = ' -sg ';
   samptype = 'GAZE';
end
%}

exp      = ' -sg ';
samptype = 'GAZE';

sc_flag  = '';
ett_file = strrep(lower(fn),'.edf', '0.ett'); % Make strrep of the edf file case insensitive
if exist(ett_file, 'file')
   sc_flag = ' -scenecam';
end

% Search the EDF file for sampling frequency and recorded eye channel(s).
% This is what an entry looks like:  MSG	3964147 RECCFG CR 1000 2 1 LR
% 'check_edf_export_success' will create a failure file if EDF is corrupt.
% It must be removed before attempting to re-run 'edf2bin'
syscmd=[binfile ' ' inputfile ' ' msgsfile exp sc_flag ' -neye -ns -y '];
success = check_edf_export_success(syscmd);
if ~success
   %numfiles = 0;
   fprintf('Aborting "edf2bin".\n')
   return
end

syscmd=[binfile ' ' inputfile ' ' eventsfile exp ' -nmsg -ns -y '];
success = check_edf_export_success(syscmd);
if ~success
   %numfiles = 0;
   fprintf('Aborting "edf2bin"\n')
   return
end

fprintf('EDF events and messages exported.\n');
fprintf('Searching for channel and frequency information.\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Search the MESSAGES file for important keywords
%  "START", "RECCFG", "END", "DISPLAY", "RES", "VFRAME"
% Use newline char as delimiter. Each line of msgs is a single MSG.
ind = 0; ind2 = 1;
sfpos=NaN(); sf=NaN();
try
   msgs = importdata([pn fname '_msgs.asc'],newline); % your current platform
catch
   try
      msgs = importdata([pn fname '_msgs.asc'],char(13));  % legacy Mac
   catch
      try
         msgs = importdata([pn fname '_msgs.asc'],[char(13) char(10)]); %#ok<*CHARTEN> % win
      catch
         fprintf('I cannot import data from the _msgs.asc file. Aborting.\n')
         beep;pause(0.33);beep;pause(0.33);beep
         return
      end
   end
end
eyes = cell(1); chname=cell(1);
v_found = 1; %gaze = 0; href = 0;
vf = struct;
fixes = struct;
saccs = struct;
blinks = struct;
v_pix_deg = zeros();  h_pix_deg = zeros();
start_time = zeros(); stop_time = zeros();
%filestops = zeros(); filestarts = zeros();

%%% start of record INPUT <time> 62064 (Same time as 'START' line 4 above)
%%%    but another 62064 appears earlier 54ms
%%%  end  of record INPUT <time> 62059 (Follows 'END' line)

h_pix_d=NaN; v_pix_d=NaN;
h_pix_g=NaN; v_pix_g=NaN;
for ii = 1:length(msgs)
   % Find START
   str_temp = strfind(msgs{ii}, 'START');
   if str_temp==1
      [~, temp]=strtok(msgs{ii});
      [temp,~]=strtok(temp);
      start_time(ind2)=str2double( temp );
   end
   % e.g. DISPLAY_COORDS 0 0 1279 1023
   disp_coords = strfind(msgs{ii}, 'DISPLAY_COORDS');
   if disp_coords
      % Get last two entries in line
      [disp_words,~] = proclinec( msgs{ii} );
      h_pix_d = (str2double(disp_words{end-1})+1)/2;
      v_pix_d = (str2double(disp_words{end})+1)/2;
   end
   gaze_coords = strfind(msgs{ii}, 'GAZE_COORDS');
   if gaze_coords
      % Get last two entries in line
      [disp_words,~] = proclinec( msgs{ii} );
      h_pix_g = (str2double(disp_words{end-1})+1)/2;
      v_pix_g = (str2double(disp_words{end})+1)/2;
   end
   % Find sampling frequency
   k=strfind( msgs{ii},'RECCFG' );
   if k~=0
      ind=ind+1;
      %cfglines(ind) = ii; cfgpos(ind)=k;
      % If the sampling freq number is also in the time, then it finds the
      % number in the time string. Only look in the msg string after k
      % (index to start of 'RECCFG') - samp freq must be after 'RECCFG'
      % Use p(end) because it is possible that "500" (or other string)
      % could appear earlier in the line, prob as part of the time string.
      p=strfind(msgs{ii},'2000');
      if ~isempty(p) && p(end)>k, sf(ind)=2000; sfpos(ind)=p(end); end
      p=strfind(msgs{ii},'1000');
      if ~isempty(p) && p(end)>k, sf(ind)=1000; sfpos(ind)=p(end); end
      p=strfind(msgs{ii},'500');
      if ~isempty(p) && p(end)>k, sf(ind)=500;  sfpos(ind)=p(end); end
      p=strfind(msgs{ii},'250');
      if ~isempty(p) && p(end)>k, sf(ind)=250;  sfpos(ind)=p(end); end
      
      temp = msgs{ii}(sfpos(ind):end);
      [~, pos_type] = strtok(temp);
      [~, eye_code] = strtok(pos_type);
      
      eyes{ind} = 'none';
      % Eyes can be encoded either by l,r, or 1,2,3.
      if contains(eye_code,'1'), eyes{ind}='l'; end
      if contains(eye_code,'2'), eyes{ind}='r'; end
      if contains(eye_code,'3'), eyes{ind}='lr'; end
      
      if contains(eye_code,'L') && ~contains(eye_code,'R'), eyes{ind}='l'; end
      if contains(eye_code,'R') && ~contains(eye_code,'L'), eyes{ind}='r'; end
      if contains(eye_code,'LR'), eyes{ind}='lr'; end
   end % if k
   
   % Find pixel resolution
   pixres = ~isempty(strfind(msgs{ii},'RES')) && strcmp(msgs{ii}(1:3),'END' );
   if pixres
      % get last two entries in line
      [pix_words,~] = proclinec( msgs{ii} );
      fprintf('Vertical pixels/deg:   %s\n', pix_words{end})
      fprintf('Horizontal pixels/deg: %s\n', pix_words{end-1})
      v_pix_deg(ind2) = str2double(pix_words{end-1} );
      h_pix_deg(ind2) = str2double(pix_words{end} );
   end
   vframe = ~isempty(strfind(msgs{ii},'VFRAME'));
   if vframe
      [vframe_words,~] = proclinec(msgs{ii} );
      vf(ind2).framenum(v_found)  = str2double(vframe_words{4});
      vf(ind2).frametime(v_found) = str2double(vframe_words{2});
      v_found=v_found+1;
   end
   str_temp = strfind(msgs{ii}, 'END');
   if str_temp == 1
      [~, temp] = strtok(msgs{ii});
      [temp,~]  = strtok(temp);
      stop_time(ind2) = str2double(temp)+1;  %%% 1msec diff betw END and
      ind2 = ind2+1;
   end
end % for ii

if length(start_time) ~= length(stop_time)
   fprintf('The number of recording stop times does not equal\n')
   fprintf('the number of recording start times!\n')
   fprintf('The EDF file may be damaged.\n')
   return
end

% Display coords SHOULD have been set. If not, take a chance & use GAZE coords
if isnan(v_pix_d)|| isnan(h_pix_d)
   h_pix_z = h_pix_g;
   v_pix_z = v_pix_g;
else
   h_pix_z = h_pix_d;
   v_pix_z = v_pix_d;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parse the EVENTS file for saccades, fixations, blinks, GAZE and/or HREF
try
   events = importdata([pn fname '_events.asc'],newline);
catch
   try
      events = importdata([pn fname '_events.asc'],char(13));  % legacy Mac
   catch
      try
         events = importdata([pn fname '_events.asc'],[char(13) char(10)]); % win
      catch
         fprintf('I cannot import data from the _events.asc file. Aborting.\n')
         beep;pause(0.33);beep;pause(0.33);beep
         return
      end
   end
end
% f_found=1; s_found=1; b_found=1;
f_found=0; s_found=0; b_found=0;
%out_found=0;
out_type = 'not found';
recnum = 0; % no records yet, 'START' will indicate a new record

%%% LE & RE fixes (and saccades, blinks) are stored together in their
%%% structures. They will be separated by eye during data loading (rd)
%%% when they are read by their respective parsing functions (e.g.
%%% parsefixfile)

errlines=[];
for ee = 1:length(events)
   if length(events{ee})>=17
      split_line = proclinec(events{ee});
      
      switch split_line{1}	% examine the 1st word in the line
         case 'START'
            recnum = find(start_time <= str2double(split_line{2}),1,'last');
            f_found=0; s_found=0; b_found=0;
         case 'EVENTS'
            out_type = lower(split_line{2});
            
         % Find R and L events
         case 'EFIX'
            % Finds the END of the fix and calcs the start using dur.
            tempstart = str2double(split_line{3});
            tempend   = str2double(split_line{4});
            tempdur   = str2double(split_line{5});
            if  tempend < stop_time(end)
               f_found = f_found+1;
               fixes(recnum).start(f_found) = tempstart; %%%%% - tempdur + 2; %%%
            else
               beep;pause(0.25);beep;pause(0.25);beep
               fprintf('\nSkipped bad fix start in events file line %d.\n',ee+1);
               fprintf('You should open "_events.asc" and manually\n');
               fprintf('delete the line containing %d\n',tempstart);
               errlines(end+1)=ee+1; %#ok<AGROW>
               continue
            end
            fixes(recnum).eye{f_found}  = split_line{2};
            fixes(recnum).end(f_found)  = tempend;
            fixes(recnum).dur(f_found)  = tempdur;
            % As per above notes, the xpos, ypos values are only as
            % reliable as the EL internal calibration routines. If you have
            % rd post-facto calibrated data available, it is better to use it. 
            fixes(recnum).xpos(f_found) = str2double(split_line{6});
            fixes(recnum).ypos(f_found) = str2double(split_line{7});
            fixes(recnum).pupi(f_found) = str2double(split_line{8});
            if length(split_line) > 8
               fixes(recnum).xres(f_found) = str2double(split_line{9});
               fixes(recnum).yres(f_found) = str2double(split_line{10});
            end
            
         case 'ESACC'
            % Finds the END of the sacc and calcs the start using dur.
            tempstart = str2double(split_line{3});
            tempend   = str2double(split_line{4});
            tempdur   = str2double(split_line{5});
            if  tempend < stop_time(end)
               s_found=s_found+1;
               saccs(recnum).start(s_found) = tempstart; %%%% - tempdur + 2; %%%
            else
               beep;pause(0.25);beep;pause(0.25);beep
               fprintf('\nSkipped bad sacc start in events file line %d.\n',ee+1);
               fprintf('You should open "_events.asc" and manually\n');
               fprintf('delete the line containing %d\n',tempstart);
               errlines(end+1)=ee+1; %#ok<AGROW>
               continue
            end
            saccs(recnum).eye{s_found}  = split_line{2};
            saccs(recnum).end(s_found)  = tempend;
            saccs(recnum).dur(s_found)  = tempdur;
            % As per above notes, the position values here are only as
            % reliable as the EL internal calibration routines. If you have
            % rd post-facto calibrated data available, it is better to use it. 
            % EVENTS ALWAYS GIVES ABSOLUTE VALUES FOR AMPL, PVEL!!!
            % Calculate a 2D angle
            saccs(recnum).xpos(s_found) = str2double(split_line{6});
            saccs(recnum).ypos(s_found) = str2double(split_line{7});
            saccs(recnum).xposend(s_found) = str2double(split_line{8});
            saccs(recnum).yposend(s_found) = str2double(split_line{9});
            saccs(recnum).ampl(s_found) = str2double(split_line{10});
            saccs(recnum).pvel(s_found) = str2double(split_line{11});
            dH = saccs(recnum).xposend(s_found) - saccs(recnum).xpos(s_found);
            dV = saccs(recnum).yposend(s_found) - saccs(recnum).ypos(s_found);
            saccs(recnum).dH(s_found) = dH;
            saccs(recnum).dV(s_found) = dV;
            saccs(recnum).theta(s_found) = atand(dV/dH);
            %%%
            if length(split_line) > 11
               saccs(recnum).xres(s_found) = str2double(split_line{12});
               saccs(recnum).yres(s_found) = str2double(split_line{13});
            end
            
         case 'EBLINK'
            tempstart = str2double(split_line{3});
            tempend   = str2double(split_line{4});
            tempdur   = str2double(split_line{5});
            if  tempend < stop_time(end)
               b_found=b_found+1;
               blinks(recnum).start(b_found) = tempstart; %%%% - tempdur;
            else
               beep;pause(0.25);beep;pause(0.25);beep
               fprintf('\nSkipped bad blink start in events file line %d.\n',ee+1);
               fprintf('You should open "_events.asc" and manually\n');
               fprintf('delete the line containing %d\n',tempstart);
               errlines(end+1)=ee+1; %#ok<AGROW>
               continue
            end
            blinks(recnum).eye{b_found} = split_line{2};
            blinks(recnum).end(b_found) = tempend;
            blinks(recnum).dur(b_found) = tempdur;
            
      end % switch case first word of the line
   end % if length of line is long enough to bother looking at
end %jj EVENTS scan loop


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Now export the samples.
a=[binfile ' ' inputfile ' ' datafile exp ' -s -t -y -hpos -nflags -miss NaN'];
system(a);
fprintf('\nEDF to ASCII conversion completed.\n')
fprintf('Importing converted data into MATLAB. Patience is a virtue.\n')
raw = importdata([pn fname '_data.asc'],'\t');
if isempty(raw)
   fprintf('No eye-movement data found. Aborting.\n')
   return
end

try cd(curdir)
catch, end

% Chop off everything after the final tab to remove the non-numeric last column.
fprintf('Data successfully loaded. Converting to numeric values. Tick tock, tick tock.\n')
%rawlen = length(raw);
%numcols = zeros(rawlen,1);
%datatxt = cell(rawlen,1);

%tic
timecol = raw(:,1);
data    = raw(:,2:end);
%{
for i = 1:rawlen
   temp = raw{i};
   rawtabs = find(temp == 9);
   numcols(i) = length(rawtabs);
   timecol{i} = raw{i}(1:rawtabs(1)-1);
   rest = raw{i}( rawtabs(1):rawtabs(end) );
   tabs = find(rest == 9);
   for j = 1:length(tabs)-1
      data(i,j) = str2double( rest(tabs(j)+1:tabs(j+1)) );
   end
end
toc

% check num of entries in each line, because number of channels
% can change between subtrials.
temp = numcols(1:end-1)-numcols(2:end);
chan_chg = find(temp~=0) + 1;
if chan_chg
   disp(['The number of channels changed following trial(s): ' num2str(chan_chg)])
   blockstarts = [1 chan_chg];
   blockstops  = [chan_chg-1 rawlen];
   block=cell(length(blockstarts));
   for j = 1:length(blockstarts)
      block{j} = cell2mat(datatxt( blockstarts(j):blockstops(j) ,:));
   end
else
  block{1} = data;
  blockstarts = 1;
  blockstops = rawlen;
end
numblocks=length(block);
disp('')
%}

block{1} = data;
numblocks=length(block);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(pn)
files = 0;
%filestarts = NaN(1,length(block));
%filestops = NaN(1,length(block));
for bb = 1:length(block)
   data = block{bb}; % because str2double gives 'NaN' for array
   
   % Display the number of channels, ask whether user wants to view them
   % or simply enter/verify channel order.
   [numsamps,numcols] = size(data);
   fprintf('\nBlock %d of %d\n', bb,numblocks)
   fprintf('  %d columns detected.\n',numcols)
   fprintf('  %d samples detected.\n',numsamps)
   
   % Use slower str2double because cell2mat chokes when
   % 6-digit time becomes 7-digit time during recording session.
   %times_str = timecol(blockstarts(bb):blockstops(bb),1);
   %t=zeros(size(times_str,1),size(times_str,2));
   t_el=timecol; %%%str2double(times_str);
   % For multiple records in a single EDF file, there will be gaps in time
   % between each experiment. Use them to separate the experiments.
   tdiff = t_el(2:end) - t_el(1:end-1);
   filestops = find(tdiff>30);	% changed 100 to 30
   filestops = cat(1, filestops,numsamps);
   %filestarts = cat(1, 1,filestops(1:end-1)+1);
   numfilestops = length(filestops);
   
   if isempty(filestops) || length(filestops)==1
      % If there are no record separator lines, just
      % use the last row of the data as the end point
      fprintf('  Only 1 trial detected.\n')
      % no need for '_x' in file name
      singleton = 1;
      filestarts = 1;
      filestops = numsamps;
   else
      fprintf('  %d trials detected.\n',numfilestops)
      fprintf('  Separations at lines: %s\n', mat2str(filestops))
      %septrials = 'y';
      septrials = input('  Treat as individual records? (y/n) ','s');
      if  contains( septrials, 'y' )
         filestarts = [1; (filestops+1)];
         singleton = 0;
      else
         filestarts = 1;
         filestops = numsamps;
         singleton=1;
      end
   end
   
   % Default chan vals coming FROM edf2asc:
   % lh_chan=1; lv_chan=2; rh_chan=4; rv_chan=5;
   % out_chans is the order data will be SAVED in the .BIN file
   numfilestops = length(filestops);
   out_chans=cell(numfilestops,1);
   for xx = 1:numfilestops
      clear rh_chan rv_chan rp_chan lh_chan lv_chan lp_chan hh_chan hv_chan
      fprintf('\n Record %d\n',files+xx);
      fprintf('   Samples: %d\n',(filestops(xx)-filestarts(xx))+1);
      fprintf('   Starting time: %d\n',start_time(xx));
      fprintf('   Sampling frequency: %d\n',sf(files+1));
      fprintf('\nDefault EDF->ASC export assumption:\n' )
      switch numcols
         case 9
            disp('   1) lh, 2) lv, 3) lp (pupil), 4) rh, 5) rv, 6) rp, 7) hh, 8) hv 9) dist')
            disp('   Will save in this order: [lh rh lv rv hh hv rp lp]')
            ch_err_flag=1;
            commandwindow
            yorn = input('Is this correct? (y/n) ','s');
            if strcmpi(yorn,'y')
               lh_chan=1; lv_chan=2; lp_chan=3;
               rh_chan=4; rv_chan=5; rp_chan=6;
               hh_chan=7; hv_chan=8; dd_chan=9;
               ch_err_flag = 0;
            end
            
         case 8
            disp('   1) lh, 2) lv, 3) lp (pupil), 4) rh, 5) rv, 6) rp, 7) hh, 8) hv')
            disp('   Will save in this order: [lh rh lv rv hh hv rp lp]')
            ch_err_flag=1;
            commandwindow
            yorn = input('Is this correct? (y/n) ','s');
            if strcmpi(yorn,'y')
               lh_chan=1; lv_chan=2; lp_chan=3;
               rh_chan=4; rv_chan=5; rp_chan=6;
               hh_chan=7; hv_chan=8;
               ch_err_flag = 0;
            end
            
         case 6
            disp('   1) lh, 2) lv, 3) lp (pupil), 4) rh, 5) rv, 6) rp')
            disp('   Will save in this order: [lh rh lv rv rp lp]')
            ch_err_flag=1;
            commandwindow
            yorn = input('Is this correct? (y/n) ','s');
            if strcmpi(yorn,'y')
               lh_chan=1; lv_chan=2; lp_chan=3;
               rh_chan=4; rv_chan=5; rp_chan=6;
               ch_err_flag = 0;
            end
                        
         case 5
            disp('   1) lh, 2) lv, 3) lp (pupil), 4) rh, 5) rv')
            disp('   Will save in this order: [lh rh lv rv]')
            ch_err_flag=1;
            commandwindow
            yorn = input('Is this correct? (y/n) ','s');
            if strcmpi(yorn,'y')
               lh_chan=1; lv_chan=2;
               rh_chan=4; rv_chan=5;
               ch_err_flag = 0;
            end
            
         case 3
            %ch_err_flag = 1;
            if strcmpi( eyes{files+1}, 'l' )
               lh_chan=1; lv_chan=2; lp_chan=3;
               %out_chans = {'lh';'lv'};
               fprintf('   Left eye only.\n');
               fprintf('   Will save in this order: [ lh lv ]\n');
            elseif strcmpi( eyes{files+1}, 'r')
               rh_chan=1; rv_chan=2; rp_chan=3;
               %out_chans = {'rh';'rv'};
               fprintf('   Right eye only.\n');
               fprintf('   Will save in this order: [ rh rv ]\n');
            end
            ch_err_flag = 0;
            
         otherwise
            fprintf('I do not know the order of the channels here.\n')
            ch_err_flag = 1;
            clear rh_chan rv_chan lh_chan lv_chan 
            clear hh_chan hv_chan rp_chan lp_chan dd_chan
      end %switch numcols
      
      % If none of the known cases exist, prompt for the channel names.
      % Needed if data were taken in an unusual way, e.g., monocularly.
      strarray = [{'lh'},{'rh'},{'lv'},{'rv'},{'lp'},{'rp'}];
      if ch_err_flag
         sampfreq = sf(files+1);
         for ii=1:numcols
            chtemp = data(:,ii); t=maket(chtemp,sampfreq);
            figure; plot(t,chtemp)
            commandwindow
            chname{ii} = input(['Enter a name for channel ' num2str(ii) ...
               '. Enter "-" to ignore it: '],'s');
            chpos = strcmp(chname{ii}, strarray);
            if chpos
               eval( [strarray{chpos} '_chan = i;'])
               %disp(['   Assigning channel ' str2num(i) ' as ' chname{i} '.'] )
            end
         end
      end
      
      clear temp
      if singleton, temp{xx} = subjstr;
      else,         temp{xx} = [subjstr '_' num2str(files+xx)]; end
      
      if ~isvarname(temp{xx})
         fprintf('The name %s must be a legal MATLAB variable name. It must begin\n',temp{xx});
         fprintf('with a letter, and contain only letters, digits, or underscores.\n');
         fprintf('Please rename it and try to run "edf2bin" again.\n');
         return         
      end
      
      % Save all the accessory data:
      % h_pix_deg, v_pix_deg, start_times sacc, fix, blink
      if exist('fixes','var') && xx<=length(fixes)
         extras.fix = fixes(xx);
      end
      if exist('saccs','var') && xx<=length(saccs)
         extras.sacc = saccs(xx);
      end
      % If there is more than 1 record, and no blinks in any of the records,
      % then blink is an empty struc and accessing blink(2) causes an error
      if exist('blinks','var') && xx<=length(blinks)
         extras.blink = blinks(xx);
      end
      if exist('vf','var') && xx<=length(vf) % ~isempty(vf)
         extras.vf = vf(xx);
      else
         extras.vf = [];
      end
      extras.start_times = start_time(xx);
      extras.stop_times  = stop_time(xx); % actually 1ms AFTER final sample!!!!!
      extras.out_type = out_type;
      
      extras.numsamps = filestops(xx)-filestarts(xx)+1; % samples in this record
      extras.samptype = samptype;
      extras.sampfreq = sf(xx);
      extras.h_pix_z = h_pix_z;
      extras.v_pix_z = v_pix_z;
      extras.h_pix_deg = h_pix_deg(xx);	% each trial has its own resolution
      extras.v_pix_deg = v_pix_deg(xx);
      extras.t_el.first = t_el(1);
      extras.t_el.last  = t_el(end);
      %extras.vf = vf;
      eval( [temp{xx} '_extras = extras;'] )
      save([temp{xx} '_extras.mat'],[temp{xx} '_extras'] )
      
      
      % Convert from EL pix values to degrees
      dat_out = [];
      c=0;
      seg = filestarts(xx):filestops(xx);
      if exist('lh_chan','var') && ~all(isnan(data(seg,lh_chan)))
         fprintf('lh data found\n');
         dat_out=(data(seg,lh_chan)-h_pix_z)/h_pix_deg(xx);
         c=c+1;
         out_chans{xx}{c}='lh';
      end
      if exist('rh_chan','var') && ~all(isnan(data(seg,rh_chan)))
         fprintf('rh data found\n');
         dat_out=cat(1,dat_out, (data(seg,rh_chan)-h_pix_z)/h_pix_deg(xx));
         c=c+1;
         out_chans{xx}{c}='rh';
      end
      if exist('lv_chan','var') && ~all(isnan(data(seg,lv_chan)))
         fprintf('lv data found\n');
         dat_out=cat(1,dat_out, -(data(seg,lv_chan)-v_pix_z)/v_pix_deg(xx));
         c=c+1;
         out_chans{xx}{c}='lv';
      end
      if exist('rv_chan','var') && ~all(isnan(data(seg,rv_chan)))
         fprintf('rv data found\n');
         dat_out=cat(1,dat_out, -(data(seg,rv_chan)-v_pix_z)/v_pix_deg(xx));
         c=c+1;
         out_chans{xx}{c}='rv';
      end
      if exist('hh_chan','var') && ~all(isnan(data(seg,hh_chan)))
         fprintf('hh data found\n');
         dat_out=cat(1,dat_out, data(seg,hh_chan));
         c=c+1;
         out_chans{xx}{c}='hh';
         %keyboard
      end
      if exist('hv_chan','var') && ~all(isnan(data(seg,hv_chan)))
         fprintf('hv data found\n');
         dat_out=cat(1,dat_out, data(seg,hv_chan));
         c=c+1;
         out_chans{xx}{c}='hv';
         %keyboard
      end
      
      if savepupils
         if exist('rp_chan','var') && ~all(isnan(data(seg,rp_chan)))
            fprintf('rp data found\n');
            dat_out=cat(1,dat_out, data(seg,rp_chan));
            c=c+1;
            out_chans{xx}{c}='rp';
            pupil.r = data(seg,rp_chan);
         end
         if exist('lp_chan','var') && ~all(isnan(data(seg,lp_chan)))
            fprintf('rp data found\n');
            dat_out=cat(1,dat_out, data(seg,lp_chan));
            c=c+1;
            out_chans{xx}{c}='lp';
            pupil.l = data(seg,lp_chan);
         end
         
         if exist('dd_chan','var') && ~all(isnan(data(seg,dd_chan)))
            fprintf('dd data found\n');
            dat_out=cat(1,dat_out, data(seg,dd_chan));
            c=c+1;
            out_chans{xx}{c}='dd';
         end
      end
      
      % Look for st,sv data?
      stsv=0;
      %disp(' ')
      %yorn=input('Do you want to try to add target data (y/n)? ','s');
      yorn='y';
      if strcmpi(yorn,'y')
         [st,sv] = tgt_recon([pn temp{xx}]);
         if ~isempty(st)
            dat_out=cat(1,dat_out,st);
            c=c+1;
            out_chans{xx}{c}='st';
            stsv=1; fprintf('   st data added\n');
         end
         if ~isempty(sv)
            dat_out=cat(1,dat_out,sv);
            c=c+1;
            out_chans{xx}{c}='sv';
            stsv=1; fprintf('   sv data added\n');
         end
      end
      % Conversion from EL HREF values to degrees.
      % Someday maybe?
      
      % Write the EM data to file
      fid = fopen([temp{xx} '.bin'], 'w', 'n');
      fwrite(fid, dat_out, 'float');
      fclose(fid);
      fprintf(' Data saved as %s.bin\n',[pn temp{xx}]);
      
      % Pupils get saved to a separate _pupil.mat file
      if savepupils
         %eval( [temp{xx} '_pupil = pupil;'] )
         %save([temp{xx} '_pupil.mat'],[temp{xx} '_pupil'] )
      end
      
   end
   files = files + length(filestops);
end % for bb


%% Finish up
try cd(curdir); catch, cd(matlabroot); end

delete([pn fname '_data.asc']) %%%%%% comment out for debugging %%%%%%
disp(' ')
temp=toc;
fprintf('Conversion elapsed time: %0.2f seconds\n',temp);
% Because why would you record several records, each w/separate sampfreq?
edfbiasgen(fname,pn,sf(1),files,out_chans,stsv);
numfiles = files;
if nargout<1, clear numfiles; end

disp('If you don''t like the bias file, delete it and recreate it by running')
disp('"edfbiasgen" yourself. You will need to know the sampling frequency')
disp('used to take the data, as well as which channels were recorded.')
disp('edfiasgen should offer a simple choice "Imported from EDF (binocular)". If not,')
disp('use the following parameters: Method is (V)ideo, Format is (B)inary,')
disp('Calibration is (N)ormal, and Channel Structure is (C)ontiguous.')

if ~isempty(errlines)
   beep;pause(0.25);beep;pause(0.25);beep
   fprintf('\n\nWARNING!\n');
   fprintf('There were anomalous start times in the "_events.asc" file.\n');
   fprintf('They are listed above in the conversion progress text.\n');
   fprintf('You should edit it and manually delete the following lines: ');
   fprintf('%s\n',mat2str(errlines));      
end

end %function edf2bin


%% Functions
% Capture the command line message from edf2asc (using 'diary' built-in fn)
% into the file 'edf_error.txt'.
% If the export goes correctly, the file will be deleted.

function success = check_edf_export_success(command)

success=0;

% Is there already an error file from before? Check ONLY THIS directory.
err_file = fullfile(pwd,'edf_error.txt');
if exist(err_file,'file')==2
   warningbeep
   fprintf('There is already an "edf_error.txt" file in this directory.\n')
   fprintf('It must be deleted before trying to run "edf2bin" again.\n')
   yorn=input('Would you like me to try to delete it and continue (y/n)? ','s');
   if strcmpi(yorn, 'y')
      delete('edf_error.txt')
   else
      fprintf('"edf_error.txt" not deleted. Quitting.\n')
      return
   end
end

% Create an error file for this session.
diary('edf_error.txt')
system(command);
diary off
fid=fopen('edf_error.txt');
sysresult=char(fread(fid)');
fclose(fid);
if contains(sysresult,'Could not process')
   beep;pause(0.33);beep;pause(0.33);beep
   fprintf('*** ERROR: I could not process the EDF file ')
   if contains(sysresult,'Corrupt edf file')
      fprintf('because it is corrupted. ***\n')
   else
      fprintf('for some reason. ***\n')
      fprintf('Open the file "edf_error.txt" to find the reason.\n')
      %keyboard
   end
else
   % Assume it was successfully processed
   success = 1;
   delete('edf_error.txt')
end

end %function check_edf_export_success
