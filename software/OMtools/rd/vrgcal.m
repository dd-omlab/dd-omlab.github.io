% vrgcal.m:  Create an offset (and eventually scale?) calibration for 
% multi-planar VERGENCE data. Called by clicking 'Create Cal' button in
% 'vrgcal_gui'.
% 
%
% Based on 'cal', which is for monoplanar target calibration.
% Uses ZOOMTOOL interactively to set zero point and max/min calibration points.
%
% NOTE: CURRENTLY only finding vergence pos for 0-deg hor targets.

% written by: Jonathan Jacobs
% created   : 12 November 2020
%
% 23 Nov 2020: 1st test release
% 02 Dec 2020: 2nd test
% 08 Dec 2020: Added naso-temporal referencing. Because.
% 04 Feb 2022: Revised call to 'getsegs', explicitly requesting ONLY
%              angle=0 for selecting calibration segments. Required because
%              modified 'getsegs' now allows selecting a specific angle. 

% 'vcwin' is the handle for the 'Vergence Calibration' figure window.
% 'vcapp' is the handle to the 'vrgcal_gui' instance.


function status = vrgcal(vc_app)

global lh rh lv rv lt rt st sv hh hv
global xyCur1Mat xyCur1Ctr samp_freq dataname cur1getH

g=grapconsts; % Let's get colorful! (list of fancy colors and stuff)
ll_clr=g.rgb([g.BRIGHTSUN, g.VIVIDVIOLET, g.RED, g.CORNFLOWER, ...
   g.SUSHI, g.MEDGRAY, g.BLACK]);

status=0;
nt=1; % meaningless?
if ~exist('vc_app','var') || isempty(vc_app)
   %
end

vcwin = findwind('Vergence Calibration');
if ~ishandle(vcwin)
   %fprintf('"vrgcal" requires the "Vergence Calibration" app.\n');
   %fprintf('I will attempt to open it for you. Hang on.\n');
   %fprintf('Opening "Vergence Cal" app...\n');
   vrgcal_gui
   clear status % no return var
   return
end

try
   vcapp = vcwin.RunningAppInstance;
catch
   fprintf('Huh? No running app instance found for this cal window!\n')
   return
end

% Get em data, vrgbias data, tgtpos info that is stored in vcwin.
try
   ud=vcwin.UserData;
   if isempty(ud)
      fprintf('vcwin.UserData is empty!\n');
      return
   end
catch
   fprintf('Cannot find vcwin.UserData!\n');
   return
end

try
   emd=ud.emdata;
   if isempty(emd)
      fprintf('"emdata" from the "Vergence Cal" app is empty.\n');
      return
   end
   %fs=emd.data.samp_freq;
catch
   fprintf('I could not find "emdata" stored in the "Vergence Cal" app.\n');
   return
end

% Check GUI. Can also check _results
try
   vb=ud.vb;
   if isempty(vb)
      fprintf('"vb" from the "Vergence Cal" app is empty.\n');
      return
   end
catch
   fprintf('I could not find "vb" stored in the "Vergence Cal" app.\n');
   return
end

% NOTE: 'Refresh Menu','Get new data' clear all data/results stored in GUI.

% Load _results.mat
has_mlres=0;
has_pores=0;
csdd=vcwin.UserData.curr_sel_DD;
[pn,fn]=fileparts(csdd.Tag);

if contains(fn,'poem')
   po_fn = fn;
   ml_fn = strrep(fn,'_poem','');
else
   ml_fn = fn;
   po_fn = [fn '_poem'];
end
po_pnfn=fullfile(pn,[po_fn '_results.mat']);
ml_pnfn=fullfile(pn,[ml_fn '_results.mat']);

try
   po_res=load(po_pnfn);
   has_pores=1;
catch
   po_res=[];
end

try
   ml_res=load(ml_pnfn);
   has_mlres=1;
catch
   ml_res=[];
end

% Prefer po_res over ml_res??
if has_pores
   vrg_res=po_res;
elseif has_mlres
   vrg_res=ml_res;
else
   fprintf('I cannot find ANY "_results.mat" file!!!\n');
   return
end

% should not be necessary if we use emd from Vergence Cal window.
% Make sure there is data already loaded into the base workspace
if isempty(dataname), dataname='unknown filename'; end
currentfile = lower(deblank(dataname(end,:)));


%% User interaction
% pretty symbols!
deg=char(176); %#ok<NASGU>
pm=char(177);  %#ok<NASGU>
lhColor = 'g';
rhColor = 'b';
hhColor=[0 1 1];
hvColor=[0  0.6  0.6];

% User selects channel to calibrate
disp(['File: ' currentfile])
disp(' 0) --abort--')
if ~isempty(rh), disp(' 1) rh'); end
if ~isempty(lh), disp(' 2) lh'); end
if ~isempty(rv), disp(' 3) rv'); end
if ~isempty(lv), disp(' 4) lv'); end
if ~isempty(rt), disp(' 5) rt'); end
if ~isempty(lt), disp(' 6) lt'); end
if ~isempty(st), disp(' 7) st'); end
if ~isempty(sv), disp(' 8) sv'); end
if ~isempty(hh), disp(' 9) hh'); end
if ~isempty(hv), disp('10) hv'); end

whichCh=-1;
while whichCh<0
   commandwindow
   whichCh = str2double( input('Calibrate which channel? ','s') );
   if isnan(whichCh), whichCh=-1; end
end

% fill "pos", chan&dir names, colors.
switch whichCh
   case 0, disp('Aborted.'), return
   case 1, pos = rh; whatChStr = 'rh'; lcolor = rhColor;
      dir1str = 'rightward'; dir2str = 'leftward';
   case 2, pos = lh; whatChStr = 'lh'; lcolor = lhColor;
      dir1str = 'rightward'; dir2str = 'leftward';
   case 3, pos = rv; whatChStr = 'rv'; lcolor = rhColor;
      dir1str = 'upward'; dir2str = 'downward';
   case 4, pos = lv; whatChStr = 'lv'; lcolor = lhColor;
      dir1str = 'upward'; dir2str = 'downward';
   case 5, pos = rt; whatChStr = 'rt'; lcolor = rhColor;
      dir1str = 'clockwise'; dir2str = 'counter-clockwise';
   case 6, pos = lt; whatChStr = 'lt'; lcolor = lhColor;
      dir1str = 'clockwise'; dir2str = 'counter-clockwise';
   case 7, pos = st; whatChStr = 'st'; lcolor = rhColor;
      dir1str = 'rightward'; dir2str = 'leftward';
   case 8, pos = sv; whatChStr = 'sv'; lcolor = lhColor;
      dir1str = 'upward'; dir2str = 'downward';
   case 9, pos = hh; whatChStr = 'hh'; lcolor = hhColor;
      dir1str = 'rightward'; dir2str = 'leftward';
   case 10, pos = hv; whatChStr = 'hv'; lcolor = hvColor;
      dir1str = 'upward'; dir2str = 'downward';
   otherwise, disp('Invalid selection. Run ''cal'' again.'), return
end

if dir1str();end % eventually will use eccentric pos again
if dir2str();end

if isempty(pos) || all(isnan(pos))
   disp('You have selected an empty data channel. Please run "cal" again.')
   return
end

[len, numCols] = size(pos);
if numCols>len
   pos=pos';
   [~,numCols] = size(pos);
end
t=maket(pos);

% should never see this case (prob), but left in just in case.
if numCols>1
   disp('"vrgcal" can only work on 1-D data, ')
   disp('i.e., a single channel from a single file.')
   return
end


%% Look for calibration distances. Check for GUI
if ishandle(vcwin)
   caldists_str=ud.caldistsStr.Value; %num chars sep by comma &| wspace
   %will str2num work? YES. i bet str2double will barf. IT DID.
   caldists=str2num(caldists_str); %#ok<ST2NM>
   numcaldists=length(caldists);
else
   fprintf('I could not find the "Vergence Cal" window,\n');
   fprintf('or there are no vergence distances set.\n');
   return
end

% Load segs from _results file.
% If there are no segs, create them.
temp=getsegs(vcwin,whatChStr,0); %%%% ONLY FIND SEGS AT ZERO DEG
seg = temp.(whatChStr);
all_segs.(whatChStr) = seg;

ud.all_segs=all_segs;
vrg_res.all_segs=all_segs;


%% Clean data, plot channel, run zoomtool.
if vcapp.UseDeblinkCB.Value==1
   pos = ao_deblink(pos);  % get rid of the worst artifacts
end
%nan_pts = find(isnan(pos)); %#ok<NASGU> % find NaN values in the data

vcfig=figure; calaxis=gca; %#ok<NASGU>
plotH = plot(t,pos,'Color',lcolor);
if exist('st','var')&& ~strcmpi(whatChStr,'st')
   if ~isempty(st), hold on; plot(t,st,'r'); end
end
if exist('sv','var') && ~strcmpi(whatChStr,'sv')
   if ~isempty(sv), hold on; plot(t,sv,'g'); end
end
yData = plotH.YData;
title(nameclean( [currentfile ' -- ' whatChStr ' VRGcal'] ))
zoomtool

% Draw a grey dash-dot line at zero deg.
hold on
lineH = line([0 max(t)],[0 0]);
lineH.Color=[0.6 0.6 0.6];
lineH.LineStyle='-.';


%% Start selecting calibration point values.
% Init zeroing data
z_adjust    = zeros(1,numcaldists);
zeroPtIndex = zeros(1,numcaldists);
zeroPtTime  = zeros(1,numcaldists);

ll=gobjects(numcaldists,1);
txtH=gobjects(numcaldists,1);

for jj=1:numcaldists
   % Operator will select zero point for each dist:
   % Get Cur1's y-pos. Use to SHIFT the data (and axis limits).
   % If we're not happy with the results, then reset to original dat/lims.
   fprintf('Now performing calibration for distance %d \n',seg(jj).dist);
   fprintf('Active at times: %s\n',mat2str(seg(jj).start(2:end)));
   fprintf('         angles: %s\n',mat2str(seg(jj).angle(2:end)));
   
   % Plot an overlay of data taken at this tgt distance.
   possegs=NaN(size(pos));
   for ss=2:length(seg(jj).startind)
      seginds=seg(jj).startind(ss):seg(jj).stopind(ss);
      try
      possegs(seginds)=pos(seginds);
      catch
         keyboard
      end
   end
   ll(jj)=plot(maket(possegs),possegs,'r.');
   ll(jj).Color=ll_clr{jj};
   ll(jj).HitTest='off';
   
   % Interact with user.
   yorn='n';
   while strcmpi(yorn,'n')
      % set plot, lims to original values
      plotH.YData = yData;
      autorange_y(calaxis)
      xyCur1Mat = [];
      xyCur1Ctr = 0;
      cursmatr('cur1_clr')
      disp( ' ' )
      disp( 'Place Cursor ONE on the desired zero point' )
      disp( 'and click the "C1 get" button.')
      waitfor(cur1getH,'String', 'C1 get  (1)' )
      if isempty(xyCur1Mat) % user canceled. (closed zoomtool window?)
         disp('Canceled.')
         return
      end
      z_adjust(jj) = nt * round(xyCur1Mat(xyCur1Ctr,2),3);
      [r1,c1]=size(ll(jj).YData);
      [r2,c2]=size(pos);
      if (r1>c1 && r2>c2) || (r1<c1 && r2<c2)  % same orientation
         % plot adjusted pos 'as-is'
         ll(jj).YData = possegs - z_adjust(jj);
      else
         % plot transposed adjusted pos
         ll(jj).YData = possegs' - z_adjust(jj);
      end
      
      % update the plot and the zoomtool y axis
      zeroPtIndex(jj) = xyCur1Mat(xyCur1Ctr,1);
      zeroPtTime(jj)  = zeroPtIndex(jj)/samp_freq(1);
      autorange_y(calaxis)
      disp('Press ENTER to continue, or "q" to quit');
      commandwindow
      yorn=input('Are you happy with this result (y/n)? ','s');
      switch lower(yorn)
         case 'q'
            disp('quitting'); return
         case 'n'
            ll(jj).YData=ll(jj).YData+z_adjust(jj);
         case 'y'
            ll(jj).MarkerSize=3;
            txtH(jj)=text(zeroPtTime(jj),z_adjust(jj),num2str(seg(jj).dist));
            txtH(jj).Color=ll_clr{jj};
            txtH(jj).FontSize=14;
         otherwise
            %
      end
      
   end %while yorn
   
   % Update stored vb info.
   vb.(whatChStr).chName = whatChStr;
   vb.(whatChStr).vdists = caldists(jj);
   vb.(whatChStr).vzeros = z_adjust(jj);
   disp(['Zero offset: ' num2str(z_adjust(jj)) '   Time index: ' num2str(zeroPtTime(jj))])
end %jj=caldists

% Store in GUI
vcwin.UserData.vb = vb;

% update the VC window _results and save the
% updated info into _results.mat file(s).
if has_pores
   po_res.all_segs=all_segs;
   po_res.vb=vb;
   vcwin.UserData.po_res=po_res;
   save(po_pnfn,'-struct','po_res')
   fprintf('%s updated.\n',po_pnfn);
end

if has_mlres
   ml_res.all_segs=all_segs;
   ml_res.vb=vb;
   vcwin.UserData.ml_res=ml_res;
   save(ml_pnfn,'-struct','ml_res')
   fprintf('%s updated.\n',ml_pnfn);
end

% Barf out some prettyprint
fprintf('/n%s distcal points formatted to paste into "vrgbias.txt":\n',currentfile)
fprintf('%%  %s times: %s\n', whatChStr, mat2str(zeroPtTime) );
fprintf('%s  %s   %s\n\n', whatChStr, mat2str(caldists), mat2str(z_adjust));

return
