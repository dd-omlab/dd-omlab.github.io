% ML_W_switch: (Mac ONLY) Switches foreground application to either MATLAB
% or to its assistant MATLABWindow (responsible for all App Designer windows)
%   ML_W_switch('ml')  will make MATLAB active
%   ML_W_switch('mlw') will make MATLABWindow active
%
% Requires the presence of the AppleScripts apps "MLW_act" and "ML_act"
% in the OMtools/utils directory. 
%
% We need to activate each one before it can be used. But don't worry,
% I have tried to automate as much of the process as possible, by checking
% all this when "omstart" runs at startup, but you may need to assist me.
%
% Step 1: extract them from their archive.
%   In the OMtools/utils directory, open "ML_{W}_act.zip". It will create a
%   new folder named "ML_{W}_act" in the OMtools/utils folder.
%   Move ML_act and MLW_act from the folder into OMtools/utils folder. 
%   Delete the now-empty ML_{W}_act" folder.
%
% Step 2: Now control-click on "ML_W_act" and select "Open" from the pop-up menu. 
%   You may be asked if you really want to allow it to run. Agree. 
%
% Step 3:
%   Repeat for "ML_act". If MATLABWindow is not already running, trying to
%   open it directly will (stupidly) launch another instance of MATLAB. So
%   to beat this, run "mlw_dummy" to launch MATLABWindow. Then you can open
%   "ML_W_act" the same way as in Step 2.
%
% NOTE: This is necessary any time you install a new copy of OMtools, because
% they are considered new apps, so are quarrantined until you agree they are
% not going to destroy your computer or bring pestilence upon the land.
%
% NOTE 2: Yes, there are almost 2x as many comment lines as code lines.
%
% NOTE 3: Content of scripts:
%      tell application "MATLABWindow"  --(or "MATLAB")
%   	    activate
%      end tell

% Written by: Jonathan Jacobs
% Created:    05 Sept 2017
%
% Noteworthy updates
% 09 Nov 2020: additional shell scripting to check if MLW is running.
% 10 Nov 2020: detects shell script result

% Find running ML,MLW shell script commands:
% pgrep -x 'MATLABWindow'
% pgrep -x 'MATLAB'

function ML_W_switch(which)

if ~ismac, return; end
if nargin~=1, which = 'ml'; end

%q=char(39);  % single quote
olddir=pwd;
[util_dir,~,~] = fileparts(mfilename('fullpath'));
cd(util_dir)

if ~exist('ML_act.app','file') || ~exist('MLW_act.app','file')
   help ML_W_switch
   return
end

switch lower(which)
   case 'ml'
      try
         %a=system('osascript ML_act.scpt');        % osascript is SLOOOOOW
         %a=system('open -b com.mathworks.matlab'); % FASTER
         %! open "./ML_act.app"                     % 'system' returns status
         a=system('open ML_act.app');               % FASTEST
      catch
         a=-1;
      end
      if a~=0  % a==0 means it worked
         beep;pause(0.25);beep;pause(0.25);beep
         help ML_W_switch
         system(['open ' util_dir]);
      end
      
   case 'mlw'
      % IS MATLABWindow already running? If it isn't, launch it by calling
      % "mlw_dummmy.mlapp". Otherwise MLW_act (stupidly) starts a new ML instance.
      %! [ -z $var ] && echo "mlw_dummy.mlapp" || echo "MLW_act.mlapp";
      %! var=$(pgrep -x 'MATLABWindow'); #echo mlw pid: $var; #echo $([ -z $var ]);
      %! [ -z $var ] && open "./mlw_dummy.mlapp" || open "./MLW_act.app"
      %! sh ./mlw_verify.sh
      s=system('sh mlw_verify.sh');
      if s==99
         % worked
         %fprintf('Could switch to MLW\n')
      else
         % not so much
         fprintf('Could NOT switch to MLW!\n');
      end
      
   otherwise
      disp('ML_W_switch: unknown action.')
end

try    cd(olddir)
catch, end
pause(0.25)

