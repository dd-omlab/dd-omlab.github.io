% eFun.m: Used by the PG to determine the pulse amplitude
  
% Written by:  Jonathan Jacobs
%              June 1998  (last mod: 06/02/98)

function out = efun( in )

%%% calculated for output of PGcalc %%%

sgn = sign(in);
in = abs(in);

c(1)=-100.9;
c(2)=103.7;
 
lambda(1)=0.4206;
lambda(2)=-0.003141;

numcoeff = length(lambda);

out=0;
for i = 1:numcoeff
   out =  out + c(i)*exp(-lambda(i)*in);
end

out = sgn*out;