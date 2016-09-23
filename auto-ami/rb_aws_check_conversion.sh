#!/bin/bash

#
#	Script to check if an import task have finished.
#
config_folder=config
source $config_folder/aws_configuration
if [ "x$TASK_ID" != "x" ] ; then
	COUNTER=1
	while [ $COUNTER -lt 1000 ]; do
		CONVERSION_TASKS=$(aws ec2 describe-conversion-tasks --conversion-task-ids $TASK_ID --region $REGION)
		CONVERSION_STATUS_MESSAGE="$(echo $CONVERSION_TASKS | jq -r .ConversionTasks[0].StatusMessage)"
		CONVERSION_STATUS="$(echo $CONVERSION_TASKS | jq -r .ConversionTasks[0].State)"
	        INSTANCE_ID="$(echo $CONVERSION_TASKS | jq -r .ConversionTasks[0].ImportInstance.InstanceId)"
		echo "Checking if conversion have finished  ($COUNTER/1000) => $CONVERSION_STATUS - $CONVERSION_STATUS_MESSAGE"
		echo "INSTANCE_ID=$INSTANCE_ID"
        if [ "$CONVERSION_STATUS" = "completed" ] ; then
    		COUNTER=1001
    		echo "Conversion done succesfully"
        elif [ "$CONVERSION_STATUS" = "cancelled" ] ; then
    		COUNTER=1001
        	echo "Conversion failed"
                exit 1
    	else
    		let COUNTER=COUNTER+1
    		sleep 5
    	fi
	done
else
	echo "USAGE: rb_aws_check_conversion.sh <TASK_ID>"
fi
