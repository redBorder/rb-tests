#!/bin/bash 
release=$1
temp_folder=temp
error_uploading=0
cd $temp_folder
if [ -f $release.img ] ; then  
	#echo "Uploading IMG to repo 128.107.16.230..."
	#scp -i ~/.ssh/rbmanager.pem -P 6666 $release.img cloud-user@128.107.16.230:/opt/rb/var/www/isos/
	#[ $? != 0 ] && error_uploading=1
	echo "Uploading QCOW2 to repo 128.107.16.230..."
	scp -i ~/.ssh/rbmanager.pem -P 6666 $release.qcow2 cloud-user@128.107.16.230:/opt/rb/var/www/isos/
        [ $? != 0 ] && error_uploading=1
	../rb_pushbullet.sh repo $release
else
	echo "IMG file not found"
	exit 1
fi
cd ..
