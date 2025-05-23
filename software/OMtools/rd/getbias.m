% getbias.m:  % Load the adjustments for the data, either from file or from user input.

% written by: Jonathan Jacobs
%             February 2004 - January 2007 (last mod: 01/31/07)

% 'readbias.m' reads in 'samp_freq' (for ASCII & ASD files), 'chName' and
% 'z_adj' (coil) or 'z_adj', 'max_adj' and 'min_adj' (IR)

% 'rectype' is created in either 'readbias' or 'inputbias'

% let's find the name of the active adjustbias file.  it is one of two possibilities:
% 1) 'adjbias.txt', the original name, left in for historical purposes;
% 2) 'adjbias_' + subject's initials (designator used for data file names) + '.txt'
% priority: #1 will be used if #2 can not be found.
% anything else will be ignored as before, allowing multiple files to be created, but
% only one to be used at a time.

% data file names can be of two forms: xxx#.yyy or xxx#_#.yyy, (where xxx can have
% an underscore in it in addition to the one that is used to separate digits)
% the first case is more common, representing the first series of recordings for a
% particular subject, while the second case represents subsequent recording sessions.

% 'adj_fname' will be used in readbias.m (and possibly elsewhere)

% because the series name might have an underscore in it as well (i.e., underscore
% is not only used to separate series name from trial number, e.g. jbj_vrg1.lab, or
% even worse: jbj_vrg2_1.lab!) we will work BACKWARDS from the end of the filename
% and strip away digits until we reach either an underscore or letters.  If letters,
% we are done.  If an underscore remove it and then we are done.

% tempSampFreq is read from the bias file for asyst, ascii or rawbin formatted files
% tempSampFreq is read directly from file header for labview, ober and rtrv files

%tempfname=shortname;
function [adj_fname,adjbiasvals] = getbias(filename)

global samp_freq

[shortname,~] = strtok(filename,'.');
seriesname = getseriesname(shortname);

numcand = 0;
adjlist = dir('adjbias*');
if isempty(adjlist)
   %disp('No bias file available!')
   adj_fname='no adjbias file found';
   adjbiasvals=[];
   return
end

numfiles = length(adjlist);
adj_cand = cell(numfiles);
orig_adjbiasname=[];
for j = 1:numfiles
   adjfilename = adjlist(j).name;
   if strcmpi(adjfilename,'adjbias.txt')
      orig_adjbiasname=adjfilename;
   end
   adjfilename = strtok(adjfilename,'.');
   [temp,adjfilename] = strtok(adjfilename,'_'); %#ok<STTOK>
   if isempty(adjfilename)
      adjfilename=temp;
   else
      adjfilename = adjfilename(2:end);
   end
   if strfind( lower(shortname),lower(adjfilename) ) == 1
      numcand = numcand + 1;
      adj_cand{numcand} = adjlist(j).name;
   end
end

%[~,c]=size(adj_cand);
if numcand==0 && ~isempty(orig_adjbiasname)
   adj_fname = orig_adjbiasname;
elseif numcand==1
   adj_fname = adj_cand{1};
else
   fprintf('getbias: Multiple adjbias files present.\n');
   fprintf('There can be only one file containing the exact\n')
   fprintf('string "adjbias_%s" in this directory.',shortname);
   showdir;
   return
end

% plan b...
%if ~exist(adj_fname,'file'), adj_fname = 'adjbias.txt'; end

%adjbias_err_flag = 1;
if exist(adj_fname,'file')  && numcand==1 % success will clear the flag.
   % no need to look for another file.
else
   disp(' ')
   disp(' ** No unambiguously named adjbias file found.')   
   s_or_c = input(' ** Do you wish to (s)earch for or (c)reate one? ','s');
   switch s_or_c
      case 's'
         adj_fname = uigetfile('*.*', 'Select an adjbias file');
      case 'c'
         adj_fname = biasgen(seriesname);
      otherwise
         disp('Canceling.')
         adj_fname=[]; adjbiasvals=[];
         return
   end
end

adjbiasvals = readbias(adj_fname,filename,samp_freq);
