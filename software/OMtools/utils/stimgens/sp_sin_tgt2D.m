function tgtvect=sp_sin_tgt2D(h, stype,dur,startpt,endpt,afreq,fps,rotdir)

% startpt,endpt are (x,y) degrees
% afreq is angular frequency of sinusoid
% dur in secs

try    h.window;
catch, h.window=[]; end

if isempty(h)      % testing condition
   h.window  = [];
   h.tgt_rad = 1;
   h.white   = [1 1 1];
   h.bg_clr  = [0 0 0];
end

tgtvect=[];
if ~exist('fps','var'),fps=50;end
if ~exist('dur','var'),dur=1;end
if ~exist('afreq','var'),afreq=1;end
if ~exist('rotdir','var'),rotdir=1;end
%if ~exist('timed','var'),timed=0;end

x0 = startpt(1);
y0 = startpt(2);
deltax = endpt(1)-startpt(1);
deltay = endpt(2)-startpt(2);

% SINUSOID (+ circle? change y to cos)
numframes = fix(dur*fps);
fpc = fps/afreq;   % frames per cycle
allpts = 2*pi*(1:numframes)/fpc;

t = (1:numframes) * 1/fps;
switch stype
   case {'sin','sine'}
      x = deltax*sin(allpts) + x0;
      y = deltay*sin(allpts) + y0;
   case {'circ','circle'}
      x = deltax*cos(allpts) + x0;
      rotdir=rotdir/abs(rotdir);      
      y = rotdir*deltay*sin(allpts) + y0;
   otherwise
      fprintf('sp_sin_tgt2D: Unknown type\n')
      return
end

r = sqrt(x.^2+y.^2); % total distance

tgtvect.dur = dur;
tgtvect.fps = fps;
tgtvect.fdur = 1/fps;
tgtvect.numframes = numframes;
tgtvect.afreq = afreq;
tgtvect.numcycles = dur*afreq;
tgtvect.fpc = fpc;
tgtvect.t0 = GetMSecs;
tgtvect.x0 = x0;
tgtvect.y0 = y0;
tgtvect.x = x;
tgtvect.y = y;
tgtvect.r = r;
tgtvect.t = t;

%{
figure
subplot(1,2,1);plot(t,x);hold on;plot(t,y)
subplot(1,2,2);plot3(t,x,y)
%}

if isempty(h.window)
   %fprintf('sp_sin_tgt2D: No drawing window. Done.\n');
   return
end

%{
% DISPLAY STIM.
% Draw init tgt pos
h.color=h.white;
draw_dot(h, x0,y0, h.tgt_rad, h.white.*h.stim_level)
Screen('Flip',h.window);
WaitSecs(1/fps);

if ~timed   
   % Approach 1
   % If we loop, no other ML stuff can run (e.g. getfix,getsacc) until
   % the entire stimulus is finished drawing.
   for ii=1:numframes
      % erase prev dot
      try    draw_dot(h, x(ii-1),y(ii-1), h.tgt_rad, h.bg_clr)
      catch, draw_dot(h, x0,y0, h.tgt_rad, h.bg_clr); end
      % draw new dot
      draw_dot(h, x(ii),y(ii), h.tgt_rad, h.white.*h.stim_level)
      Screen('Flip',h.window);
      WaitSecs(1/fps);
   end
else
   % Approach 2
   timed_draw(tgtvect)
end
%}