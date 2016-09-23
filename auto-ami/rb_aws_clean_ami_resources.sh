#!/bin/bash

function usage() {
    echo "USAGE: $(basename $0)"
    echo "-a <AMI_ID>"
    echo "-i <INSTANCE_ID>"
    echo "-s <S3_FOLDER>"
}


temp_folder=temp
config_folder=config
if [ -r $temp_folder/vauto-ami.txt ] ; then
        source $temp_folder/vauto-ami.txt
fi
if [ -r $temp_folder/AMI_ID.txt ] ; then
	source $temp_folder/AMI_ID.txt 
fi
source $config_folder/aws_configuration

while getopts "a:i:s:h" opt ; do
    case $opt in
        a) AMI_ID=$OPTARG;;
        i) INSTANCE_ID=$OPTARG;;
        s) S3_FOLDER=$OPTARG;;
        h) usage; exit 0;; 
    esac
done

  

COUNTER=1
AMI_STATE=$(aws ec2 describe-images --region eu-west-1 --owners self --image-ids $AMI_ID | jq -r .Images[0].State)
while [ "x$AMI_STATE" != "xavailable" -a $COUNTER -le 300 ] ; do 
    AMI_STATE=$(aws ec2 describe-images --region $REGION --owners self --image-ids $AMI_ID | jq -r .Images[0].State)
    echo "AMI $AMI_ID is in $AMI_STATE state. Sleeping 10 seconds... ($COUNTER/300)"
    sleep 10
    let COUNTER=COUNTER+1
done

if [ "x$AMI_STATE" = "xavailable" ] ; then
    
    #Cleaning EC2 resources...
    #Get ebs volume
    if [ "x$INSTANCE_ID" != "x" ] ; then
        VOLUME_ID=$(aws ec2 describe-instance-attribute --instance-id $INSTANCE_ID --attribute blockDeviceMapping --region $REGION | jq -r .BlockDeviceMappings[0].Ebs.VolumeId)
        echo "VOLUME_ID=$VOLUME_ID"
        aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
        COUNTER=1
        while [ "x$DELETE_VOLUME_STATUS" != "x0" -a $COUNTER -le 10 -a "x$VOLUME_ID" != "x" ] ; do 
            echo "Trying to delete volume $VOLUME_ID ($COUNTER/10)"
            aws ec2 delete-volume --volume-id $VOLUME_ID --region $REGION
            DELETE_VOLUME_STATUS=$?
            [ $DELETE_VOLUME_STATUS ] && sleep 2
            let COUNTER=COUNTER+1
        done
    else
        echo "ERROR: Can't delete instance, INSTANCE_ID parameter is missing"
    fi
    #Cleaning S3 resources...
    if [ "x$S3_FOLDER" != "x" ] ; then
        aws s3 rm s3://$S3_FOLDER --recursive
    else
        echo "ERROR: Can't delete S3 Folder, S3_FOLDER parameter is missing"
    fi
fi
