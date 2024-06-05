% drawstim. present your stim (laser, LED, picture, text or graphic object
% e.g. PTB textures)

% Written by: Jonathan Jacobs
% Created:    27 Mar 2021

% stim can be a single x,y point, or a trajectory list of  x,y, points.
function [h,hgui,tgt] = drawstim(h,hgui,tgt,p)

dbstop if CAUGHT ERROR

oldPriority = 0;
Priority(3);

eye = p.eye;
tgt(h.tcnt).when    = h.tgt_on_time;
tgt(h.tcnt).whenEL  = TrackerTimeMS;
tgt(h.tcnt).viewing = eye;

temp=p.meth;
meth=temp{1};
temp=p.traj;
traj=temp{1};

if strcmpi(meth,'pict:')
   texture=Screen('MakeTexture', h.window, p.pdata);
   Screen('PreloadTextures', h.window, texture);
end

keep=0;
switch traj
   case 'led:'
      % Update target LED
      led_num = p.lednum;
      led_val = 2.^(led_num-1);
      tgt(h.tcnt).led      = led_num;
      tgt(h.tcnt).distance = h.led_loc_tbl.distance(h.led_loc_tbl.num==led_num);
      tgt(h.tcnt).angle    = h.led_loc_tbl.angle(h.led_loc_tbl.num==led_num);
      % light it
      if h.use_parallel, parallel_LED(led_val,[]);            end
      if h.use_led,      fprintf(h.ledport,num2str(led_val)); end
      
      % Enter target LED info into logs
      if h.use_Eyelink
         Eyelink('Message','LED %d on ',led_num);
      end
      if h.use_Arrington
         cmdstr='dataFile_InsertString';
         ledstr=['LED ' num2str(led_num) ' on.'];
         vpx_SendCommandString([cmdstr ' ' ledstr])
      end
      fprintf2(h.log, ...
         '(%d) LED %d on at %.0f (EL: %.0f); dist: %.f; angle: %.f; eye: %s.  ', ...
         h.tcnt, led_num, tgt(h.tcnt).when, tgt(h.tcnt).whenEL, ...
         tgt(h.tcnt).distance, tgt(h.tcnt).angle, eye);
      
      % Highlight current LED (un-highlight prev LED) in omrec_gui
      if h.prev_led
         try
            hgui.LedAxes.UserData.ltxt(h.prev_led).Color='b';
            hgui.LedAxes.UserData.ltxt(h.prev_led).(sizeprop)=7;
         catch
         end
      end
      if led_num
         try
            hgui.LedAxes.UserData.ltxt(led_num).Color='r';
            hgui.LedAxes.UserData.ltxt(led_num).(sizeprop)=12;
         catch
         end
      end
      h.prev_led = led_num;
      
      
   case 'xy:'     %% combine this into vect:
      xpos=p.xpos;
      ypos=p.ypos;
      tgt(h.tcnt).xpos = xpos;
      tgt(h.tcnt).ypos = ypos;
      
      % Enter stim info into logs
      if h.use_Eyelink
         Eyelink('Message','Start: Tgt pos %d,%d  ',xpos,ypos);
      end
      fprintf2(h.log, ...
         '(%d) Tgt pos %d,%d at %.0f (EL: %.0f); eye: %s.  ', ...
         h.tcnt, xpos,ypos, tgt(h.tcnt).when, tgt(h.tcnt).whenEL, ...
         tgt(h.tcnt).viewing);
      
      switch lower(meth)
         case 'draw:'
            oshape=lower(p.oshape);
            ocolor=lower(p.ocolor);
            owid=p.owid;
            switch oshape
               case 'dot'
                  % If keep==0, don't need to clear prev dot.
                  if keep~=0
                     draw_dot(h, h.prev_xpos,h.prev_ypos,owid,h.bgcolor)
                  end
                  draw_dot(h, xpos,ypos,owid,ocolor)
                  Screen('Flip',h.window,[],keep);
               otherwise
                  fprintf2(h.log,'unknown target shape!\n')
                  keyboard
            end
            
         case 'laser:'
            % Send p.xpos,p.ypos,laseron command to laser controller 
            % via analog out or USB serial?
            
         case 'pict:'
            % pict uses PIXELS for position!
            texture=Screen('MakeTexture', h.window, p.pdata);
            srcRect=[]; %[]=use whole pict
            xpix = deg2pix(xpos,'h',h);
            ypix = deg2pix(ypos,'v',h);
            destRect=[xpix-p.pwid/2, ypix-p.phgt/2, xpix+p.pwid, ypix+p.phgt];
            rotang=p.pangle;
            Screen('DrawTexture', h.window, texture,srcRect,destRect,rotang);
            Screen('Flip',h.window,[],keep);
            
         case 'text:'
            % use Screen('DrawText'). Try to add DrawFormattedText later?
            % text uses PIXELS for position!
            xpix = deg2pix(xpos,'h',h);
            ypix = deg2pix(ypos,'v',h);
            
            oldSize = Screen('TextSize', h.window, p.tsize); % Font size
            if ~strcmpi(p.tfont,'default')                   % Font name
               fontname=p.tfont;
               fontname(fontname=='_')=' ';
               oldFont=Screen('TextFont', h.window, fontname);
               if ~strcmp(fontname,Screen('TextFont', h.window, fontname))
                  fprintf2(h.log,'Could not set fontname.\n');
               end
            end
            
            tcolor=whatcolor(p.tcolor);
            Screen('DrawText', h.window, p.ttext,xpix,ypix,tcolor.rgb);
            Screen('Flip',h.window);
            Screen('TextFont', h.window, oldFont);
            Screen('TextSize', h.window, oldSize);
            
         otherwise
            fprintf2(h.log,'Unknown stimobj type!\n');
            keyboard
      end %switch meth
      
      h.prev_xpos=xpos;
      h.prev_ypos=ypos;
      
      
   case 'vect:'
      % Draw them all? (with timing)
      timed=0;
      if ~timed     % Approach 1
         % In a loop no other ML stuff can run (e.g. getfix,getsacc)
         % until the ENTIRE stimulus is finished drawing.
         xpos=p.xpos;
         ypos=p.ypos;
         fps=p.fps;
         
         % Instead of for, use while. Find the index closest to the actual
         % polled time. If it is same as last index, try again after pause.
         % This lets us drop frames if we are falling behind, similar to
         % what is done in "timed_draw"
         thisind=NaN(1,length(xpos));
         etime=thisind;
         ptime=thisind;
         rightnowMS=thisind;
         
         stimstartMS = GetMSecs;
         prevind = 0;
         ind = 0;
         xx = 0;
         ii = 0;
         
         % Enter stim start info into logs
         if h.use_Eyelink
            Eyelink('Message','Start: Tgt file %s for %d sec', p.trajname,p.dur);
         end
         fprintf2(h.log, ...
            '(%d) Start: Tgt file %s for %d sec at %.0f (EL: %.0f); eye: %s.  ', ...
            h.tcnt, p.trajname{1}, p.dur, tgt(h.tcnt).when, tgt(h.tcnt).whenEL, ...
            tgt(h.tcnt).viewing);
         
         while(1) %%%
            if ind>=length(xpos), break; end
            if GetMSecs>h.tgt_off_time % 1000/fps: msec/frame
               slop=95;
               if ind < slop/100 * length(xpos)
                  beep;pause(0.33);beep
                  fprintf2(h.log,'Target display time has expired!\n');
                  fprintf2(h.log,'Less than %d%% of the stimulus was shown!\n',slop);
                  fprintf2(h.log,'ind: %d of %d\n',ind,length(xpos));
                  keyboard
               end
               break
            end
            
            ii=ii+1;
            rightnowMS(ii) = GetMSecs;
            ind = round( fps*(rightnowMS(ii)-stimstartMS)/1000 ); %ms->sec
            % Too soon?
            if ind==prevind
               xx=xx+1;
               WaitSecs(1/fps);
               continue;
            end
            ind=ind+1;
            thisind(ind) = ind;
            
            % Parse stim
            switch meth
               case 'draw:'
                  oshape=lower(p.oshape);
                  ocolor=lower(p.ocolor);
                  owid=p.owid;
                  switch oshape
                     case 'dot'
                        % erase prev dot
                        try
                           draw_dot(h,xpos(ind-1),p.ypos(ind-1),owid,h.bg_clr)
                        catch
                           %draw_dot(h, x0,y0, h.tgt_rad, h.bg_clr);
                        end
                        draw_dot(h,xpos(ind),ypos(ind),owid,ocolor);
                        Screen('Flip',h.window,[],keep);
                     otherwise
                        fprintf2(h.log,'unknown target shape!\n')
                        keyboard
                  end
                  
               case 'laser:'
                  % Send p.xpos,p.ypos,laseron command to laser controller
                  % via analog out or USB serial?
                  
               case 'pict:'
                  % pict uses PIXELS for position!
                  texture=Screen('MakeTexture', h.window, p.pdata);
                  srcRect=[]; %[]=use whole pict
                  xpix = deg2pix(xpos,'h',h);
                  ypix = deg2pix(ypos,'v',h);
                  destRect=[xpix(ind)-p.pwid/2, ypix(ind)-p.phgt/2, ...
                     xpix(ind)+p.pwid, ypix(ind)+p.phgt];
                  rotang=p.pangle;
                  Screen('DrawTexture', h.window, texture,srcRect,destRect,rotang);
                  Screen('Flip',h.window,[],keep);
                  
               case 'text:'
                  % use Screen('DrawText'). Try to add DrawFormattedText later?
                  % text uses PIXELS for position!
                  xpix = deg2pix(xpos,'h',h);
                  ypix = deg2pix(ypos,'v',h);
                  
                  oldSize = Screen('FontSize', p.tsize);
                  if ~strcmpi(p.tfont,'default')
                     %
                     fontname=p.tfont;
                     fontname(fontname=='_')=' ';
                     oldFont=Screen('TextFont', h.window, fontname);
                     if ~strcmp(fontname,Screen('TextFont', h.window, fontname))
                        fprintf2(h.log,'Could not set fontname.\n');
                     end
                  end
                  
                  tcolor=whatcolor(p.tcolor);
                  Screen('DrawText', h.window, p.ttext,xpix,ypix,tcolor.rgb);
                  Screen('Flip',h.window);
                  Screen('TextFont', h.window, oldFont);
                  Screen('TextSize', h.window, oldSize);
                  
               otherwise
                  fprintf2(h.log,'Unknown stimobj type!\n');
                  keyboard
            end %switch meth
            
            ptime(ind) = stimstartMS/1000 + ind/fps;
            etime(ind) = WaitSecs('UntilTime', ptime(ind));
            prevind = thisind(ind);            
         end %while(1)
         
      else   % Approach 2: use timer-based draw
         timed_draw(tgtvect,usePTB);
      end %if timed
      
      
   otherwise
      fprintf2(h.log,'Unknown traj type!\n');
      keyboard
end %switch traj

% wait until time is up. Increment tgt counter.
pause((h.tgt_off_time-GetMSecs)/1000) %convert msecs to secs
h.tcnt=h.tcnt+1;

% Enter stim end info into logs
fprintf2(h.log,'Tgt done at %.0f\n',GetMSecs);
if h.use_Eyelink
   Eyelink('Message','Tgt done at  %.0f.',GetMSecs);
end

%Priority(0);
Priority(oldPriority);