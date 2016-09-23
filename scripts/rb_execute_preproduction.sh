#!/bin/bash 

temp_folder=~/rb-tests/scripts/temp
RELEASE=$1

for iter in 1 2 3 
do
  cd $temp_folder
  rm -f RB-PREP-MANAGER-$iter.img
  cp TEST_MANAGER_$RELEASE.img RB-PREP-MANAGER-$iter.img	
  virsh start RB-PREP-MANAGER-$iter
done
#fi
