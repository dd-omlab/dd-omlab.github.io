% emcopy: Create a copy of an emData variable.
% This is necessary because simply using an assignment (e.g. emd1 = emd)
% will create a REFERENCE to emd, NOT a unique object.
% By using 'emcopy' we make a new, unique emData variable.

% Written by: Jonathan Jacobs
% Created:    25 Jan 2022

function out = emcopy(in)

out = eval(class(in));
props = properties(in);
for p = 1:length(props)  %copy all public properties
   try   %may fail if property is read-only
      out.(props{p}) = in.(props{p});
   catch
      warning('failed to copy property: %s', props({p}));
   end
end


end %function