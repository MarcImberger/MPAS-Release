#!/bin/csh
###################################################
### Etablish partly copying from scratch directory
###################################################
# Here, external function is called, which runs as long as (while loop) Run_info 
# has the argument 'R' to copy mpasout_* from scratch directory to SAVEDIR (will be 
# replaced by the root function ChangePBSSubmissionFile.csh) '

# set content of Run_status.info to 'R': 
echo 'R' >& Run_status.info 
# read first line from Run_status.info and save it in stat:
set stat = `sed -n '1p' Run_status.info` 
# sed: (s)tream (ed)itor, non-interactive text editor for the command line
while ( $stat == 'R')
  # count number of current mpas output files by counting entries of 'ls mpasout_*' out
  @ nfiles = `ls OUTPUTFILENAME* | wc -w` 
  # wc: (w)ord (c)count
  echo "mpasout: $nfiles"
  if($nfiles >= 3) then
    # read filename of mpasoutput using sorted list 'ls' (newest first [-t flag]) with one file per line 
    # [-1 flag] and tailing the whole first line ('tail -1', same as 'tail -n 1')
    set fname = `ls -t1 OUTPUTFILENAME* | tail -1`
    echo 'Copying ' $fname
    /bin/cp -rfL $fname SAVEDIR/$fname
    /bin/cp -rfL diag* SAVEDIR/
    /bin/cp -rfL restart* SAVEDIR/
    /bin/rm $fname
  endif
  sleep 1
  # read first line from Run_status.info again and save it in stat:
  set stat = `sed -n '1p' Run_status.info`
  # procedure starts again if Run_status.info still contains 'R'
end 
