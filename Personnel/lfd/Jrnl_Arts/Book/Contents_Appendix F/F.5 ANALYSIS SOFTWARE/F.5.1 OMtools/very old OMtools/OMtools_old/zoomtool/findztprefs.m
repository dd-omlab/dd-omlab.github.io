function ztprefpath = findztprefs

% written by:  Jonathan Jacobs
%              February 2011

[sep, sep2] = getsep;

% Doesomprefs folder exist?  If it does, use zt preferences saved loose in omprefs folder.
% If it does not exist, use 'findztprefs' and use ztprefs folder in zoomtool folder.
% if there is no 'ztprefs' folder, create one in the zoomtools folder.

if exist('omprefs','file') == 2
	cd(findomprefs)
    ztprefpath=findomprefs;
	return
end

oldpath = pwd;
cd(matlabroot)
cd ..
matlabdir = pwd;
home = getenv('HOME');

% known locations for zoomtool prefs on OS X as of ML2010b
locations = {
              {'matlabdir', 'omtools', 'zoomtool'}; ...
				  {'matlabroot', 'omtools', 'zoomtool'}; ...
				  {'matlabroot', 'toolbox', 'omtools', 'zoomtool'}; ...
			     {'home', 'documents', 'MATLAB', 'omtools', 'zoomtool'}; ...
			   };

ztf=0; ztpf=0;             %% zoomtool folders found, ztprefs folders found
for j=1:length(locations)
	dir_err=0;
	temp=eval(char( locations{j}(1) ));
   if ~exist( temp, 'dir')    
       disp( ['dir_error: ' locations{j}] );
       continue;
   end
   cd(temp)
	
	% if there are given subdirectories, navigate to them.
	numsubdir = length(locations{j});
	if numsubdir > 1
		dir_err=0;
		for k=2:numsubdir
			temp=char( locations{j}(k) );
			eval('cd(temp)','dir_err=1;')
		end % for k
	end %if numsubdir
	
	if ~dir_err   %% we have found a valid zoomtools folder
	   ztf = ztf+1;
	   ztpath{ztf} = pwd;
		dirfiles = dir;
		for i = 1:length(dirfiles)
			  temp = lower( deblank(dirfiles(i).name) );
			if strcmp( temp, 'ztprefs')				%% we have found a valid zt prefs folder
				ztpf = ztpf+1;
				ztprefpath{ztpf} = [pwd sep 'ztprefs'];				
				%return
			end
		end %for i
	end %if ~dir_err	

end %for j

if ztpf<1
	disp('Could not find any zoomtool prefs location. ')
	disp('I will create the folder ''ztprefs'' in the zoomtool folder. ')
	if ztf == 1 % unlikely that ztf=0 since we are running a program from zoomtool
		ztpath = char(ztpath{1});
		cd(ztpath)
		mkdir('ztprefs')
		ztprefpath = [ztpath sep 'ztprefs'];
		cd('ztprefs')
	  elseif ztf > 1
	   ztprefpath = '';
	   disp('Multiple zoomtool folders found. You should only have one zoomtool folder')
	   disp('on your MATLAB path. Please remove or rename all redundant zoomtool folders.')
	   error('Cannot save zoomtool preferences. Aborting.')
	end
 elseif ztpf == 1
 	ztprefpath = char(ztprefpath{1});
 elseif ztpf >1
   disp('Multiple zoomtool pref locations found:')
   for m=1:ztpf
   	disp( [ num2str(m) ':  ' char(ztprefpath{m}) ] )
   end
   %% which zt dir to prefer?
   m=0;
   while(m<1 | m>ztpf)
   	m = input('Which zoomtool preferences folder should I use? ("0" to abort.)');
   end
   ztprefpath = char(ztprefpath{m});
end	