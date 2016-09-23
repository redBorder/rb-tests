#!/bin/bash

source /home/rb-tests/.bashrc

RELEASE=$1

pushd /home/rb-tests/rb-tests/autoami &> /dev/null
cp -f config/custom_configuration config/aws_configuration
cp -f /home/rb-tests/.aws/custom_credentials /home/rb-tests/.aws/credentials
sudo ./rb_create_cloud_img.sh $RELEASE
sudo ./rb_aws_create_import_task.sh $RELEASE 
sudo ./rb_aws_resume_import.sh $RELEASE
cp -f config/redborder_configuration aws_configuration
cp -f /home/rb-tests/.aws/redborder_credentials /home/rb-tests/.aws/credentials

popd &> /dev/null
