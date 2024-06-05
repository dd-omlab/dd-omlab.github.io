% function: out = getTime(in1,in2)
% Return the current system time (using 'tic'), expresssed in units of
% seconds, milliseconds, microseconds, and nanoseconds. 
% Does anybody really know what time it is?
%
% with NO arguments:  just returns the current system clock.
% with ONE argument:  tests 'pause(0.5)' accuracy
% with TWO arguments: calculate the time between in1 and in2 (results of
%    previous calls to 'getTime').
% out fields: 'sec', 'msec', 'usec', 'nsec' : double (good for calcs)
%    'seci', 'mseci', 'useci', 'nseci' : int64 (prettier display)
%
% Written by: Jonathan Jacobs
% Created:    22 May 2021


function out=getTime(in1,in2)

if nargin==0
   test=0;
   a=tic;
   aa=double(a);
elseif nargin==1
   test=in1;
elseif nargin==2
   out=getTdiff(in1,in2);
   return
end

sec1  = 1e+9;
msec1 = 1e+6;
usec1 = 1e+3;
nsec1 = 1;

if test==0  
   %a=tic;
   %aa=double(a);
   %disp( (aa-zz)/msec1 )
   out.seci  = a/sec1;
   out.mseci = a/msec1;
   out.useci = a/usec1;
   out.nseci = a/nsec1;   
   out.sec  = aa/sec1;
   out.msec = aa/msec1;
   out.usec = aa/usec1;
   out.nsec = aa/nsec1;   
elseif test==1
   a = double(tic); pause(0.5); b = double(tic);
   fprintf('wait(0.5):\n');
   fprintf('   sec: %.1f\n', (b-a)/sec1);
   fprintf('  msec: %.1f\n', (b-a)/msec1);
   fprintf('  usec: %.1f\n', (b-a)/usec1);
   fprintf('  nsec: %.1f\n', (b-a)/nsec1);
end

end % function getTime

%%
function out=getTdiff(a,b)
out.seci  = int64(b.sec - a.sec);
out.mseci = int64(b.msec - a.msec);
out.useci = int64(b.usec - a.usec);
out.nseci = int64(b.nsec - a.nsec);
out.sec  = double(b.sec)  - double(a.sec);
out.msec = double(b.msec) - double(a.msec);
out.usec = double(b.usec) - double(a.usec);
out.nsec = double(b.nsec) - double(a.nsec);
end

%try
%   test=in;
%catch
%   test=0;
%end


