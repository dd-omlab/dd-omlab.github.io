% findAPPwind: find the app struct containing the experiment's GUI figure.
% Usage: appH = findAPwind(name,field)
% 'name' is a literal string of the window to search for.
% 'field' is either 'Name' or 'Tag'. If not specified, default is 'Name'.

% Written by: Jonathan Jacobs
% Created:    18 Jun 2021

function appH = findAPPwind(instring,field)

if nargin<1 || isempty(instring)
   disp('findwind error: name can not be empty')
   return
end
if nargin<2, field='Name'; end

try
   winH = findwind(instring.Name,field);
catch
   winH = findwind(instring,field);   
end

if ishandle(winH)
   appH = winH.RunningAppInstance;
else
   appH = [];
end

end %function findAPPwind