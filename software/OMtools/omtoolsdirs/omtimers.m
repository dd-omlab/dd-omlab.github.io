function omtimers(action)

%persistent omchk_t

if ~exist('action','var')
   action = 'start';
end

omchk_t = omchk_init;

switch action   
   case 'start'
      if ~isa(omchk_t,'timer')         
         start(omchk_t);
         fprintf('"omchk_t" launched\n');
         %mlock
      end      
      if ~isa(omchk_t,'timer')
         %fprintf('"omchk_t" not launched\n');
      end

   case 'stop'
      try
         if isa(omchk_t,'timer')
            try
               stop(omchk_t);
               disp('omchk_t stopped');
            catch
               disp('omchk_t NOT stopped');
            end
         else
            fprintf('no "omchk_t" timer exists\n');
         end
      catch
         fprintf('could not stop omchk_t\n');
      end
      return
      
   case 'delete'
      %munlock
      clear omchk_t
      try
         if isa(omchk_t,'timer')
            stop(omchk_t);
            fprintf('omchk_t stopped and deleted\n');
         else
            fprintf('no "omchk_t" timer exists\n');
         end
      catch
         fprintf('could not stop omchk_t\n');
      end
      %clear checkstimer
      return
      
   otherwise
      %
end
  
end %function checktimers


%%
function omchk_t = omchk_init(action)
omchk_t=timer;
omchk_t.ExecutionMode = 'fixedRate';
omchk_t.Name     = 'omchk_t';
omchk_t.BusyMode = 'queue';
omchk_t.Period   =  5;
omchk_t.TimerFcn = @(~,~)tcheck_shit(action);


end % function omchk_t
%%
function tcheck_shit(varargin)
persistent omchk_t
if exist('omchk_t','var') && isa(omchk_t,'timer')
   mlock
   % Payload
   disp('aaa');
   disp('bbb');
else
   munlock
   fprintf('shit: bad "omchk_t"\n');
   delete omchk_t
   omchk_t = omchk_init;
   mlock
end
end % function checktimersshit
