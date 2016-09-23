#!/bin/bash 
source ~/.bash_profile
echo "PATH=$PATH"
temp_folder=temp
config_folder=config
if [ -r $temp_folder/vauto-ami.txt ] ; then
	source $temp_folder/vauto-ami.txt
fi
source $config_folder/aws_configuration
release=$1
echo "RELEASE = $release"

if [ "x$release" != "x" -a "x$AWS_ACCESS_KEY" != "x" -a "x$AWS_SECRET_KEY" != "x" -a "x$TASK_ID" != "x" ] ; then
        rm -f $temp_folder/ec2-resume-import.log
	ec2-resume-import -t $TASK_ID -o $AWS_ACCESS_KEY -w $AWS_SECRET_KEY --region $REGION $temp_folder/$release.img | tee $temp_folder/ec2-resume-import.log	 
	S3_FOLDER=$(head $temp_folder/ec2-resume-import.log -n 10 | grep -i "Creating new manifest at" | grep -o -e "\S*\/.*\/")
        . rb_aws_check_conversion.sh $TASK_ID
	aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --sriov-net-support simple \
	--region $REGION
	
	COUNTER=1
	CREATE_STATUS=1
	while [ "$CREATE_STATUS" != "0"  -a $COUNTER -le 50 ]; do
		echo "Trying with AMINAME = $release-V$COUNTER ($COUNTER/50)"
		DEBUG=$( aws ec2 create-image --instance-id $INSTANCE_ID  --name "$release-V$COUNTER" --region $REGION) 
		CREATE_STATUS=$?
		
		let COUNTER=COUNTER+1
	done
	AMI_ID=$(echo "$DEBUG"| jq -r .ImageId )
	echo "AMI_ID=$AMI_ID"
	echo "AMI_ID=$AMI_ID" > $temp_folder/AMI_ID.txt
	
        echo $release | grep -v "cloudproxy"
        if [ $? -eq 0 ] ; then
		echo "AMI_ID=$AMI_ID" > $temp_folder/AMI_ID_TESTING.txt
        fi
        ./rb_aws_clean_ami_resources.sh -i $INSTANCE_ID -s $S3_FOLDER
        ./rb_pushbullet.sh aws $release
else
	echo "Invalid arguments"
	exit 1
fi
cd ..
