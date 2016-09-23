 #!/bin/bash -e


temp_folder=temp
RELEASE=$1
NumberVirtualMachine=$2

if [ "x$RELEASE" != "x" -a "x$NumberVirtualMachine" != "x"  ] ; then
        cd $temp_folder
	rm -f TEST_REDBORDER_MANAGER_$NumberVirtualMachine.img
	cp TEST_MANAGER_$RELEASE.img TEST_REDBORDER_MANAGER_$NumberVirtualMachine.img
	virsh start REDBORDER-MANAGER-$NumberVirtualMachine
	cd ..
else
	echo "Usage: ./rb_execute_img.sh <IMG FILENAME> <NUMBER_VIRTUAL_MACHINE>"
fi
