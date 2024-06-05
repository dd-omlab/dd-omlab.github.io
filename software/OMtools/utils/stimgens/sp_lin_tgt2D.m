function tgtvect=sp_lin_tgt2D(h, startpt,endpt,tgtvel,fps) %,timed)

% startpt,endpt are (x,y) degrees
% tgtvel is radial velocity deg/sec

try    h.window;
catch, h.window=[]; end

if isempty(h)
   h.tgt_rad = 1;
   h.window  = [];
   h.white   = [1 1 1];
   h.bg_clr  = [0 0 0];
end

tgtvect=[];
if ~exist('fps','var'), fps=50;end

deltax = endpt(1)-startpt(1);
deltay = endpt(2)-startpt(2);
deltar = sqrt(deltax^2 + deltay^2); % total distance

dur = deltar/tgtvel;
numframes = fix(dur*fps);

tstep = 1/fps;
xstep = deltax/numframes;
ystep = deltay/numframes;

x0 = startpt(1);
y0 = startpt(2);
x = x0 + (1:numframes)*xstep;  % creates numsteps+1 values
y = y0 + (1:numframes)*ystep;
t = (1:numframes)*tstep;

tgtvect.dur = dur;
tgtvect.tgtvel = tgtvel;
tgtvect.fps = fps;
tgtvect.fdur = 1/fps;
tgtvect.numframes = numframes;
tgtvect.xstep = xstep;
tgtvect.ystep = ystep;
tgtvect.tstep = tstep;
tgtvect.x0 = x0;
tgtvect.y0 = y0;
tgtvect.t0 = GetMSecs;
tgtvect.x = x;
tgtvect.y = y;
tgtvect.t = t;

%{
figure
subplot(1,2,1);plot(t,x);hold on;plot(t,y)
subplot(1,2,2);plot3(t,x,y)
%}

if isempty(h.window)
   %fprintf('No drawing window. Done.\n');
   return
end

%{
% DISPLAY STIM.
% Draw init tgt pos
draw_dot(h, x0,y0, h.tgt_rad, h.white.*h.stim_level)
Screen('Flip',h.window);
WaitSecs(1/fps);

if ~timed
   % Approach 1
   % If we loop, no other ML stuff can run (e.g. getfix,getsacc) until
   % the entire stimulus is finished drawing.
   for ii=1:numframes
      % erase prev dot
      try    draw_dot(h, x(ii-1),y(ii-1), h.tgt_rad, h.bg_clr);
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
