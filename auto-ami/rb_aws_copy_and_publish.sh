#!/bin/bash -e

function wait_for_ami() {
    #Waiting AMI to be available
    ami_id=$1
    region=$2
    COUNTER=1
    AMI_STATE=$(aws ec2 describe-images --region $region --owners self --image-ids $ami_id | jq -r .Images[0].State)
    while [ "x$AMI_STATE" != "xavailable" -a $COUNTER -le 300 ] ; do
        AMI_STATE=$(aws ec2 describe-images --region $region --owners self --image-ids $ami_id | jq -r .Images[0].State)
        echo "AMI $ami_id ($region) is in $AMI_STATE state. Sleeping 10 seconds... ($COUNTER/300)"
        sleep 10
        let COUNTER=COUNTER+1
    done
}

function usage() {
    echo "rb_aws_copy_and_publish.sh <OPTIONS>"
    echo "  -a AMI_ID : AMI_ID from ireland that will be copied and published"
    echo "  -p : flag to indicate that you want to publish amis"
    echo "  -r REGION_LIST : comma-separated list with regions where ami must be copied. By default is 'us-east-1, eu-west-2'. eu-west-1 musn't be included"
    echo "  -h : show help"
}

temp_folder=temp
AMI_ID=""
PUBLISH=0
REGION_LIST="us-east-1,us-west-2"

#Getting AMI_ID from temporal file
if [ -r $temp_folder/AMI_ID.txt ] ; then
    source $temp_folder/AMI_ID.txt
fi

while getopts "a:r:hp" opt ; do
    case $opt in
        a) AMI_ID=$OPTARG;;
        p) PUBLISH=1;;
        r) REGION_LIST=$OPTARG;;
        h) usage; exit 0;;
    esac
done

if [ "x$AMI_ID" != "x" ] ; then
    NEW_AMI_ID_LIST=""
    #Iterate on REGION_LIST to create copy tasks of AMIs
    for region in $(echo $REGION_LIST | tr ',' ' ') ; do
        AMI_NAME=$(aws ec2 describe-images --image-ids $AMI_ID --region eu-west-1 | jq -r .Images[].Name)
        echo -n "Creating task to copy to $region..."
        NEW_AMI_ID_LIST="$NEW_AMI_ID_LIST$(aws ec2 copy-image --source-region eu-west-1 --source-image-id $AMI_ID --name $AMI_NAME --region $region | jq -r .ImageId) "
        if [ "x$NEW_AMI_ID_LIST" != "xnull" -a "x$NEW_AMI_ID_LIST" != "x" ] ; then echo " ok" ; else echo "FAILED" ; exit 1 ; fi
    done
   
    #Iterate on REGION_LIST to wait for AMI to be copied
    AMI_COUNTER=1
    for region in $(echo $REGION_LIST | tr ',' ' ') ; do
        new_ami=$(echo $NEW_AMI_ID_LIST | awk "{print \$$AMI_COUNTER}")
        wait_for_ami $new_ami $region
        if [ $PUBLISH -eq 1 ] ; then
           echo -n "Publishing AMI $new_ami in region $region"
           aws ec2 modify-image-attribute --image-id $new_ami --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}" --region $region
           if [ $? -eq 0 ] ; then echo " ok" ; else echo "FAILED" ; fi
        fi
        let AMI_COUNTER=AMI_COUNTER+1
    done
    #Ireland AMI must be published to if flag is set
    if [ $PUBLISH -eq 1 ] ; then
        echo -n "Publishing AMI $AMI_ID in region eu-west-1"
        aws ec2 modify-image-attribute --image-id $AMI_ID --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}" --region eu-west-1
        if [ $? -eq 0 ] ; then echo " ok" ; else echo "FAILED" ; fi
    fi

else
    echo "Error, AMI_ID not found"
fi
