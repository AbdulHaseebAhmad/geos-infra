#!/bin/bash

attach_iam_instance_profile(){

	aws ec2 associate-iam-instance-profile \
	    --instance-id "$INSTANCE_ID" \
	    --iam-instance-profile Name="$APP_INSTANCE_PROFILE_NAME"

	if [[ $? -ne 0 ]];
	then
		echo "the instance profile failed to attach"
		log "the instance profile failed to attach"
		return 1
	fi

	echo "the instance profile succesfully attached to the ec2 instance "$INSTANCE_ID""
	log  "the instance profile succesfully attached to the ec2 instance "$INSTANCE_ID""
	return 0
}
