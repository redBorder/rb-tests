 #!/bin/bash -e

temp_folder="../temp"
RELEASE=$1
NumberVirtualMachine=$2

if [ "x$RELEASE" != "x" -a "x$NumberVirtualMachine" != "x"  ] ; then
        cd $temp_folder
        rm -f TEST_REDBORDER_IPS_$NumberVirtualMachine.img
        cp TEST_IPS_$RELEASE.img TEST_REDBORDER_IPS_$NumberVirtualMachine.img
        virsh start REDBORDER-IPS-$NumberVirtualMachine
        cd ..
else
        echo "Usage: ./rb_execute_img.sh <IMG FILENAME> <NUMBER_VIRTUAL_MACHINE>"
        exit 1
fi
