%% draw_cross
function draw_cross(h, xcnt, ycnt, wid, hgt, color) % in degrees

if nargin<6, color=h.white; end

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

pix_hor = floor(wid * h.hpix_per_deg);
pix_vrt = floor(hgt * h.vpix_per_deg);
lin_thick = 10; %pix

[x0,y0] = RectCenter(h.wRect);
xc = x0 + xcnt*h.hpix_per_deg;
yc = y0 + ycnt*h.vpix_per_deg;
horRect = [0 0 pix_hor lin_thick];
cHRect = CenterRectOnPointd(horRect,xc,yc);
Screen('FillRect', h.window, color, cHRect );

vrtRect = [0 0 lin_thick pix_vrt];
cVRect = CenterRectOnPointd(vrtRect,x0,y0);
Screen('FillRect', h.window, color, cVRect );
%Screen('Flip', h.window);
end % draw_cross
