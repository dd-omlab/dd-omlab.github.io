% omcheck: Make sure current OMtools version is installed.

function status = omcheck

%fprintf('Checking OMtools...\n')

% Find local OMtools install
prevdir=pwd;
[omtoolspath,ot_ver] = findomtools;
if isempty(omtoolspath)
   disp('No OMtools installation found on your path.')
   disp('Try running install_omtools.')
   status=-666;
   return
end

% OMtools_zipped dirs shared on box.com 
boxx_stable_ver='https://app.box.com/s/yv5tznd9r59vbspw68i70vv9zmljlqn4';
boxx_root_ver  ='https://app.box.com/s/n68e0sq0i63p3r1st2a3cs8afcv0somg';
boxx_dev_ver   ='https://app.box.com/s/gnhivg2q1lcnn7nwqb8vn9nto6ug0thr';

fprintf('Local OMtools:   %s ',ot_ver)
disp([' (<a href="matlab: system([''open '' findomtools]);">' ...
   omtoolspath '</a>)'])
%fn = which('omtools_version'); %#ok<UNRCH>
%fp = fileparts(fn);
%a2 = "open" + fp;
%c1 = 'Local <a href="matlab: system('
%c2 = a2;
%c3 = '> OMrecord</a>:  local_ver\n'
%link = sprintf(c1 + c2 + c3)
%fprintf(['Local <a href="matlab: system([''open '' fileparts(which(''omtools_version''))]);">' ...
%   'OMrecord</a>:  ' local_ver '\n']);

for branch=2:3
   switch branch
      case 1
         boxx_ver = boxx_root_ver;
         bstr='main';
      case 2
         boxx_ver = boxx_stable_ver;
         bstr='stable ';
         %continue
      case 3
         boxx_ver = boxx_dev_ver;
         bstr='develop';
      otherwise
         keyboard
   end
   
   % Find the string "latest_version" in Box response.
   % Latest version date will be in the file name.
   try
      options=weboptions('Timeout',10);
      response=webread(boxx_ver,options);
      temp0=strfind(response,'latest_version');
      temp1=temp0(temp0(1)~='.');
      if isempty(temp1)
         cloud_ver='I could not find a "latest_version" text file on the server!';
      else
         temp2=strfind(response(temp1:temp1+100),'",');         
         try
            temp2=temp2(1);
            response=response(temp1:temp1+temp2);
            temp1=strfind(response,'--');
            temp2=strfind(response,'.txt');
            temp3=response(temp1+2:temp2-1);
            if isempty(temp3)
               cloud_ver='I could not detect a version in the "latest_version" file!';
            else
               while(strcmpi(temp3(1),' '))
                  temp3(1)='';
               end
               cloud_ver=temp3;
            end
         catch
            %status=0;
         end
      end
      status=0;        % cloud version exists
   catch
      cloud_ver='I could not contact the server!';
      status=-999;
   end
   
   if ~strcmpi(ot_ver,cloud_ver)
      fprintf(' %s branch: <a href="%s">%s</a>\n',bstr,boxx_ver,cloud_ver)
   else
      fprintf(' %s branch: <a href="%s">%s</a>',bstr,boxx_ver,cloud_ver)
      fprintf('  (You are up to date)\n')
      status=1;
   end   
end


try    
   cd(prevdir)
catch
   fprintf('Could not return to previous dir: %s\n',prevdir);
   cd(findomtools); 
end

end % function