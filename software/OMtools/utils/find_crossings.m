% find_crossings: detect time indices in an input vector when the values
% cross a given threshold.
% Call with NO arguments to see a simple demo.
%
% Usage: 
%   crossings = find_crossings(in,thresh,debug)
% where:
%  - in is a 1D vector of real values
%  - thresh is a real value (default = 0)
%  - debug is a boolean. If true, a graph will be plotted showing exact
%      matches and threshold crossing events plotted over the input data.
%  - crossings is a structure with fields:
%      exact: when in is EXACTLY thresh
%      below: the index just before in crosses above thresh 
%      above: the index just after in crosses above thresh 
%      ind:   whichever of in(below) or in(above) is closest to thresh

% Written by: Jonathan Jacobs
% Created:    19 July 2022


function crossings = find_crossings(in,thresh,debug)


if ~exist('in','var')
   %fprintf('No input data detected. Quitting.\n');
   %return
   in = [];
end

if isempty(in)
   in = [-1 0 3 3 4 5 2 -10 -9 -14 -1 4 5 10];
end

if ~exist('debug','var')
   debug = false;
else
   debug = boolean(debug);
end

if nargin==0
   debug = boolean(true);
end

crossings = struct('exact',[],'below',[],'above',[]);

if ~exist('thresh','var')
   thresh=0;
end

%debug = true;
if debug
   figure; gca; box; hold on
   plot(in,'-g','Marker','*')
   plot([0 length(in)],[0 0])
   xlabel('Sample index')
   ylabel('Sample value')
   title('o: exact match, x: closest value to thresh')
end


% Thresh crossing occurs:
% when is exactly thresh 
% between successve points that change between above and below thresh
%    choose point whose value is CLOSEST to thresh.

crossings.exact = find(in == thresh);
if debug
   %fprintf('Found %d points that were EXACTLY %d\n', ...
   %   length(crossings.exact),thresh);
   plot(crossings.exact,in(crossings.exact),'bo')
   xplot = plot(NaN,NaN,'rx');
end

% Create time-shifted-by-1 version of in (y-shifted so thresh = 0)
% for element-by-element comparison of sign of input values.
in_t  = in - thresh;
in_t1 = [in_t(1) in_t(1:end-1)];

% Where do the signs differ? (Ignoring times when in is exactly thresh.)
c_start = find( sign(in_t) ~= sign(in_t1) & ...
   sign(in_t)~=0 & sign(in_t1)~=0 );
c_start = c_start - 1;


% Find indices of sample just BELOW thresh, and just ABOVE thresh.
for ii = 1:length(c_start)

   if abs(in(c_start(ii))) <= abs(in(c_start(ii)+1))
      crossings.below(ii) = c_start(ii);
      crossings.above(ii) = c_start(ii)+1;
   else
      crossings.below(ii) = c_start(ii)+1;
      crossings.above(ii) = c_start(ii);
   end
   
   % Use the index for the value that is CLOSEST to thresh
   if abs(in(crossings.below(ii))-thresh) <= ...
         abs(in(crossings.above(ii))-thresh)
      crossings.ind(ii) = crossings.below(ii);      
   else
      crossings.ind(ii) = crossings.above(ii);      
   end
   
   % Update list of crossing indices in plotted figure.
   if debug
      xplot.XData(ii) = crossings.ind(ii);
      xplot.YData(ii) = in(crossings.ind(ii));
   end
end

end %function find_crossings