#!/bin/bash

add_role_to_instance_profile(){
	
	echo "adding Role to instance profile"
	log  "adding Role to instance profile"

	aws iam add-role-to-instance-profile \
	    --instance-profile-name  "$APP_INSTANCE_PROFILE_NAME" \
	    --role-name "$APP_SECRETS_ROLE"
	
	if [[ $? -ne 0 ]];
	then
		echo "failed to add role to iam profile"
		log "failed to add role to iam profile"
		return 1
	fi

	INSTANCE_PROFILE_ROLES=$(aws iam get-instance-profile \
	    --instance-profile-name "$APP_INSTANCE_PROFILE_NAME" \
	    --query "InstanceProfile.Roles")
	    
	if [[ $? -ne 0 ]];

	then
		echo "failed to fetch roles"
		log "failed to fetch roles"
		return 0
	fi
	
	echo "the following "$INSTANCE_PROFILE_ROLES" were attached"
	log  "the following "$INSTANCE_PROFILE_ROLES" were attached"
	return 0 

    }
