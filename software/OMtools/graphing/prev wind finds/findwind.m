% findwind.m: Search open windows by name.
% Usage: winH = findwin(name,field)
% 'name' is a literal string of the window to search for.
% 'field' is either 'Name' or 'Tag'. If not specified, default is 'Name'.

% Written by:  Jonathan Jacobs
%              September 1997  (last mod: 09/10/97)

function winH = findwind(instring,field)

winH = -1;

if nargin<1 || isempty(instring)
   disp('findwind error: name can not be empty')
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
