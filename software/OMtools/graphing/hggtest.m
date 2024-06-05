function overlay = hggtest

figure
overlay = hggroup;
plotax = axes;

x=1:10;
temp = plot(plotax,x,x.^2);
overlay(1) = temp;

temp = text(5,25,'5');
overlay(2) = temp;

%keyboard
end %function hggtest

