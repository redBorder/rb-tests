#!/bin/bash

STACK_NAME=$1
REGION=$2

[ "x$REGION" = "x" ] && REGION=eu-west-1

function deleteRecordSets() {
  HOSTED_ZONE=$1  
  echo "Getting route53 record sets"
  LIST=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE --region $REGION)
  
  COUNTER=0
  TYPE=$(echo $LIST | jq -r .ResourceRecordSets[$COUNTER].Type)
  while [ "x$TYPE" != "x" -a "x$TYPE" != "xnull"  ] ; do 
    #getting record sets    
    if [ "x$TYPE" = "xA"  ] ; then
      NAME=$(echo $LIST | jq -r .ResourceRecordSets[$COUNTER].Name)  
      TTL=$(echo $LIST | jq -r .ResourceRecordSets[$COUNTER].TTL)
      IP_HOST=$(echo $LIST | jq -r .ResourceRecordSets[$COUNTER].ResourceRecords[0].Value)
      #deleting record sets
      if [ "x$TTL" != "x" -a "x$TTL" != "xnull" ] ; then 
        echo "Deleting route 53"
        aws route53 change-resource-record-sets --region $REGION --hosted-zone-id $HOSTED_ZONE --change-batch  \
            "{ \"Changes\": [                                                                    \
                {                                                                                \
                    \"Action\":\"DELETE\",                                                       \
                    \"ResourceRecordSet\": {                                                     \
                        \"Name\": \"$NAME\",                                                 \
                        \"Type\": \"$TYPE\",                                                     \
                        \"TTL\": $TTL,                                                           \
                        \"ResourceRecords\": [                                                   \
                            {                                                                    \
                                \"Value\" : \"$IP_HOST\"                                         \
                            }                                                                    \
                        ]                                                                        \
                    }                                                                            \
                }                                                                                \
            ] }"
      fi
    fi
    let COUNTER=COUNTER+1
    TYPE=$(echo $LIST | jq -r .ResourceRecordSets[$COUNTER].Type)
  done

}

if [ "x" != "x$STACK_NAME" ] ; then
  # Search s3 bucket name 
  S3BUCKET=$(aws cloudformation describe-stack-resource --region $REGION --stack-name $STACK_NAME --logical-resource-id S3Bucket | jq -r .StackResourceDetail.PhysicalResourceId)
  echo "S3BUCKET=$S3BUCKET"
  # Delete s3 data from bucket
  if [ "x" != "x$S3BUCKET" -a "xnull" != "x$S3BUCKET"  ] ; then
    echo "Deleting S3 data"
    aws s3 rm s3://$S3BUCKET --include "*" --recursive
  fi

  # Search route53 hosted zones
  PUBLIC_HOSTED_ZONE=$(aws cloudformation describe-stack-resource --region $REGION --stack-name $STACK_NAME --logical-resource-id PublicHostedZone | jq -r .StackResourceDetail.PhysicalResourceId)
  PRIVATE_HOSTED_ZONE=$(aws cloudformation describe-stack-resource --region $REGION --stack-name $STACK_NAME --logical-resource-id PrivateHostedZone | jq -r .StackResourceDetail.PhysicalResourceId)  
  if [ "x" != "x$PUBLIC_HOSTED_ZONE" -a "xnull" != "x$PUBLIC_HOSTED_ZONE" ] ; then
    deleteRecordSets $PUBLIC_HOSTED_ZONE
  fi
  if [ "x" != "x$PRIVATE_HOSTED_ZONE" -a "xnull" != "x$PRIVATE_HOSTED_ZONE" ] ; then  
    deleteRecordSets $PRIVATE_HOSTED_ZONE
  fi
else
  echo "USAGE: $0 <STACK_NAME>"
fi
