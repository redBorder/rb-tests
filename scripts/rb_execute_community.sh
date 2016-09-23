#!/bin/bash -e

temp_folder=temp
RELEASE=$1

if [ "x$RELEASE" != "x" ] ; then
        cd $temp_folder
	rm -f TEST_REDBORDER_COMMUNITY.img
	cp TEST_MANAGER_$RELEASE.img TEST_REDBORDER_COMMUNITY.img
	virsh start REDBORDER-COMMUNITY
	cd ..
else
	echo "Usage: ./rb_execute_community.sh <IMG FILENAME>"
fi
