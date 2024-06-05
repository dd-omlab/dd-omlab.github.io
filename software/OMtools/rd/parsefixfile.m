% parsefixfile: Called near the end of 'rd' to build fixation structures
% using emData and additional info ( ) stored in the '_extras.mat' file.
% 
% DO NOT USE 'xpos','ypos' for calculations, because they were stored by
% the EL prior to post-facto calibration. Instead, get position data by
% indexing into emData channels.

% Written by: Jonathan Jacobs
% Created:    January 2018

function data = parsefixfile(data)

fn = data.filename; fn=strtok(fn,'.');
a = load([fn '_extras.mat']);
field_name = cell2mat( fieldnames(a) );
extras = eval([ 'a.' field_name] );

if isfield(extras, 'fix')
   fix = extras.fix;
   if isempty(fieldnames(fix)), return; end
   numsfixes=length(fix.eye);
   data.start_times = extras.start_times;
   data.stop_times  = extras.stop_times;
   data.h_pix_z = extras.h_pix_z;
   data.h_pix_deg = extras.h_pix_deg;
   data.v_pix_z = extras.v_pix_z;
   data.v_pix_deg = extras.v_pix_deg;
   
   l_cnt = 0; r_cnt = 0;
   for i=1:numsfixes
      switch fix.eye{i}
         case 'L'
            l_cnt = l_cnt+1;
            if ~isempty(fix.xpos)
               data.lh.fixation.paramtype = 'EDF_PARSER';
               data.lh.fixation.fixlist.start(l_cnt) = fix.start(i);
               data.lh.fixation.fixlist.end(l_cnt) = fix.end(i);
               data.lh.fixation.fixlist.dur(l_cnt) = fix.dur(i);
               data.lh.fixation.fixlist.pupil(l_cnt) = fix.pupi(i);
               %
               data.lh.fixation.fixlist.startpos(l_cnt) = ...
                  (fix.xpos(i)-data.h_pix_z)/data.h_pix_deg;
               
            end
            if ~isempty(fix.ypos)
               data.lv.fixation.paramtype = 'EDF_PARSER';
               data.lv.fixation.fixlist.start(l_cnt) = fix.start(i);
               data.lv.fixation.fixlist.end(l_cnt) = fix.end(i);
               data.lv.fixation.fixlist.dur(l_cnt) = fix.dur(i);
               data.lv.fixation.fixlist.pupil(l_cnt) = fix.pupi(i);
               %
               data.lv.fixation.fixlist.startpos(l_cnt) = ...
                  (fix.ypos(i)-data.v_pix_z)/data.v_pix_deg;
            end
            
         case 'R'
            r_cnt = r_cnt+1;
            if ~isempty(fix.xpos)
               data.rh.fixation.paramtype = 'EDF_PARSER';
               data.rh.fixation.fixlist.start(r_cnt) = fix.start(i);
               data.rh.fixation.fixlist.end(r_cnt) = fix.end(i);
               data.rh.fixation.fixlist.dur(r_cnt) = fix.dur(i);
               data.rh.fixation.fixlist.pupil(r_cnt) = fix.pupi(i);
               %
               data.rh.fixation.fixlist.startpos(r_cnt) = ...
                  (fix.xpos(i)-data.h_pix_z)/data.h_pix_deg;
            end
            if ~isempty(fix.ypos)
               data.rv.fixation.paramtype = 'EDF_PARSER';
               data.rv.fixation.fixlist.start(r_cnt) = fix.start(i);
               data.rv.fixation.fixlist.end(r_cnt) = fix.end(i);
               data.rv.fixation.fixlist.dur(r_cnt) = fix.dur(i);
               data.rv.fixation.fixlist.pupil(r_cnt) = fix.pupi(i);
               %
               data.rv.fixation.fixlist.startpos(r_cnt) = ...
                  (fix.ypos(i)-data.v_pix_z)/data.v_pix_deg;
            end
      end %switch
   end %for i
end % if fix is a field in extras struct