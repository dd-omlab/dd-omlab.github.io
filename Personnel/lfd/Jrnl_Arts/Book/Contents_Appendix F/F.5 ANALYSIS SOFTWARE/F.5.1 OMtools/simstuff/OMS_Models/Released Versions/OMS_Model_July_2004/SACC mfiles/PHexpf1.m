% eFun.m: Used by the PG to determine the pulse amplitude
  
% Written by:  Jonathan Jacobs
%              June 1998  (last mod: 06/02/98)

function out = efun( in )

sgn = sign(in);
in = abs(in);

c(1)=-91.57;
c(2)=92.06;
 
lambda(1)=0.353;
lambda(2)=-0.004782;

numcoeff = length(lambda);

out=0;
for i = 1:numcoeff
   out =  out + c(i)*exp(-lambda(i)*in);
end

out = sgn*out;