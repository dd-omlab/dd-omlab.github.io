% fprintf2: Sends text to console AND a specified log file.
% 

% Written by: Jonathan Jacobs
% Created:    27 Jan 2021

function arg=fprintf2(varargin)

% fid: 
% varargin: First cell must be sprintf-like string. 
%           Having other cells is optional

% was 'fid' really sent? 
switch nargin
   case 0
      % nothing. will use demo case.
      fid=1;
      fprintf('demo case: ')
      arg=[{'aaa%d%s%d\n'},{11},{'bbb'},{22}];
   otherwise
      if ischar(varargin{1})
         % fprintf string
         fid=1;
         arg=varargin;
      elseif isnumeric(varargin{1})
         fid=varargin{1};
         temp=varargin;
         temp(1)=[];
         arg=temp;
      end
end

% debug
%fprintf('fid: %d\n',fid);
%fprintf('arg:'); disp(arg)

% disp on screen.
printarg(1,arg)
% send to file?
if fid>1
   printarg(fid,arg)
end

if nargout==0
   clear arg
end
end

%%
function printarg(fid,arg)
if nargin ~= 2
   fprintf('fprintf2/printarg requires 2 input arguments.\n')
   keyboard
   return
end

%if isstr(fid)
%   
%end

if length(arg)==1
   try
      fprintf(fid,arg{1});
   catch ME
      if contains(ME.message,'Invalid file identifier')
         fprintf('fprintf2: No file open to print message to.\n')
         %keyboard
         return
      end
   end
else  
   try
      fprintf(fid,arg{1},arg{2:end});
   catch ME
      if contains(ME.message,'Invalid file identifier')
         fprintf('fprintf2: No file open to print message to.\n')
         %keyboard
         return
      end
   end
end

end %function printarg