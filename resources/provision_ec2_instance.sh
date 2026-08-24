#!/bin/bash

provision_ec2_instance(){

	log "provisioning app server EC2 intance.."
	echo "provisioning app server EC2 intance.."
	

	if [[ -z "$1" ]];
	then 
		return 1
	fi


	DB_SECRET_ARN=$(yq ".rds.secrets_arn" "$CONFIG_FILE")
	DB_ENDPOINT=$(yq ".rds.endpoint" "$CONFIG_FILE")
	
	sed -e "s|__SECRET_ARN__|$DB_SECRET_ARN|g" \
    	    -e "s|__RDS_ENDPOINT__|$DB_ENDPOINT|g" \
    	    ../resources/user-data.sh > ../resources/generated-user-data.sh

	INSTANCE_ID=$(aws ec2 run-instances \
	    --image-id "$AMI_ID" \
	    --instance-type "$INSTANCE_TYPE" \
	    --subnet-id "$SUBNET_ID" \
	    --security-group-ids "$SECURITY_GROUP_ID" \
	    --key-name "$KEY_NAME" \
	    --iam-instance-profile Name="$INSTANCE_PROFILE_NAME" \
	    --user-data file://../resources/generated-user-data.sh \
	    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value="$INSTANCE_NAME"}]" \
	    --query "Instances[0].InstanceId" \
	    --output text)
	
	if [[ $? -ne 0 ]];
	then
		log  "the provisioning of app server EC2 instance Failed" 
		echo "the provisioning of app server EC2 instance Failed"
		return 1
	fi

	log "the app server ec2 instance was provisioned succesfully with instance_id = "$INSTANCE_ID""
	echo "the app server ec2 instance was provisioned succesfully with instance_id = "$INSTANCE_ID""
	yq -i ".app_servers.instances.instance_$1_id = \"$INSTANCE_ID\"" ../config/config.yaml
		
	log "waiting for the app server ec2 with id "$INSTANCE_ID" to be available"
	echo   "waiting for the app server ec2 with id "$INSTANCE_ID" to be available"
	
	aws ec2 wait instance-running \
            --instance-ids "$INSTANCE_ID"
	
	if [[ $? -ne 0 ]];
	then
	    log "the app server ec2 with id $INSTANCE_ID failed to become available"
	    echo "the app server ec2 with id $INSTANCE_ID failed to become available"
	    return 1
	fi

	log "the app server ec2 with id $INSTANCE_ID is available"
	echo "the app server ec2 with id $INSTANCE_ID is available"	
	return 0
}

provision_ec2_instance $1
