% getsegs: called by 'vrgcal_apply' and 'vrgcal' to load segments of 
% vergence calibration

% Written by: Jonathan Jacobs
% Created:    Dec 2020

% 04 Feb 2022: Stores segment info for ALL segments, not just angle=0,
%              because 'vrgcal_apply' now applies multiplanar biases to all 
%              data segments, not just explicitly calibrated straight-ahead ones.

function all_segs = getsegs(vcwin,whatChStr,angles)

if ~exist('angles','var')
   angles = 0;
end

% Try to load results.mat for selected data.
try
   csdd=vcwin.UserData.curr_sel_DD;
   [pn,~]=fileparts(csdd.Tag);
   pnfn=fullfile(pn,[csdd.Value '_results.mat']);
   vrg_res=load(pnfn);
   all_segs=vrg_res.all_segs;
catch
   all_segs=struct('rh',[],'lh',[],'rv',[],'lv',[]);
end

% If no channel name, just return what already exists
if ~exist('whatChStr','var')
   %fprintf('\n');
   return
end

try
   ud = vcwin.UserData;
   caldists_str=ud.caldistsStr.Value; %num chars sep by comma &| wspace
   %will str2num work? YES. i bet str2double will barf. IT DID.
   caldists=str2num(caldists_str); %#ok<ST2NM>
   numcaldists=length(caldists);
catch
   fprintf('getsegs: cannot find caldists in GUI!\n');
   return
end

try
   emd=ud.emdata.data;
   pos=emd.(whatChStr).pos;
   fs=emd.samp_freq;
catch
   fprintf('getsegs: could not find "emdata" stored in the "Vergence Cal" app.\n');
   return
end

% Create/modify channel segments
seg=struct('dist',NaN,'angle',NaN,'start',NaN,'stop',NaN);
seg(length(caldists)).dist=NaN;
try
   % Do we already have valid target position?
   tgtpos=vrg_res.ml_tgtpos;
   tstarts=vrg_res.ml_starts;
catch
   % Recreate tgtpos and save vrg_res to _results file
   % find first non-0 tgt change
   ml_tgtpos=vrg_res.tgtpos;
   while(ml_tgtpos(1).led==0)
      ml_tgtpos=ml_tgtpos(2:end);
   end
   % still have to clip off final ('99' entry)
   while(ml_tgtpos(end).led==0)
      ml_tgtpos=ml_tgtpos(1:end-1);
   end
   
   ml_t0 = vrg_res.tgtpos(1).when;
   ml_tgtchanges = [ml_tgtpos.when];
   ml_starts = ml_tgtchanges-ml_t0;
   tstarts = ml_starts;  % convert to secs. orient as column.
   
   % save to ml_results file
   tgtpos=ml_tgtpos;
   vrg_res.ml_tgtpos=ml_tgtpos;
   vrg_res.ml_starts=ml_starts;
   save(pnfn,'-struct','vrg_res');
   fprintf('getsegs has updated %s\n',pnfn);
end

for jj=1:numcaldists
   % Create segments of the EMdata recorded at THIS cal dist. 
   thisdist=caldists(jj);
   seg(jj).dist=thisdist;
   seg(jj).angle=NaN;
   seg(jj).start=NaN;
   seg(jj).startind=NaN;
   seg(jj).stop=NaN;
   seg(jj).stopind=NaN;
   
   % xxx CURRENTLY ONLY FINDING vgr hor pos for 0-deg tgts xxx
   % Find vrg hor pos for ALL angles, but use ONLY 0-deg for performing vergence
   % calibration.
   for tt=1:length(tgtpos) % last tgtpos is LEDs off.
      if tgtpos(tt).distance == thisdist
         if angles == 0
            seg(jj).angle(end+1)=tgtpos(tt).angle;
            % set seg starts
            temp1 = tstarts(tt);
            seg(jj).start(end+1)    = temp1;
            seg(jj).startind(end+1) = fix(temp1*fs);
            % set seg stops
            try    temp2 = tstarts(tt+1)-1/fs;
            catch, temp2 = length(pos)/fs; end
            seg(jj).stop(end+1)=temp2;
            seg(jj).stopind(end+1) = fix(temp2*fs);
         %else
            %
         end
      end
   end
end

all_segs.(whatChStr)=seg;
%seginfo.all_segs = all_segs;