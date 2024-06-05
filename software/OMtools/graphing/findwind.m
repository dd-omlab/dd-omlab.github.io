% findwind.m: Search open windows by name.
% Usage: winH = findwin(name,field)
% 'name' is a literal string of the window to search for.
% 'field' is either 'Name' or 'Tag'. If not specified, default is 'Name'.

% Written by:  Jonathan Jacobs
%              September 1997  (last mod: 09/10/97)

% 05 Nov 2020: Changed to 'allchild' so we no longer need to force graphics root
%              to automatically make hidden handles unhidden
% 18 Jun 2020: if 'instring' is a window handle, look for its name

function winH = findwind(instring,field)

winH = -1;

if nargin<1 || isempty(instring)
   %disp('findwind FYI: name was empty')
   return
end
if nargin<2, field='Name'; end

switch lower(field)
   case 'name'
      field='Name';
   case 'tag'
      field='Tag';
   otherwise
      disp('findwind error: field must be either "Name" or "Tag"')
      return
end

if ishandle(instring)
   instring = instring.Name; 
end

%ch_old = get(0,'Children');
ch = allchild(0);
if isempty(ch), return; end

% check the children for the given string
for ii = 1:length(ch)
   %if strcmpi( ch(ii).(field),instring )
   if contains( lower(ch(ii).(field)),lower(instring) )
      winH = ch(ii);
      return
   end
end
