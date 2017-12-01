#!/bin/tcsh
##############################################
### CreatePBSSubmissionFile.csh
##############################################
# -----------------------------------------------------------------------------------------
# This file is replaceing all the placeholders in the *_blanc files
# with the arguments of the variables specified in this files
# The following variables has to be specified
#
# Variables used in PBSSubmissionFile.csh
# JOBNAMEPREFIX: Name of the current job (qsub parameter), also used for naming the executable,
#                naming .log and .error files and can be also
# SAVEDIRPREFIX: Prefix used for defining the saving directory in /mnt/mimer (SAVEDIR variable)
# NUMBEROFNODES: qsub parameter, number of nodes used 
#                !!! Remember: there has to be a grid.info.partNUMBEROFNODES
#                in the workdirectory !!!         
# NUMBEROFCORES: qsub parameter, number of cores 
# WALLTIME: qsub paramter, walltime given in "HH:MM:SS"
#
# Variables used in PBSSubmissionFile.pbs AND CopyConcurrently.csh 
# SAVEDIR: Directory where the mpasout files should go
# OUTPUTFILENAME: Prefix for the outputvariables create by MPAS (defined in streams.atmosphere)
#
# Variables needed within this file
# MPAS: Absolute path of the location of the "MPAS-Realease" folder (MPAS root directory)
# EXETYPE: Specifies the executable file of MPAS
#          [0]: init_atmosphere_model
#          [1]: atmosphere_model
# -----------------------------------------------------------------------------------------

# Definition of Variables
set JOBNAMEPREFIX="jw_bw" # !! <= 6 signs due to limitation of PBS JOBNAME length 
set SAVEDIRPREFIX="jw_bw_with_perturbation"
set EXETYPE=1
set NUMBEROFNODES=1
set NUMBEROFCORES=2
set WALLTIME="2:00:00"
set SAVEDIR="/mnt/mimer/maim/MPAS/Projects/test_cases/baroclinic_waves/$SAVEDIRPREFIX"
set OUTPUTFILENAME="mpasout"
set MPAS="/home/maim/MPASv5/MPAS-Release" 
# -----------------------------------------------------------------------------------------
# 1. Create SAVEDIR if not already existing 
mkdir -p $SAVEDIR
if ($EXETYPE == 0) then
   set JOBNAME=$JOBNAMEPREFIX.iatm
   ln -sfn init_atmosphere_model $JOBNAME
else
   set JOBNAME=$JOBNAMEPREFIX.atm
   ln -sfn atmosphere_model $JOBNAME
endif
# 2. Copy the *_blanc files in the current work directory
cp -f $MPAS/blanc_files/CopyConcurrently_blanc.csh CopyConcurrently.csh 
cp -f $MPAS/blanc_files/PBSSubmissionFile_blanc.pbs PBSSubmissionFile.pbs
# 3. Find out if node/cores combination makes sense and if  there is a grid.info.part for the node/cores combination 
# 3.1 reject job submissions using more than 9 nodes 
if ($NUMBEROFNODES > 9) then 
   echo "NUMBEROFNODES > 9 (intended?), consider (maybe) longer walltime instead of so many nodes!"
   exit 1
endif 
# 3.2 Reject job submissions with more than 20 processes per node (physically not possible)
if ($NUMBEROFCORES > 20) then 
   echo "NUMBEROFCORES >= 20 is not possible"
   exit
endif 
# 3.3 Reject job submission when there is no corresponding graph.info.part file for the 
#     Nodes/Core combination 
@ np=$NUMBEROFNODES * $NUMBEROFCORES
set GridFilePrefix = `ls -t1 *grid.nc | cut -d. -f1,2 `
set GridPartFileNeeded = "$GridFilePrefix.graph.info.part.$np" 
if (! -f $GridPartFileNeeded ) then
   echo "ERROR:"
   echo "Nodes/core combination ($NUMBEROFNODES x $NUMBEROFCORES = $np) needs $GridPartFileNeeded, which doesn't exist!"
   echo "Please select different nodes/core combination or use METIS to create $GridPartFileNeeded" 
   exit 1
endif
# 4. Transform nodes and ppn from integer to char
set NumOfNodes="$NUMBEROFNODES"
set NumOfCores="$NUMBEROFCORES"
# 5. Replace placeholder variables in corresponding _blanc file
sed -i s/JOBNAME/$JOBNAME/g PBSSubmissionFile.pbs
sed -i s/NUMBEROFNODES/$NumOfNodes/g PBSSubmissionFile.pbs
sed -i s/NUMBEROFCORES/$NumOfCores/g PBSSubmissionFile.pbs
sed -i s/WALLTIME/$WALLTIME/g PBSSubmissionFile.pbs
##### For SaveDir, switch delimiter because $SaveDir contains "/"
sed -i s@SAVEDIR@$SAVEDIR@g PBSSubmissionFile.pbs
sed -i s@SAVEDIR@$SAVEDIR@g CopyConcurrently.csh
sed -i s/OUTPUTFILENAME/$OUTPUTFILENAME/g PBSSubmissionFile.pbs
sed -i s/OUTPUTFILENAME/$OUTPUTFILENAME/g CopyConcurrently.csh
sed -i s/EXETYPE/$EXETYPE/g PBSSubmissionFile.pbs
# 6. Submit job
sleep 1
#qsub PBSSubmissionFile.pbs
echo "Run of CreatePBSSubmissioFile successful"
