function dat=find_loaded_emdm(go)

dat.loaded_data.Items={};

% find all emData sets in base memory
temp=evalin('base','whos');
tlen=length(temp);
dat.loadednames=cell(tlen,1);

% load the f_info struct
cnt=0;
for ii=1:tlen
   if strcmpi(temp(ii).class,'emData')
      if strcmpi(temp(ii).name,'ans');continue;end
      cnt=cnt+1;
      [~,emd_info] = getEMD(temp(ii).name);
      if isempty(emd_info)
         continue
      else
         dat.loadednames{cnt}=temp(ii).name;
         dat.loaded_data.Items{cnt}=dat.loadednames{cnt};
         dat.f_info(cnt).filename=emd_info.filename;
         dat.f_info(cnt).pathname=emd_info.pathname;
         dat.f_info(cnt).samp_freq=emd_info.samp_freq;
         dat.f_info(cnt).cutoff=emd_info.samp_freq/20;
         dat.f_info(cnt).numsamps=emd_info.numsamps;
         dat.f_info(cnt).chan_names=emd_info.chan_names;
      end
   end
end %for ii

if cnt==0
   dat.loadednames={}; 
else
   dat.loadednames=dat.loadednames(1:cnt);
end
%dat.loadednames=~cellfun(@isempty,dat.loadednames);

if nargin==0,   return;end
if isempty(go), return;end

%go.UserData=dat;
if ishandle(go) && strcmp(go.Style,'popupmenu')
   go.String=[dat.loadednames;{'Refresh menu';'Get new data'}];
else
end

end %function update_datalist

