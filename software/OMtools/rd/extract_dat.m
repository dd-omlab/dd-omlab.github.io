% extract_dat: Extracts fields from 'rdlab2'-created data and
% saves the fields into the base workspace.
% Possible fields: 
%   Eye position: rh, lh, rv, lv
%   Target pos:   th, tv
%   Everything else: comments, warn, smpf, numpoints

% Written by: Jonathan Jacobs
% Created:    28 Feb 2023

function extract_dat(fn)

if nargin == 0 || isempty(fn)
   [fn, pn] = uigetfile('.mat','Select a .mat file to extract.');
   if fn==0
      fprintf('No file selected. Canceling.\n')
      return
   end
end

% Get filename w/o extension
try
  [fn_root,~] = strtok(fn,'.'); 
catch
   fprintf('Error: could not extract data name from file name.\n')
   return
end

% load data from mat file
try
   dd = open(fullfile(pn,fn));
catch
   fprintf('Error: could not load data. Aborting.\n')
   return
end

% Data will appear as structure field (with name of the data file) in 'dd'.
% This should be the ONLY field in the loaded data.
dd_fields = fields(dd);
switch length(dd_fields)
   case 0
      fprintf('NO DATA IN %s. Aborting.\n',fn_root)
      return
   case 1
      % If the struct has correct name, rename it to 'dd'.
      if strcmpi(dd_fields{1},fn_root)
         dd = dd.(fn_root);
      else
         fprintf('Data field does not match %s. Aborting.\n',fn_root)
      end
   otherwise
      fprintf('Too many fields in %s. Aborting.\n',fn_root);
end


% Assign eye movement channel data into base workspace
try
   rh = dd.rh;
   assignin('base','rh',rh);
   fprintf('rh data placed in base workspace.\n')
catch
   fprintf('"rh" data not present.\n')
end
try
   lh = dd.lh;
   assignin('base','lh',lh);
   fprintf('lh data placed in base workspace.\n')
catch
   fprintf('"lh" data not present.\n')
end
try
   rv = dd.rv;
   assignin('base','rv',rv);
   fprintf('rv data placed in base workspace.\n')
catch
   fprintf('"rv" data not present.\n')
end
try
   lv = dd.lv;
   assignin('base','lv',lv);
   fprintf('lv data placed in base workspace.\n')
catch
   fprintf('"lv" data not present.\n')
end

% Target data
try
   th = dd.th;
   assignin('base','th',th);
   fprintf('th data placed in base workspace.\n')
catch
   fprintf('"th" data not present.\n')
end
try
   tv = dd.tv;
   assignin('base','tv',tv);
   fprintf('tv data placed in base workspace.\n')
catch
   fprintf('tv" data not present.\n')
end

% All the other stuff, too.
try
   t = dd.t;
   assignin('base','t',t);
   fprintf('time vector, t, placed in base workspace.\n')
catch
   fprintf('"t" vector not present.\n')
end

try
   warn = dd.warn;
   assignin('base','warn',warn);
   fprintf('warnings ("warn") placed in base workspace.\n')
catch
   fprintf('No warning messages present.\n')
end

try
   comments = dd.comments;
   assignin('base','comments',comments);
   fprintf('comments placed in base workspace.\n')
catch
   fprintf('No comments present.\n')
end

try
   smpf = dd.smpf;
   assignin('base','smpf',smpf);
   fprintf('sampling frequenct ("smpf") placed in base workspace.\n')
catch
   fprintf('No sampling frequency present.\n')
end

try
   numpoints = dd.points;
   assignin('base','numpoints',numpoints);
   fprintf('numpoints placed in base workspace.\n')
catch
   fprintf('No data length ("numpoints") present.\n')
end

fprintf('"extract_dat" has finished.\n')
end %function extract_dat


%{
% Get filename w/o extension
try
  [fn_root,~] = strtok(fn,'.'); 
catch
   fprintf('Error: could not extract data name from file name.\n')
   return
end

% does it exist in memory?
% copy data
try
   dd = evalin('base',fn_root);     
catch
   fprintf('Could not evaluate filename root.\n')
   keyboard
end
%}


