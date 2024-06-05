%% draw_dot
function draw_dot(h, xcnt,ycnt, circ_rad, color) % diameter in degrees

if nargin<5, color=h.white; end

trans=1;
if ischar(color)
   cc = whatcolor(color);
   color = cc.rgb;
else
   if length(color)>3
      trans=color(4);
      color=color(1:3);
   end
   if all(color<=1), color=color.*h.white; end
   color=color.*h.stim_level;
   color=[color trans];
end

circ_pix_h = floor(2*circ_rad * h.hpix_per_deg);
circ_pix_v = floor(2*circ_rad * h.vpix_per_deg);
baseRect = [0 0 circ_pix_h circ_pix_v];
maxDiameter = max(baseRect) * 1.01;

[x0,y0] = RectCenter(h.wRect);
xc = x0 + xcnt*h.hpix_per_deg;
yc = y0 + ycnt*h.vpix_per_deg;

centeredRect = CenterRectOnPointd(baseRect,xc,yc);
Screen('FillOval',h.window,color,floor(centeredRect),maxDiameter)
%Screen('Flip', h.window);
end % draw_dot
