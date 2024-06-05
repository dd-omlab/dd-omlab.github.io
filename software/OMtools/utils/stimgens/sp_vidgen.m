% sp_vidgen: create video file of SP targets composed of
% point-by-point vectors of x,y position
%
% Written by:  Jonathan Jacobs
%              last mod:  03/02/21)
%
% Stim file entries should follow these templates:
% lin	 vel x0 y0 xr yr color
% sin  dur x0 y0 xr yr afreq color
% circ dur x0 y0 xr yr afreq color angle rotdir 

function sp_vidgen(dist_to_subj,mirror)

% REMEMBER TO ADD DIST TO MIRROR TO DIST TO SUBJ
if ~exist('stimfile','var'),     stimfile = []; end
if ~exist('dist_to_subj','var'), dist_to_subj=500; end
if ~exist('mirror','var'),       mirror=0; end

%% what screens are available for making the movie?
temp = get(0);
mon_pos = temp.MonitorPositions;
[numscreens,~] = size(mon_pos);
fprintf('Local screen dimensions\n')
sXoff=NaN*ones(numscreens,1);  sYoff=NaN*ones(numscreens,1);
swid=NaN*ones(numscreens,1);   shgt=NaN*ones(numscreens,1);

for jj=1:numscreens
   sXoff(jj) = mon_pos(jj,1);
   sYoff(jj) = mon_pos(jj,2);
   swid(jj)  = mon_pos(jj,3);
   shgt(jj)  = mon_pos(jj,4);
   fprintf('Screen %d: %d by %d pixels\n',jj,swid(jj),shgt(jj))
end

whichmon=1;
if numscreens>1
   whichmon = 2;
   %whichmon = -1;
   fprintf('Make the movie on which monitor?\n')
   while whichmon<0 || whichmon>numscreens
      whichmon=input('--> ');
   end
end
monXO = sXoff(whichmon);   monYO = sYoff(whichmon);
monWid = swid(whichmon);   monUsableHgt = shgt(whichmon);

%% What screen will the movie be played on?
% What are its physical and display dimensions?
% Use these values to calculate how many degrees the monitor spans
% and how many pixels equal one degree.
tgtmon = 7;
%tgtmon = -1;
qstr='\nWhat screen do you want the movie to play on? ("0" to cancel)\n';
monstr={
   '1. Apple Cinema HD          (1920 x 1200 pix; 490 x 310 mm)\n',...
   '2. SyncMaster 2443          (1920 x 1200 pix; 517 x 325 mm)\n',...
   '3. Monoprice 28" 4K HDI     (2560 x 1440 pix; 620 x 340 mm)\n',...
   '4. iMac 5K, 27"             (2560 x 1440 pix; 593 x 336 mm)\n',...
   '5. Retina Macbook Pro 2015  (1440 x  900 pix; 331 x 208 mm)\n',...
   '6. iPad Air (mirroring MBP) (1440 x  900 pix; 197 x 123 mm)\n',...
   '7. iPad Air (native HDI)    (1024 x  768 pix; 197 x 147 mm)\n',...
   '8. BenQ                     (1920 x 1080 pix; 503 x 300 mm)\n',...
};
fprintf(qstr);
for zz=1:length(monstr),fprintf(monstr{zz});end
while tgtmon<0 || tgtmon>8
   tgtmon=input('--> ');
end

% Monitors' actual DISPLAYABLE screen sizes in MILLIMETERS.
switch tgtmon
   case 1
      % Apple Cinema HD dimensions.
      scr_pix_wid = 1920; scr_pix_hgt = 1200;  % PIXELS
      scr_phys_wid = 490; scr_phys_hgt = 310;  % MILLIMETERS
   case 2
      % SyncMaster 2443.
      scr_pix_wid = 1920; scr_pix_hgt = 1200;  % PIXELS
      scr_phys_wid = 517; scr_phys_hgt = 325;  % MILLIMETERS
   case 3
      % Monoprice 28" 4K
      scr_pix_wid = 2560; scr_pix_hgt = 1440;  % PIXELS
      scr_phys_wid = 620; scr_phys_hgt = 340;  % MILLIMETERS
   case 4
      % iMac 5K, 28"
      scr_pix_wid = 1440; scr_pix_hgt =  900;  % PIXELS
      scr_phys_wid = 593; scr_phys_hgt = 336;  % MILLIMETERS
   case 5
      % Retina MacBook Pro 15"
      scr_pix_wid = 1440; scr_pix_hgt =  900;  % PIXELS
      scr_phys_wid = 331; scr_phys_hgt = 208;  % MILLIMETERS
   case 6
      % iPad Air, when MIRRORING rMBP15 (ignoring pixel doubling)
      scr_pix_wid = 1440; scr_pix_hgt =  900;  % PIXELS
      scr_phys_wid = 197; scr_phys_hgt = 123;  % MILLIMETERS
   case 7
      % iPad Air, native (ignoring pixel doubling)
      scr_pix_wid = 1024; scr_pix_hgt =  768;  % PIXELS
      scr_phys_wid = 197; scr_phys_hgt = 148;  % MILLIMETERS
   case 8
      % BenQ
      scr_pix_wid = 1920; scr_pix_hgt = 1080;  % PIXELS
      scr_phys_wid = 503; scr_phys_hgt = 300;  % MILLIMETERS
   otherwise
      fprintf('Canceled\n')
      return
end

% ML titlebar + OS X menubar + large dock: 22+22+96=140 pixels
% Solution: HIDE dock and menubar while making movie.
mov_pix_hgt = scr_pix_hgt;
mov_pix_wid = scr_pix_wid;
%menu_hgt=23;
tbar_hgt = 22;
wasted_hgt = tbar_hgt;
monUsableHgt = monUsableHgt-wasted_hgt;

%aspect ratio of the ultimate target screen

if ismac
   %[pn,~,~]=fileparts(mfilename('fullpath'));
   %cmdstr=sprintf('osascript %s/toggle_mb_dock.scpt',pn);
   %system(cmdstr)
end

% If at all possible, try to create the movie on a screen that is at least
% as large as the screen it will be played on. Otherwise we need to scale
% the movie size so it can be created with the proper aspect ratio.
scale=1.0;
if mov_pix_wid>monWid || mov_pix_hgt>monUsableHgt
   fprintf('Movie dimension(s) are larger than local rendering screen.\n')
   %disp('add some details about sizes options here?')
   fprintf('0. Cancel.\n')
   fprintf('1. Scale the movie down to fit the rendering screen.\n')
   choice=-1;
   while choice<0 || choice>1
      choice=input(' -> ');
   end
   switch choice
      case 0
         fprintf('Canceled\n')
         return
      case 1
         scale=min( monWid/mov_pix_wid, monUsableHgt/mov_pix_hgt );
         scale=scale*0.9;
         fprintf('Downscaled by %d\n',scale);
         %offer chance to manually set scaling?
   end
end

%aspect = scr_pix_wid / scr_pix_hgt;
mov_pix_wid = scale * mov_pix_wid;
mov_pix_hgt = scale * mov_pix_hgt;

% geometry is our friend. When we do it correctly.
% at distance D from the screen, what are dimensions in DEGREES?
temp = atan((scr_phys_wid*0.5)/dist_to_subj); % in RADIANS
half_alpha_hor = temp*180/pi; % degrees
temp = atan((scr_phys_hgt*0.5)/dist_to_subj); % in RADIANS
half_alpha_vrt = temp*180/pi; % degrees

% use these values to convert between MOVIE pixels and degrees
hpix_per_deg = mov_pix_wid/(2*half_alpha_hor);
vpix_per_deg = mov_pix_hgt/(2*half_alpha_vrt);


%%
if isempty(stimfile)
   fprintf('\nSelect a stimulus text file:\n')
   [stimfile,stimpath] = uigetfile('*.txt','Select a stimulus text file');
   if stimfile==0, fprintf('Canceled\n'); return; end
   cd(stimpath)
end
targets = read_spvgen(stimfile);

% Set appropriate frame rate.
% Each stim element can have unique duration. Find lowest common mult
% of all instantaneous frame rates: 'frate = lcm(sym( 1./listdur ));'
% Works, but 'sym' is from symbolic toolbox. Can't assume it's present.
% So why not write our own semi-symbolic lcm that handles vects, and
% as a bonus, non-integer values...
listdur = NaN(size(targets));
for ii=1:length(targets)
   listdur(ii)=targets{ii}.dur;
end
moviedur   = sum(listdur);
%frate      = lcmvect( 1./listdur );
frate=50;
tgtframes = round(frate .* listdur); % # frames for each stimulus.

% can save each frame as its own image file, and also directly as AVI
fprintf('\nSave the stimulus image/movie as:\n');
[filename, pathname] = uiputfile( {'*.jpg';'*.png';'*.pdf';'*.tiff';'*.bmp'}, ...
   'Save the stimulus movie as: ');
if filename==0, fprintf('Cancelled\n'); return;end

[filename, ~] = strtok(filename,'.');
cd(pathname)

% center the movie on the rendering screen
movXO = monXO + abs(mov_pix_wid - monWid)/2;
movYO = monYO + abs(mov_pix_hgt - monUsableHgt)/2;
fig = figure;
fig.Position=[movXO, movYO, mov_pix_wid, mov_pix_hgt];
fig.Color=[0 0 0];
fig.MenuBar='none';
fig.Units='normalized';
%fig.Position=[(1-scale)/2, (1-scale)/2, scale, scale];
fig.PaperPositionMode='auto';
fig.InvertHardcopy='off';
fig.Units='pixels';

ax = gca;
ax.Units='normalized';
%ax.OuterPosition=[0 0 1 1];
ax.Position=[0 0 1 1];
box off; hold on
axis off; axis equal tight
ax.Units='pixels';
ax.XLim=[-mov_pix_wid/2, mov_pix_wid/2];
ax.YLim=[-mov_pix_hgt/2, mov_pix_hgt/2];

% Create movie file
profile='MPEG-4';
%profile='Motion JPEG AVI';
%profile='Motion JPEG 2000';
stim_mov = VideoWriter( [pathname filename],profile);
stim_mov.FrameRate = frate;
stim_mov.Quality = 100;
open(stim_mov)


%% Create stimuli, draw and capture the frames
% Add an extra frame to the front bec Experiment Builder appears to skip
% the first frame when playing movie
F = getframe;
writeVideo(stim_mov, F);

h.window  = [];
h.white   = [1 1 1];
h.bg_clr  = [0 0 0];

renderstart=tic;
for k = 1:length(targets)   
   thistgt = targets{k};
   t_type  = thistgt.t_type;
   dur = thistgt.dur;
   x0 = thistgt.x0;
   xr = thistgt.xr;
   y0 = thistgt.y0;
   yr = thistgt.yr;
   h.color = thistgt.color;
   
   % create the x,y points for this tgt
   switch t_type
      case {'circ','sin'}
         afreq = thistgt.afreq;
         rot = thistgt.rot;         
         %angle = thistgt.angle;         
         tgtvect=sp_sin_tgt2D(h, t_type,dur,[x0,y0],[xr,yr],afreq,frate,rot);         
         
      case 'lin'
         vel = thistgt.vel;
         tgtvect=sp_lin_tgt2D(h, [x0 y0],[xr yr],vel,frate);
      otherwise
         %
   end % switch t_type

   % Convert x,y from deg to pix.
   x = tgtvect.x * hpix_per_deg;
   y = tgtvect.y * vpix_per_deg;
   x0 = x0 * hpix_per_deg;
   y0 = y0 * vpix_per_deg;   
   
   ll=plot(x0,y0,h.color);
   ll.LineStyle='none';
   ll.Marker='o';
   ll.MarkerSize=12;
   ll.MarkerFaceColor=h.color;
   
   for ii=1:tgtframes(k)
      ll.XData = x(ii);
      ll.YData = y(ii);
      F = getframe;
      if mirror
         F.cdata = fliplr(F.cdata);
      end
      writeVideo(stim_mov,F);
      % commented to disable saving individual frames as separate files
      %print( [filename '_' num2str(temp) ext], '-djpeg', '-r0' )      
      %saveas(fig, [filename '_' num2str(k) ext] )
   end
   delete(ll)
end
renderdur = toc(renderstart);

%%
fprintf('\nMovie %s saved in %s. Dur: %d sec. Frame rate: %d\n',...
   filename,pwd,moviedur,frate);
fprintf('Time to make movie: %.3f secs\n', renderdur);

%if ismac,system(cmdstr);end
close(stim_mov)
close(fig)
