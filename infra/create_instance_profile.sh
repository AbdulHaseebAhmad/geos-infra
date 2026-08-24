#!/bin/bash

create_instance_profile(){

	echo "creating iam instance profile"
	log "creating iam instance profile"

	aws iam create-instance-profile \
	    --instance-profile-name "$INSTANCE_PROFILE_NAME"
	
	if [[ $? -ne 0 ]];
	then
		echo "instance profile could not be created"
		log   "instance profile could not be created"
		return 1
	fi
		
	INSTANCE_PROFILE_ARN=$(aws iam get-instance-profile \
	    --instance-profile-name "$INSTANCE_PROFILE_NAME" \
	    --query "InstanceProfile.Arn" \
	    --output text)
	

	if [[ $? -ne 0 ]];
	then
		echo "the instance profile created but arn could not be fetched"
		log  "the instance profile created but arn could not be fetched"
		return 1
	fi

	echo "the instance profile created and arn fetched and saved"
	log  "the instance profile created and arn fetched and saved"
	yq -i ".iam_role.app_instance_profile.arn = \"$INSTANCE_PROFILE_ARN\"" ../config/config.yaml
	return 0 
}
