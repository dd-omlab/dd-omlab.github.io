function rdlab_batch

pn = uigetdir(pwd, 'Select a data directory');

try
   cd(pn)
catch
   fprintf('Could not change to directory: %s.\n',pn)
   fprintf('Make sure it is valid and does not have a space in its name.\n')
   return
end
temp = dir;

for ii = 1:length(temp)
   if contains(temp(ii).name,'.lab')
      rdlab2(temp(ii).name);
   end
end