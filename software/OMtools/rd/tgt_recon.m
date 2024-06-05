% tgt_recon: reconstruct st and sv stimuli created by bp & pd experiments.
% Requires presence of a '_results.mat' file in data directory.
%
% useage: [st,sv,tgtwhen,dist,angle,tgtpos] = tgt_recon(namein); 
% input:  namein is NAME (string) of an emData var in memory. If empty,
%         tgt_recon will list all emData names and prompt for selection.
% output: st,sv are arrays of hor and vrt pos, based on timing information
%         contained in the _results file. 
%         tgtwhen is array of target-change times
%         dist,angle are (r,theta) values for vergence stims
%         tgtpos is structure created by reconstruction process
%         If called w/no output, will just plot the reconstructed stimuli.

% Written by: Jonathan Jacobs
% Created: June 2017 
% Updates:
% 28 Dec 2020: Fix to use ml_tgtpos if present. Use PTB/ML timing field.
% 23 Jan 2021: Add ability to use (r,theta) info from vergence experiments.
%              output added 'tgtwhen' contains times of all target changes
% 28 Feb 2022: Better checking of base data name.
% 28 Nov 2022: Warns and ignores case when no .whenML or .when time in tgtpos.

% For some reason, PTB (and EL) store time as seconds, not ms.
% Must convert to ms to prevent results getting rounded to zero.

function [st,sv,tgtwhen,dist,ang,tgtpos] = tgt_recon(namein)

sv=[]; st=[]; tgtwhen=[]; dist=[]; ang=[];

if nargin==0
   EMD = getEMD;
   fn  = strtok(EMD.filename,'.');
   samp_freq = EMD.samp_freq;
   pn   = findfilepath(EMD.filename);
else
   % strip file exten if present
   namein = strtok(namein,'.');
   seps = strfind(namein,filesep);
   if isempty(seps)
      [pn, fn] = findfilepath([namein '_results.mat']);
   else
      pn = namein(1:seps(end));
      fn = namein(seps(end)+1:end);
   end
end %nargin

% get the base name. Make sure it is correct
%temp = strfind(fn,'_results');
%fn_base = fn(1:temp-1);
%if ~strcmpi(namein,fn_base)
%   fprintf('Hey! "namein" ~= "fn_base"!!!\n')
%   keyboard
%end

fn_base = fn;
fn_r  = [fn_base '_results.mat'];
fn_ex = [fn_base '_extras'];

% _extras and _results contain useful info, e.g. target pos, samp_freq
if ~exist(fn_r,'file')
   disp(['  tgt_recon: ' fn_r ' is not present.'])
   return
end

t=[];
times=[];
warning('off','MATLAB:load:variableNotFound')
try    load([pn fn_r],'t');
catch, end
try    load([pn fn_r],'times');
catch, end

tgtpos=[];
ml_tgtpos=[];
try    load([pn fn_r],'tgtpos');
catch, end
try    load([pn fn_r],'ml_tgtpos');
catch, end
warning('on','MATLAB:load:variableNotFound')

if isempty(tgtpos) && isempty(ml_tgtpos)
   fprintf('tgt_recon: %s contains no target info. Done.\n',fn_r);
   return
end

% if we have 'ml_tgtpos' info in _results file, prefer it to 'tgtpos'
if ~isempty(ml_tgtpos)
   tgtpos=ml_tgtpos;
end

try
   tgtwhen=[tgtpos.whenML]; % because t0,tr are using PTB(==ML) timebase.
catch
   try
      tgtwhen=[tgtpos.when]; % because t0,tr are using PTB(==ML) timebase.
   catch
      tgtwhen=NaN;
      fprintf('tgt_recon: "tgtpos" has no "when" field. Ignoring.\n')
   end
end

% tgtpos exists. Check if single plane data (xpos and ypos fields are present), or vergence (dist and angle)
if any(contains(fields(tgtpos),'xpos')) && any(contains(fields(tgtpos),'ypos'))
   xypos=1;
   fprintf('tgt_recon: Loading (xpos,ypos) target info from %s\n', fn_r)
else
   xypos=0;
   %fprintf('!! tgt_recon: No (xpos,ypos) target info found in %s', fn_r)
end

if any(contains(fields(tgtpos),'distance')) && any(contains(fields(tgtpos),'angle'))
   rthpos=1;
   fprintf('tgt_recon: Loading (r,θ) target info from %s\n', fn_r)
else
   rthpos=0;
   %fprintf('!! tgt_recon: No (r,θ) target info found in %s', fn_r)
end

if ~rthpos && ~xypos
   % has neither
   fprintf('tgt_recon: No target info found in %s. Done.\n', fn_r)
   return
end

try
   extras = load([pn fn_ex '.mat']);
catch
   fprintf('I cannot find file: %s\n',[pn fn_ex '.mat']);
   return
end

numsamps = extras.(fn_ex).numsamps;
totaltgtdur = tgtwhen(end) - tgtwhen(1) + 1;
if nargin==1, samp_freq=extras.(fn_ex).sampfreq; end
ds=round(1000/samp_freq);       % int scale factor (for 500Hz data, ds=2)
tgtsamps=fix(totaltgtdur/ds);
pad=zeros(numsamps-tgtsamps,1);
st_temp = NaN(5*numsamps,1);
sv_temp = NaN(5*numsamps,1);
   
% older data might not have struct 't' that holds all timer-related values
if ~exist('times','var') && ~exist('t','var')
   fprintf('I cannot find a "t" or "time" field in the _results.mat\n');
   return
end

if ~exist('times','var') || isempty(times) 
   % no 'times' therefore 't' must exist
   times=t;
end

if ~exist('exp_startPTB','var')
   t0 = times.exp_startPTB;
   %tr = times.rec_startPTB;
   %pad=zeros(fix((t0-tr)/ds),1);
else
end

if xypos
   % Use (x,y) info to reconstruct tgt   
   for ii=1:length(tgtpos)-1
      start = tgtwhen(ii)-t0+1;
      try
         stop = tgtwhen(ii+1)-t0;
      catch
         fprintf('Could not calculate stoptime #%d\n',ii);
         keyboard
      end
      tseg = start:stop;
      st_temp(tseg) = tgtpos(ii).xpos * ones(1,length(tseg));
      sv_temp(tseg) = tgtpos(ii).ypos * ones(1,length(tseg));
      st = [pad; st_temp(1:ds:numsamps*ds)];
      sv = [pad; sv_temp(1:ds:numsamps*ds)];
      st = st(1:numsamps);
      sv = sv(1:numsamps);
   end

elseif rthpos
   % Use (r,theta) info to reconstruct tgt
   dist = tgtpos.distance;
   ang  = tgtpos.angle;
end


% Finish up
if nargout==0
   if xypos
      figure;  subplot(2,1,1);plot(st,'r')
      hold on; subplot(2,1,2);plot(sv,'g')
   else
      %fprintf('tgt_recon: Put (r,theta) plot code from po_analyze here.\n');
      %
   end
   clear st sv tgtwhen dist ang
end