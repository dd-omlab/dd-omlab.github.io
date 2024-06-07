% getEMD.m: select EM data structure from base memory.
% usage: EMD = getEMD;

% Written by Jonathan Jacobs
% January 2018 (last mod: 07 January 2018)

function [EMD,emd_info] = getEMD(emd_name)

EMD = [];
% check for emData struct in memory. if only one, assume it.
varnames=evalin('base','whos');
cnt=0;
vn_len=length(varnames);
name=cell(vn_len,1);

% look at data already in memory
for i=1:vn_len   
   if strcmpi(varnames(i).class,'emData')
      % no name specified, collect all names
      if nargin==0
         cnt=cnt+1;
         name{cnt}=varnames(i).name;
      else
         if strcmpi( strtok(emd_name,'.'),varnames(i).name )
            %can only have one match
            name{1}=varnames(i).name;
            cnt=1;
            break
         end
      end
   end      
end

if nargin==0
   disp('0) Cancel')
   for i=1:cnt
      disp([num2str(i) ') ' name{i}] )
   end
   which=-1;
   while which<0 || which>cnt
      which=input('Which data do you want to use? ');
   end
   if which==0,disp('Canceled.');return;end
   EMD = evalin('base',name{which});
   cnt = 1;
end

switch cnt
   case 0
      disp(['No data matching ' emd_name ' in memory. '])
      disp('You need to load a file using "rd".')
      EMD=[];
      emd_info = [];
      return
   case 1
      EMD = evalin('base',name{1});
      if nargin==1
      else
         fprintf('%s selected\r',name{1});
      end
   case num2cell(2:100)
      % can we look at candidate paths and match to existing f_info from
      % datstat GUI window UserData properties?
      winH = findwind('EM Data Manager');  % find emdm
      if ishandle(winH)
         f_info = winH.UserData.f_info;
         for i=1:cnt
            for j=1:length(f_info)
               if strcmpi(name{i},f_info(j).filename)
                  EMD = evalin('base',name{i});
                  if strcmpi(EMD.pathname,f_info(j)) % bingo!
                     break
                  end
               end %if strcmpi(name
            end
         end %for i
      end % if ishandle(
end %switch

emd_info.filename = EMD.filename;
emd_info.pathname = EMD.pathname;
emd_info.chan_names = EMD.chan_names;
emd_info.samp_freq = EMD.samp_freq;
emd_info.numsamps = EMD.numsamps;

end % function getEMD

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function winH = findwind(name)
winH = -1;
ch = get(0,'Children');
for i=1:length(ch)
   if strcmpi(ch(i).Name, name)
      winH = ch(i);
      break
   end
end
end %function
