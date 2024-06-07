function omtoolspath = findomtools

% written by:  Jonathan Jacobs
%              February 2011

% Does 'OMtools' folder exist? It can exist in a number of places:
% original location: matlabroot.  No longer a good idea, but will allow it.
% other locations: inside folder containing MATLAB; inside toolbox
% or even in home directory 'MATLAB' folder.

[sep, sep2] = getsep;

oldpath = pwd;
cd(matlabroot)
cd ..
matlabdir = pwd;
home = getenv('HOME');

locations = { 
			     {'matlabdir'}; ...
				  {'matlabroot'}; ...
			     {'matlabroot', 'toolbox'}; ...
			     {'home', 'documents', 'MATLAB'}; ...
			   };

omtf=0;								%% omtools folders found
for j=1:length(locations)
	dir_err=0;
	
   temp=eval(char( locations{j}(1) ));
   if ~exist( temp, 'dir')    
       disp( ['dir_error: ' locations{j}] );
       continue;
   end
   cd(temp)
	
	% if there are subdirectories, navigate to them.
	numsubdir = length(locations{j});
	if numsubdir > 1
		dir_err=0;
		for k=2:numsubdir
			temp=char( locations{j}(k) );
			eval('cd(temp)','dir_err=1;')
		end % for k
	end %if numsubdir
	
	if ~dir_err
		dirfiles = dir;
		for i = 1:length(dirfiles)
			  temp = deblank(lower(dirfiles(i).name));
			if strcmp( temp, 'omtools')
				omtf = omtf+1;
				omtoolspath{omtf} = [pwd sep 'OMtools'];
				%return
			end
		end %for i
	end %if ~dir_err	

end %for j

if omtf < 1
	disp('Could not find the OMtools folder. Make sure it is installed in an appropriate location.')
	disp('Allowed directories are: matlabroot; the folder containing matlabroot; ')
	disp('the MATLAB toolbox folder (against Mathworks rules!!!); ')
	disp('inside your personal MATLAB directory in your home directory.')
	omtoolspath = '';
	return
 elseif omtf == 1
 	omtoolspath = char(omtoolspath{1});
 elseif omtf > 1
   disp('Multiple OMtools folders found:')
   for m = 1:omtf
   	disp( char(omtoolspath{m}) )
   end	
   disp('You should remove or rename all but one of the OMtools folders listed above.')
  	omtoolspath = '';
	return
end	