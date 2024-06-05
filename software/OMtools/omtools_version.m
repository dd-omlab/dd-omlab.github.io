% omtools_version: how old am I now?
% I must change the otver string when I update OMtools

% Written by: Jonathan Jacobs
%             12 Oct 2020
%

function otver = omtools_version

verstr = '05 Apr 2024';

if nargout==0
   fprintf('OMtools version: %s\n',verstr)
   clear otver
   return
end

otver = verstr;
