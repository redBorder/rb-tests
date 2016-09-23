 #!/bin/bash -e


temp_folder=temp
RELEASE=$1

if [ "x$RELEASE" != "x" ] ; then
        cd $temp_folder
	rm -f TEST_REDBORDER_CP.img
	cp TEST_CLIENTPROXY_$RELEASE.img TEST_REDBORDER_CP.img
	virsh start REDBORDER-CLIENT-PROXY
	cd ..
else
	echo "Usage: ./rb_execute_img.sh <RELEASE>"
fi
