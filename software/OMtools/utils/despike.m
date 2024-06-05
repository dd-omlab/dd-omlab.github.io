function out = despike(in,lvl,smear)

% Knock out noise spikes without introducing time delay.
if nargin<2, lvl=5; smear=10; end

out=in;

d1=d2pt(in,3);
d2=d2pt(d1,3);

badpts=find(abs(d2)>lvl*std(d2));

for ii=1:smear
   temp1=badpts-ii;
   temp2=badpts+ii;
   temp3=union(temp1,temp2);
   badpts=union(badpts,temp3);
   badpts(badpts<1)=1;
end

out(badpts)=NaN;


end %function despike
