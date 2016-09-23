 #!/bin/bash -e

temp_folder="../temp"
RELEASE=$1
#NumberVirtualMachine=$2

if [ "x$RELEASE" != "x" ] ; then
        cd $temp_folder
        rm -f TEST_REDBORDER_MANAGER_IPS.img
        cp TEST_MANAGER_$RELEASE.img TEST_REDBORDER_MANAGER_IPS.img
        virsh start REDBORDER-MANAGER-IPS
        cd ..
else
        echo "Usage: ./rb_execute_img.sh <IMG FILENAME> <NUMBER_VIRTUAL_MACHINE>"
        exit 1
fi
