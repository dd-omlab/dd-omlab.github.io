% This is a basic script to start OMtools and the OMrecord toolbox.
% It can be used as a startup script on its own, by naming it "startup.m" and
% placing it in your local MATLAB folder (usually in the "Documents" folder of
% your home directory).
%
% If you already have a startup script, you can name this file as omtools_startup.m,
% and add a call to it in your current startup.

%fprintf('Startup disabled. Type "edit startup" & comment out these two lines.\n')
%return

try
   omstart
catch err
   fprintf('omstart has failed to run because: ');
   if strcmp(err.identifier,'MATLAB:UndefinedFunction')
      disp('MATLAB cannot find "omstart.m".');
      disp('Check MATLAB path (type "pathtool") for lines containing "OMtools"')
      disp('There should be about a dozen or so.');
      pathtool
      commandwindow
      disp('Try this: ')
      disp('change MATLAB directory to OMtools/omtoolsdirs.')
      disp('Run ompath(''clear'') and then run ompath(''set'') ')
      disp('Open/refresh pathtool again and verify that they have been added.')
   else
      fprintf('let''s find out why. Dropping into debug mode.\n');
      keyboard
   end
   return
end

try
   omrecstart
catch err
   if contains(err.message,'Unrecognized function') && ...
         contains(err.message,'omrecstart')      
      fprintf('Could not run "omrecstart" in "OMrecord" toolbox.\n')
      fprintf('Make sure the toolbox is on your path.\n')      
   end
end

fprintf('\nOMtools is ready.\n')

% Go to your home MATLAB directory
try
   cd(findomtools)
   cd ..
catch
   fprintf('Could not find the OMtools directory!\n');
end

%restoredefaultpath
%rehash toolboxcache

