% rdlab2: read data using rdlab, organize and save to workspace and disk

% Written by: Jonathan Jacobs
% Created:    20 Feb 2023


function out = rdlab2(in)

%autorename = 1;
 
 if nargin==0 || isempty(in)
   %showfigs = 0;
else
   filename = in;
end
 
% Initialize outputs 
out=struct();
warn = {'';'';'';'';'';'';'';''};
lh =[]; lv=[];
rh =[]; rv=[];

% Load data
rdlab

% Look for eye channels
if ~exist('lh','var') || isempty(lh) %#ok<*NODEF>
   warn{1} = 'No lh data found.';
   fprintf('%s\n',warn{1})
   lh = [];
end
if ~exist('rh','var') || isempty(rh)
   warn{2} = 'No rh data found.';
   fprintf('%s\n',warn{2})
   rh = [];
end
if ~exist('lv','var') || isempty(lv)
   warn{3} = 'No lv data found.';
   fprintf('%s\n',warn{3})
   lv = [];
end
if ~exist('rv','var') || isempty(rv)
   warn{4} = 'No rv data found.';
   fprintf('%s\n',warn{4})
   rv = [];
end

% assume chair, xy, proj unused?
%

if ~isempty(rh)
   t = maket(rh,smpf);
elseif ~isempty(lh)
   t = maket(lh,smpf);
else
   fprintf('Both rh and lh are empty! Cannot create a time vector.\n')
   fprintf('Using t from original data. Beware it might not be the.\n')
   fprintf('same length as the data vectors.\n')
end

out.lh = lh;
out.lv = lv;
out.rh = rh;
out.rv = rv;
out.th = th;
out.tv = tv;
out.t = t;

out.warn =  warn;
out.comments = comments;
out.smpf = smpf;
out.points = points;

% Copy 'out' to subject name/number
[~,fn,~] = fileparts(filename);
try
  eval([fn ' = out;']);
catch
   fprintf('I could not name the output as %s\n',fn);
end

try
   assignin('base',fn,out)
   fprintf('Data saved to workspace as %s\n',fn);
catch
   fprintf('I could not place the data in the base workspace.\n');
end

% Save .mat file with data
try
   save([fn '.mat'], fn);
   fprintf('Saving the data as %s.mat\n',fn);
catch
   fprintf('I could not save the data as %s.mat\n',fn);
end

%keyboard

end %function rdlab2



% maket.m: make a time vector for the given array.
% usage: t = maket(inArray, sample frequency);

% Written by: Jonathan Jacobs
%             February 1997 - April 1998 (last mod: 04/02/98)

function  t_vect = maket(inArray, samp_vect)
global samp_freq

if nargin == 0
   help maket
   return
end

if nargin == 1
   samp_vect = samp_freq;
   if (isempty(samp_vect)) || (samp_vect == 0)
      while (isempty(samp_vect)) || (samp_vect == 0)
         samp_vect = input( 'Enter the sampling frequency: ');
      end
   end
end

numDPts = max(size(inArray));
t_vect = (1:numDPts)'/samp_vect(1);

end %function maket

%{
% If it seems like there is uniocular data, verify
do_rename = 1;  %% default. Can change to 0 if desired

if (isempty(lh) && isempty(lv)) && (~isempty(rh) && ~isempty(rv) )
   fprintf('LE data is empty, but RE data is not.\n')
   if autorename == 0
      yorn = input('Should I rename rv data to lh (y/n)? ','s');
      if ~strcmpi(yorn,'y')
         do_rename = 0;
      else
         do_rename = 1;
      end
   end
   if do_rename == 1
      warn{5} = 'Renaming rv data as lh.\n';
      lh = rv;
      lv = [];
   else
      warn{5} = 'NOT renaming rv data as lh.\n';
   end
   fprintf('%s\n',warn{5});
end

if (isempty(rh) && isempty(rv)) && (~isempty(lh) && ~isempty(lv) )
   fprintf('RE data is empty, but LE data is not.\n')
   if autorename == 0
      yorn = input('Should I rename lv data as rh (y/n)? ','s');
      if ~strcmpi(yorn,'y')
         do_rename = 0;
      else
         do_rename = 1;
      end
   end
   if do_rename == 1
      warn{5} = 'Renaming lv data as rh.\n';
      lh = rv;
      rv = [];
   else
      warn{5} = 'NOT renaming lv data as rh.\n';
   end
   fprintf('%s\n',warn{5});
end
%}

