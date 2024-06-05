function sp_lin_tgt(h,start_pt,end_pt,tgtvel)

xtot = (end_pt(1)-start_pt(1));
ytot = (end_pt(2)-start_pt(2));

rtot = sqrt(xtot^2 + ytot^2);
dur = rtot/tgtvel;

fps = 60;
numsteps = fix(dur*fps);
xstep = xtot/numsteps;
ystep = ytot/numsteps;

x = start_pt(1);
y = start_pt(2);

%while abs(x-end_pt(1))>xlim && abs(y-end_pt(2))>ylim
for i=1:numsteps
   %draw_dot(h, x,y, h.tgt_rad, h.bg_clr)
   x=x+xstep;
   y=y+ystep;
   draw_dot(h, x,y, h.tgt_rad, h.white.*h.stim_level)
   Screen('Flip',h.window);
   WaitSecs(1/fps);
end
