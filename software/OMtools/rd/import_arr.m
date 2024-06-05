% import_arr: import Arrington data text file and save an output file that can
% be read by MATLAB. Save as bin file that is compatible with OMtools?
%
% Issues to consider:
% - Arrington file naming convention is not compatible with MATLAB, as it begins
% with digits, and contains '-'.
% - Arrington is NOT running on a Real-time OS (can force W10,11 to pretend), so
% there may be delays between samples. Need to look at the delta_t column to be
% certain of ACTUAL timing. May need to calc stats for this to decide if data is
% temporarally reliable.
% - Must be consistent choosing which eye is A, which is B.
%   22 Jun 2023: "A" is RE, "B" is LE.

function import_arr

[fn, pn] = uigetfile('*.txt','Select an Arrington data file');

if fn == 0
   fprintf('Canceled.\n')
   return
end

% load the entire file then parse it.
% Lines that begin with  '3' are comments.
% Lines that begin with  '5' are Column names.
% Lines that begin with  '6' are Column abbreviations.
% Lines that begin with  '7' are FrameRate.
% Lines that begin with '10' are EM data.
% Lines that begin with '16' are displayed image file names.

% Data columns repeated for EyeA (columns 2-12), EyeB (columns 13:23):
% t, delta_t, hor, vrt, hor_cor, vrt_cor, region, pup_wid, pup_hgt, qual, fix
% Columns 24-28: GPX, GPY, GPZ, Sample#, marker

fid = fopen(fullfile(pn,fn));

if fid <= 0
   fprintf('Could not open %s. Aborting.\n', fullfile(pn,fn));
   return
end
fprintf('\nImporting from %s.\n',fullfile(pn,fn));

raw_arr_text = fread(fid,'*char')';
fclose(fid);

msglines = cell(10000,1);
msg_beg  = cell(10000,1);

cnt = 0;
tempmsg = raw_arr_text;
while ~isempty(tempmsg)
   cnt = cnt+1;
   [msglines{cnt},tempmsg] = strtok(tempmsg,{newline,char(13)}); %#ok<STTOK>
   if ~isempty(msglines{cnt})
      msg_beg{cnt} = msglines{cnt}(1:3);
   end
end

% Get sampling frequency. One line for EyeA, one line for EyeB. Hopefully the
% same for both? We will use value(s) to check accuracy and stability of
% 'DeltaTime' after we extract the data.
fs_lines = cellfun(@(mm) strfind(mm,['7' 9]),msg_beg,'UniformOutput',false);
fs_lines = find(cellfun(@isempty,fs_lines)==0);
fs_A = 0;
fs_B = 0;
for fsl = 1:length(fs_lines)
   fs_ltext = msglines{fs_lines(fsl)};
   if contains(fs_ltext,'FrameRate')
      [~,fs_temp] = strtok(fs_ltext,':');
      if contains(lower(fs_ltext),'eyea')
         fs_A = str2double(fs_temp(find(isnumber(fs_temp)))); %#ok<FNDSB>
         fprintf('RH (EyeA) frame rate: %g Hz.\n',fs_A);
      elseif contains(lower(fs_ltext),'eyeb')
         fs_B = str2double(fs_temp(find(isnumber(fs_temp)))); %#ok<FNDSB>
         fprintf('LH (EyeB) frame rate: %g Hz.\n',fs_B);
      end
   end
end

% Is this binocular data?
unioc = 0;
has_A = 1;
has_B = 1;
if fs_A == 0 && fs_B ~=0
   fprintf('Monocular data -- Only Eye B (lh) detected.\n')
   fs = fs_B;
   has_A = 0;
   unioc = 1;
end

if fs_B == 0 && fs_A ~=0
   fprintf('Monocular data -- Only Eye A (rh) detected.\n')
   fs = fs_A;
   has_B = 0;
   unioc = 1;
end

% CAN the frame rates be unequal?
if (fs_A ~= fs_B) && unioc == 0
   fprintf('Warning: Unequal eye camera frame rates:\n');
   fprintf('RH (EyeA): %g Hz, LH (EyeB): %g Hz.\n',fs_A, fs_B);
   fprintf('Use rate from (A) or (B)? ');
else
   fs = fs_A;
end


% Parse comment lines (begin with '3') to find values needed for calculations:
cmt_lines = cellfun(@(mm) strfind(mm,['3' 9]),msg_beg,'UniformOutput',false);
cmt_lines = find(cellfun(@isempty,cmt_lines)==0);

% Init values
scr_wid = 0;
scr_hgt = 0;
pupA_method = 'unknown';
pupB_method = 'unknown';
view_dist = 0;
ipd = 0;

for cl = 1:length(cmt_lines)
   % Get screen dimensions
   % Find line with 'ScreenSize'. Find values for 1) Hor, 2) Vrt.
   ss_ltext = msglines{cmt_lines(cl)};
   if contains(ss_ltext,'ScreenSize')
      wordlist = split(ss_ltext);
      scr_wid = str2double(wordlist{3});
      scr_hgt = str2double(wordlist{4});
      fprintf('Screen width: %g mm. \nScreen height: %g mm\n',scr_wid,scr_hgt);
   end
   
   % Get pupil method. We will primarily use 'Ellipse' for recording?
   % Find lines with 'pupilSegmentationMethod'. One for EyeA, one for EyeB.
   if contains(msglines{cl},'pupilSegmentationMethod')
      pseg_ltext = msglines{cmt_lines(cl)};
      if contains(lower(pseg_ltext),'eyea')
         if contains(pseg_ltext,'Ellipse')
            pupA_method = 'Ellipse';
         else
            pupA_method = '--';
         end
         fprintf('RH (EyeA) pupil method: %s.\n',pupA_method);
         
      elseif contains(lower(pseg_ltext),'eyeb')
         if contains(pseg_ltext,'Ellipse')
            pupB_method = 'Ellipse';
         else
            pupB_method = '--';
         end
         fprintf('LH (EyeB) pupil method: %s.\n',pupB_method);
      end
   end
   
   % Get viewing distance -- Find line with 'ViewingDistance'.
   if contains(msglines{cl},'ViewingDistance')
      vdist_ltext = msglines{cl};
      wordlist = split(vdist_ltext);
      view_dist = str2double(wordlist{3});
      fprintf('Viewing dist: %d mm.\n',view_dist);
   end
   
   % Get IPD -- Find line with 'InterPupillaryDistance'.
   if contains(msglines{cl},'InterPupillaryDistance')
      ipd_ltext = msglines{cl};
      wordlist = split(ipd_ltext);
      ipd = str2double(wordlist{3});
      fprintf('Interpupillary dist: %d mm.\n',ipd);
   end
   
end % comments loop


% Get times of stimuli images. Lines begin with '16'.
% Parse comment lines (begin with '3') to find values needed for calculations:
stim_lines = cellfun(@(mm) strfind(mm,['16' 9]),msg_beg,'UniformOutput',false);
stim_lines = find(cellfun(@isempty,stim_lines)==0);
st_time = zeros(length(stim_lines),1);
st_name = cell(length(stim_lines),1);
if ~isempty(stim_lines)
   fprintf('Stimulus image list:\n')
end
for stl = 1:length(stim_lines)
   st_ltext = msglines{stim_lines(stl)};
   wordlist = split(st_ltext);
   st_time(stl) = str2double(wordlist(2));
   st_name{stl} = wordlist{3};
   fprintf('   %d. time: %g, name: %s\n',stl,st_time(stl),st_name{stl})
end


% Get data values.
% Find all lines whose first three characters are '10' TAB.
datalines = cellfun(@(mm) strfind(mm,['10' 9]),msg_beg,'UniformOutput',false);
datalines = find(cellfun(@isempty,datalines)==0);
fprintf('Importing %d samples.\n',length(datalines));

data = zeros(length(datalines), 28); %% Arrington data has 28 columns
for ii = 1:length(datalines)
   [wordlist, numwords] = proclinec(msglines{datalines(ii)});
   try
      data(ii,1:numwords) = str2double(wordlist);
   catch
      keyboard
   end
end

% We are most interested in these values:
% EyeA cols 3,4 (or 5,6) for H,V eye pos, 8,9 for pupil size (wid, hgt)
% EyeB cols 15,16 (or 17,18) for H,V eye pos, 20,21 for pupil size (wid, hgt)

% Use viewing distance and screen dimensions to calc gaze angles.
% Need to convert all X,Y values from relative (0->1) to degrees.
% 0,0 is the UPPER LEFT corner. 1,1 is the LOWER RIGHT corner.
% Use screen width, height and viewing distance from subject (v_dist) to calculate.
% Call center of screen wid/2,hgt/2 "xc,yc". This corresponds to 0,0 deg.
% Straightforward for horizontal position:
%    x_dist = (xraw - 0.5)*wid
%    x_deg  = atand(x_dist/v_dist)
% For vertical position, remember that y0 is the TOP of the screen, so
%    y_dist = -(yraw - 0.5)*hgt
%    y_deg  =  atand(y_dist/v_dist)


% Extract relative (0..1) position values from array
% Discard first value of all?
if has_A == 1
   rh_raw = data(2:end,5);
   rv_raw = data(2:end,6);
else
   fprintf('Setting rh data to 0.\n');
   rh_raw = zeros(length(datalines)-1,1);
   rv_raw = rh_raw;
end

if has_B == 1
   lh_raw = data(2:end,17);
   lv_raw = data(2:end,18);
else
   fprintf('Setting lh data to 0.\n');
   lh_raw = zeros(length(datalines)-1,1);
   lv_raw = lh_raw;
end

% Convert position from screen percentage to dist (mm).
rh_dist = (rh_raw-0.5)*scr_wid;
lh_dist = (lh_raw-0.5)*scr_wid;
rh = atand(rh_dist/view_dist);
lh = atand(lh_dist/view_dist);

rv_dist = (rv_raw-0.5)*scr_hgt;
lv_dist = (lv_raw-0.5)*scr_hgt;
rv = atand(rv_dist/view_dist);
lv = atand(lv_dist/view_dist);

% Get t, delta_t. (Will store in "extras" file?)
t_rec = data(2:end,2);
delta_t = data(2:end,3);

% How good at real-time sampling was data? Ideally inter-sample interval should
% simply be 1/sampling_freq (i.e., framerate).
%isi_ideal = 1/fs;
%isi_actual = diff(delta_t);
%isi_err = isi_actual - isi_ideal;
%isi_err_mean = mean(isi_err);
%isi_err_std  = std(isi_err);

fs_err = fs - 1000./delta_t;
fs_err_mean = mean(fs_err);
fs_err_std  = std(fs_err);

fprintf('Actual frame rate error: %g (mean), %g (STD).\n', ...
   fs_err_mean,fs_err_std)

% Can we assign a quality measure to the actual isi?
%fs_q = 1/isi_m;

% Calc pupil area as pi*radius_wid*radius_hgt, ASSUMING ELLIPSE METHOD USED
rpup_w = data(2:end,9);
rpup_h = data(2:end,10);
lpup_w = data(2:end,20);
lpup_h = data(2:end,21);

rp = zeros(length(datalines)-1,1);
if has_A
   if strcmpi(pupA_method,'Ellipse')
      rp = pi * (rpup_w .* rpup_h);
      fprintf('Calculating relative RE pupil size.\n')
   else
      fprintf('RE pupil method is not "Ellipse".\n')
      fprintf('Cannot calculate RE pupil area.\n')
   end
end

lp = zeros(length(datalines)-1,1);
if has_B
   if strcmpi(pupB_method,'Ellipse')
      lp = pi * (lpup_w .* lpup_h);
      fprintf('Calculating relative LE pupil size.\n')
   else
      fprintf('LE pupil method is not "Ellipse".\n')
      fprintf('Cannot calculate LE pupil area.\n')
   end
end

% Save EM data to a .MAT (or .bin?) file.
dat_out = [];
dat_out(:,1) = rh;
dat_out(:,2) = lh;
dat_out(:,3) = rv;
dat_out(:,4) = lv;
dat_out(:,5) = rp;
dat_out(:,6) = lp;

fprintf('Enter a name for this data file (must be of the form aaa#).\n')
goodname = 0;
while goodname == 0
   dat_name = input(' --> ','s');
   if isdigit(dat_name(1))
      fprintf('First character must be a letter.\n')
   else
      goodname = 1;
   end
end

% Write the EM data to file
m_or_o = input('Save as matfile (m) or OMtools file (o)? ','s');
if strcmpi(m_or_o(1),'m')
   save([dat_name '.mat'],'rh','lh','rv','lv','rp','lp','fs')
   fprintf(' Data saved as %s.mat\n',[pn dat_name]);
else
   fid = fopen([dat_name '.bin'], 'w', 'n');
   fwrite(fid, dat_out, 'float');
   fclose(fid);
   fprintf(' Data saved as %s.bin\n',[pn dat_name]);
   % Create biasgen file for use with OMtools
   out_chans{1}{1} = 'rh';
   out_chans{1}{2} = 'lh';
   out_chans{1}{3} = 'rv';
   out_chans{1}{4} = 'lv';
   out_chans{1}{5} = 'rp';
   out_chans{1}{6} = 'lp';   
   arrbiasgen(dat_name,pn,fs,1,out_chans,0);
end
   
% Save extra info to an 'extras' .MAT file.
extras = struct('scr_wid',scr_wid,'scr_hgt',scr_hgt, ...
   'view_dist',view_dist, ...
   'fs_A',fs_A,'fs_B',fs_B, ...
   'ipd',ipd,'t_rec',t_rec, ...
   'fs_err',fs_err,'fs_err_mean',fs_err_mean,'fs_err_std',fs_err_std, ...
   'pupA_method',pupA_method,'pupB_method',pupB_method ...
   );
save([dat_name '_arrx.mat'],'extras');
fprintf(' Extras saved as %s_extras.bin\n',[pn dat_name]);

end % function import_arr


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% isdigit.m: True for elements of a string that are digits.

% Written by:  Jonathan Jacobs
%              May 1999  (last mod: 05/27/99)

function out = isdigit(in)

x = double(in);

%out = zeros(1,length(x));

% 43:+  45:-  46:.
out = find(x>=48 & x<=57 | x==45);
%outmat(where) = 1;
if isempty(out),out=0;end
%out = outmat;

end % function isdigit
