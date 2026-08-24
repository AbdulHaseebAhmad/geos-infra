#!/bin/bash

provision_iam_role(){
	
	echo "provisioning iam role"
	log "provisioning iam role"


	APP_SECRETS_ROLE_ARN=$(
 	   aws iam create-role \
	        --role-name "$IAM_ROLE_NAME" \
	        --assume-role-policy-document '{
	            "Version": "2012-10-17",
	            "Statement": [{
	                "Effect": "Allow",
	                "Principal": {"Service": "ec2.amazonaws.com"},
	                "Action": "sts:AssumeRole"
	            }]
	        }' \
	        --query 'Role.Arn' \
	        --output text
	)

	if [[ $? -ne 0 ]];
	then
		echo "the iam role could not be provisioned succesfully"
		log "the iam role could not be provisioned succesfully"
		return 1
	fi

	echo "the iam role was successfullly provisioned"
	log "the iam role was successfullly provisioned"
	yq -i ".iam_role.app_secrets_role.arn = \"$APP_SECRETS_ROLE_ARN\"" ../config/config.yaml
	return 0
}
