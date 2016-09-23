 #!/bin/bash -e


temp_folder=temp
RELEASE=$1
NumberVirtualMachine=$2

if [ "x$RELEASE" != "x" -a "x$NumberVirtualMachine" != "x"  ] ; then
        cd $temp_folder
	rm -f TEST_REDBORDER_MASTER_$NumberVirtualMachine.img
	cp TEST_MASTER_$RELEASE.img TEST_REDBORDER_MASTER_$NumberVirtualMachine.img
	virsh start REDBORDER-MASTER-$NumberVirtualMachine
	cd ..
else
	echo "Usage: ./rb_execute_img.sh <IMG FILENAME> <NUMBER_VIRTUAL_MACHINE>"
fi
