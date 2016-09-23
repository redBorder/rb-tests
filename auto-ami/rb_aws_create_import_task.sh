#!/bin/bash 
source ~/.bash_profile
echo "PATH=$PATH"
temp_folder=temp
config_folder=config
if [ -r $temp_folder/vauto-ami.txt ] ; then
	source $temp_folder/vauto-ami.txt
fi
source $config_folder/aws_configuration
[ "x$S3BUCKET" = "x" ] && S3BUCKET=rbos
release=$1
cd $temp_folder
if [ "x$release" != "x" -a "x$AWS_ACCESS_KEY" != "x" -a "x$AWS_SECRET_KEY" != "x" ] ; then	
	IMPORT_RESULT=1
	COUNTER=1
	while [ $COUNTER -lt 11 -a "$IMPORT_RESULT" != "0" ] ; do
		DEBUG=$(ec2-import-instance ./$release.img -f RAW -t m3.medium -a x86_64 --subnet $SUBNET --bucket $S3BUCKET \
	               	-o $AWS_ACCESS_KEY -w $AWS_SECRET_KEY --region $REGION -p Linux --no-upload)
		IMPORT_RESULT=$?
		echo $DEBUG
		if [ "$IMPORT_RESULT" != "0" ] ; then
			echo "Import instance failure, retrying... ($COUNTER/10)"
		fi
   		let COUNTER=COUNTER+1	
	done
	if [ "$IMPORT_RESULT" != 0 ] ; then
		echo "Import instance failure, imposible create task"
		exit 1
	fi
	TASK_ID=$(echo "$DEBUG" | grep TaskId | cut -f 4)
	echo "TASK_ID=$TASK_ID" > vauto-ami.txt
	echo "TASK_ID=$TASK_ID" 
else	echo "USAGE: rb_aws_create_import_task.sh <img filename>"
fi
cd ..
