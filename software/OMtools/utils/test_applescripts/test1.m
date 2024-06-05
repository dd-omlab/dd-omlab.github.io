function test1
[pn,~,~]=fileparts(mfilename('fullpath'));
cmdstr=sprintf('osascript %s/toggle_mb_dock.scpt',pn);
system(cmdstr);
