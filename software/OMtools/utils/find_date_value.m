function out = find_date_value(in)

%months_long = {'January','February','March','April','May','June', ...
%   'July','August','September','October','November','December'};

months_short = {'Jan','Feb','Mar','Apr','May','Jun', ...
   'Jul','Aug','Sep','Oct','Nov','Dec'};

for ii = 1:length(in)
   in{ii}
   
   % Find year value
   
   
   % Find month value
   for mm = 1:length(months_short)
      if contains(in_str, months_short{mm})
         month_ind = mm;
         break
      end
      fprintf('Could not find month in %s\n',in)
   end
   
   
   % Find date value
   
end

end %function find_latest_date