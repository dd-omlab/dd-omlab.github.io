% ao_deblink: Remove blinks from data recorded by sampling from
% (e.g.) Eyelink's optional analog out card.
% Currently this is best tuned for data directly imported from Eyelink EDF
% files.
% Usage: out = ao_deblink( in, [keyword/value pairs])
% where 'in' is pos data (e.g., lh). This is the only REQUIRED ARGUMENT
% allowed keywords:
%  'pos_lim',   'pos_lim_min', 'pos_lim_max'
%  'vel_lim',   'vel_lim_min', 'vel_lim_max'
%  'acc_lim',   'acc_lim_min', 'acc_lim_max'
%  'spread_ms', 'samp_freq'
%  'verbose',   'plot_res'
% 
% Using the short form, e.g. 'pos_lim' (or 'vel_lim' or 'acc_lim') will set
% the '_max' and '_min' values to be the positive and negative of the supplied
% value. E.g., if vel_lim = 1000, vel_lim_min = -1000, vel_lim_max = 1000.
%
% Default values: pos: 40, vel 100, acc 25000
%                 spread_ms: 10, samp_freq: 500
%
% Use 'deblink_set' GUI to view/modify parameters.
%
% What could go wrong? I am assuming a close-enough-to-normal distribution
% of eye-movement position data (for generous values of "close enough"). 
% So far, moderate amounts of blinking (one every 5-10 seconds) does not 
% seem to shift the mean noticeably, even though Eyelink AO drives voltage
% to the minus rail when it detects a dropout, while the EDF represents
% blinks as maximal POSITIVE values.

% Written by: Jonathan Jacobs  
% Created:    November 2016

% 08 Jan 2019: added new "NaN spreading" to clean area to either side of NaNs
% 29 Jun 2022: Updated to use keyword/value input pairs
% 30 Jun 2022: Created GUI 'deblink_set' to allow on-the-fly parameter changes
%   Useful for testing fine-tuning.
% 01 Jul 2022: Simplified by removing statistical limits setting.
%   Return to default PVA limits of 40, 1000, 25000
%   Changed spread to use msec. Default +/-10
% 12 Jul 2022: Added 'use_pos','use_vel','use_acc' and 'use_spread' checkbox
%   checking. If set to zero, that modification will not be applied.

% To do: Add popup menu of common settings to 'deblink_set.mlapp'?

function [pos_d, vel_d, acc_d] = ao_deblink(pos, varargin)

global samp_freq

if all(isempty(pos))
   disp('deblink_ao: input array is empty!')
   pos_d = [];
   return
end

% Set values for parameters not specified in varargin
% Look in omtools_prefs/omprefs for last set used. If not found, use defaults
try
   curdir = pwd;
   cd(findomprefs)
   load('deblink_vals.mat','dbvals');
   cd(curdir)
   pos_lim_max = dbvals.pos_max;  pos_lim_min = dbvals.pos_min;
   vel_lim_max = dbvals.vel_max;  vel_lim_min = dbvals.vel_min;
   acc_lim_max = dbvals.acc_max;  acc_lim_min = dbvals.acc_min;
   spread_ms = dbvals.spread_ms;
   plot_res = dbvals.plot_res;
   verbose = dbvals.verbose;
   use_pos = dbvals.use_pos;
   use_vel = dbvals.use_vel;
   use_acc = dbvals.use_acc;
   use_spread = dbvals.use_spread;
catch
   % default argument values
   fprintf('Using default values.\n')
   pos_lim_max =    40;  pos_lim_min =   -40;
   vel_lim_max =  1000;  vel_lim_min =  -1000;
   acc_lim_max = 25000;  acc_lim_min = -25000;
   spread_ms = 10;
   plot_res = 0;
   verbose = 0;
   use_pos = 1;
   use_vel = 1;
   use_acc = 1;
   use_spread = 1;
end

spread_samps = round(spread_ms * (samp_freq/1000));

% Parse function call for overriding keyword/val inputs
varg_keys = { ...
   'pos_lim',     'pos_lim_min', 'pos_lim_max', ...
   'vel_lim',     'vel_lim_min', 'vel_lim_max', ...
   'acc_lim',     'acc_lim_min', 'acc_lim_max', ...
   'spread_ms',   'samp_freq', ...
   'verbose',     'plot_res'   ...
   };

for vv = 1:length(varargin)-1
   try
      arg_ind = find(strcmpi(varg_keys,varargin{vv}));
      if isempty(arg_ind)
         continue
      end
      this_arg = varg_keys{arg_ind};      
   catch
      errorbeep
      fprintf('Could not get argument #%d\n',vv);
      keyboard
   end
   
   try
      this_val = varargin{(vv+1)};
   catch
      errorbeep
      fprintf('Could not get value #%d\n',vv+1);
      keyboard
   end
   
   switch this_arg
      case 'pos_lim'
         pos_lim_min = -this_val;
         pos_lim_max =  this_val;
      case 'pos_lim_min'
         pos_lim_min =  this_val;
      case 'pos_lim_max'
         pos_lim_max =  this_val;

      case 'vel_lim'
         vel_lim_min = -this_val;
         vel_lim_max =  this_val;         
      case 'vel_lim_min'
         vel_lim_min =  this_val;
      case 'vel_lim_max'
         vel_lim_max =  this_val;

      case 'acc_lim'
         acc_lim_min = -this_val;
         acc_lim_max =  this_val;
      case 'acc_lim_min'
         acc_lim_min = this_val;
      case 'acc_lim_max'
         acc_lim_max =  this_val;
         
      case 'spread_ms'
         spread_ms = this_val;
         if spread_ms > 100
            fprintf('Spread limited to +/-100 msec.\n')
            spread_ms = 100;
         end
      case 'samp_freq'
         samp_freq = this_val;
      case 'verbose'
         verbose = this_val;
         
      otherwise
         errorbeep
         fprintf('ao_deblink: unknown keyword: %s\n',this_arg);
   end
end

% Optionally display params to console
if verbose == 1
   valstr1 = sprintf('Pos: [%d %d], Vel: [%d %d], Acc: [%d %d].', ...
      pos_lim_min,pos_lim_max,vel_lim_min, vel_lim_max,acc_lim_min, acc_lim_max);
   valstr2 = sprintf('Spread: %.3f, Sampling Freq: %d',spread_ms,samp_freq);
   fprintf('%s %s\n\n',valstr1,valstr2);
end

if isempty(samp_freq) || samp_freq==0
   samp_freq = input('Enter the sampling frequency (default = 500): ');
   if isempty(samp_freq)
      samp_freq = 500;
   end
end

% Begin calculations
vel = d2pt(pos,3,samp_freq);
acc = d2pt(vel,3,samp_freq);

% Old statistical analysis of pos,vel,acc data:
%{
% assume normal distribution
% (can we REALLY make this assumption for EM data???)
% Don't think so -- use histfit after doing histogram to decide.
% -- Stats TBX function -- find basic replacement -- 
[mu_pos,sig_pos]=normfit(stripnan(pos));
[mu_vel,sig_vel]=normfit(stripnan(vel));
[mu_acc,sig_acc]=normfit(stripnan(acc));

% FAKE FAKE FAKE!!!
mu_pos =   50;   sig_pos =    -50;
mu_vel =  1000;  sig_vel =  -1000;
mu_acc = 75000;  sig_acc = -75000;

% upper/lower limits for actual eye-movement data
% defaults +/-50,1000,75000
min_pos_hi_lim =   50;   min_pos_lo_lim =     50;
min_vel_hi_lim = 1000;   min_vel_lo_lim =  -1000;
min_acc_hi_lim = 75000;  min_acc_lo_lim = -75000;

sig_spread = 1.125;
pos_hi_lim = mu_pos + sig_spread*sig_pos; 
pos_hi_lim = max(pos_hi_lim, min_pos_hi_lim);
pos_lo_lim = mu_pos - sig_spread*sig_pos; 
pos_lo_lim = min(pos_lo_lim, min_pos_lo_lim);

vel_hi_lim = mu_vel + sig_spread*sig_vel; 
vel_hi_lim = max(vel_hi_lim, min_vel_hi_lim);
vel_lo_lim = mu_vel - sig_spread*sig_vel; 
vel_lo_lim = min(vel_lo_lim, min_vel_lo_lim);

acc_hi_lim = mu_acc + sig_spread*sig_acc; 
acc_hi_lim = max(acc_hi_lim, min_acc_hi_lim);
acc_lo_lim = mu_acc - sig_spread*sig_acc; 
acc_lo_lim = min(acc_lo_lim, min_acc_lo_lim);
%}

% Initialize deblink data holders
pos_d = pos; 
vel_d = vel;
acc_d = acc;

% Debug mode will show deblinked p,v,a at each step
debug = 0;
if debug == 1
   posfig = figure; plot(pos_d); hold on; box on
   title('g: pos pts, r: vel pts, m: acc pts')
   velfig = figure; plot(vel_d); hold on; box on
   title('g: pos pts, r: vel pts, m: acc pts')
   accfig = figure; plot(acc_d); hold on; box on
   title('g: pos pts, r: vel pts, m: acc pts')
end

% Find position points outside of limits
bad_pos = [];
if use_pos
   bad_pos = union( find(pos<pos_lim_min), find(pos>pos_lim_max) );
end
pos_d(bad_pos)=NaN; %#ok<*FNDSB>
vel_d(bad_pos)=NaN;
acc_d(bad_pos)=NaN;
if debug == 1
   figure(posfig);plot(pos_d,'g')
   figure(velfig);plot(vel_d,'g')
   figure(accfig);plot(acc_d,'g')
end

% Find velocity points outside of limits
bad_vel = [];
if use_vel
   bad_vel = union( find(vel<vel_lim_min), find(vel>vel_lim_max) );
end
pos_d(bad_vel)=NaN;
vel_d(bad_vel)=NaN;
acc_d(bad_vel)=NaN;
if debug == 1
   figure(posfig);plot(pos_d,'r')
   figure(velfig);plot(vel_d,'r')
   figure(accfig);plot(acc_d,'r')
end

% Find acceleration points outside of limits
bad_acc = [];
if use_acc
   bad_acc = union( find(acc<acc_lim_min), find(acc>acc_lim_max) );
end
pos_d(bad_acc)=NaN;
if debug == 1
   figure(posfig);plot(pos_d,'m')
   figure(velfig);plot(vel_d,'m')
   figure(accfig);plot(acc_d,'m')
end

% Expand the NaNs 'spread_samps' places to either side. 
if use_spread == 1
   ss = fix(spread_samps);
else
   ss = 0;
end
for ii = 1:ss
   temp1p = [pos_d(1); pos_d(1:end-1)];
   temp2p = [pos_d(2:end); pos_d(end)];   
   temp3p = (pos_d+temp1p)/2;
   temp4p = (pos_d+temp2p)/2;
   pos_d  = (temp3p+temp4p)/2;

   %if plot_res == 1
      % Calc NaN-spread vel
      temp1v = [vel_d(1); vel_d(1:end-1)];
      temp2v = [vel_d(2:end); vel_d(end)];
      temp3v = (vel_d+temp1v)/2;
      temp4v = (vel_d+temp2v)/2;
      vel_d  = (temp3v+temp4v)/2;
      % Calc NaN-spread acc
      temp1a = [acc_d(1); acc_d(1:end-1)];
      temp2a = [acc_d(2:end); acc_d(end)];
      temp3a = (acc_d+temp1a)/2;
      temp4a = (acc_d+temp2a)/2;
      acc_d  = (temp3a+temp4a)/2;
   %end
end

% Display results. P,V,A in separate axes.
if plot_res == 1
   t = maket(pos_d);
   figure;
   subplot(3,1,1); box; hold on
   plot(t,pos,'b');
   plot(t,pos_d,'r');
   title('Deblinked position')
   xlabel('Time (sec)'); ylabel('Position (deg)')
   
   subplot(3,1,2); box; hold on   
   plot(t,vel,'b');
   plot(t,vel_d,'r');
   title('Deblinked velocity')
   xlabel('Time (sec)'); ylabel('Velocity (deg/sec)')

   subplot(3,1,3); box; hold on
   plot(t,acc,'b');
   plot(t,acc_d,'r'); 
   title('Deblinked acceleration')
   xlabel('Time (sec)'); ylabel('Accel (deg/sec^2)')
end

%{
% OLD NaN spread method
% for now(?), disable the spread feature
% all points that meet exclusion criteria
bad_pts = union(bad_pos, bad_vel);
bad_pts = union(bad_pts, bad_acc);

% and then spread to catch points on either side
bp2 = [bad_pts(1); bad_pts];
bp1 = [bad_pts; bad_pts(end)];
temp = abs(bp2-bp1);
bp_seps = bad_pts(find(temp>1)); %#ok<FNDSB>
for i = 1:length(bp_seps)
   plug = (bp_seps(i)-pre_width):(bp_seps(i)+post_width); 
   x = plug(plug>0 & plug<poslen);
   pos_d(x)=NaN;
end
%}

end %function ao_deblink