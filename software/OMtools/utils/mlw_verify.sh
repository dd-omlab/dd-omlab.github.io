#!/bin/bash

# mlw_verify.sh: part of test of ML_W_switch.m, ML_act.app and MLW_act.app
# Make sure MATLABWindow is running. Hopefully, only 1 instance.

function mlw_verify(){
mlwPID=$(pgrep -xd ',' 'MATLABWindow');  
#echo mlw pid: $mlwPID; 
#echo $([ -z $mlwPID ]);
#echo [ ${#mlwPID[@]} -gt 1 ]

#a=$( grep -o "," <<< "$mlw" ); #echo a = $a
b=$( grep -o "," <<< "$mlwPID" | wc -l ); #echo b = $b

# Sometimes there are MULTIPLE MLWindows running. May be orphans.
# if there is more than one, put up a warning
if [ $b -gt 1 ]; then
   echo "There is more than one MATLABWindow running!" 
   echo " If you feel brave, use Activity Monitor to start killing off"
   echo " instances until something interesting or something good happens. "
   echo " Or, if it works anyway, ignore this \"binary operator\" warning:"   
fi

# if there is no MATLABWindow process running, launch MLW_act. Give it a sec...
if [ -z $mlwPID ] ; then
   echo "launching MLW_act.app"
   open "./mlw_dummy.mlapp"
   sleep 1
else
   open "./MLW_act.app"
   #sleep 1
fi

MLW=$(lsappinfo find bundleID="org.cef.MATLABWindow");
#echo $MLW
#: <<'END'
if [ -z $MLW ] ; then
   return 66
   echo "it did not work"     #after the 'return', so no echo
else
   return 99
   echo "it worked"
fi
}

mlw_verify

###graveyard###
#res=$?
#echo qwert #$res
#[ -z $MLW ] && echo "MLW_act worked" || echo "MLW_act did not work"
