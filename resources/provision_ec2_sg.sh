#!/bin/bash

provision_ec2_sg(){
	
	log "Provisioning Security group for ec2"
	echo  "Provisioning Security group for ec2"

	SECURITY_GROUP_ID=$(aws ec2 create-security-group \
            --group-name "$SECURITY_GROUP_NAME" \
            --description "$SECURITY_GROUP_DESCRIPTION" \
            --vpc-id "$VPC_ID" \
	    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$SECURITY_GROUP_NAME}]" \
	    --query "GroupId"\
	    --output "text")
        
	if [[ $? -ne 0 ]];
        then
		log "security group could not be formed"
                echo "security group could not be formed"
                return 1
        fi

	log "Security group provisioned with security group id = "$SECURITY_GROUP_ID""
       	echo "Security group provisioned with security group id = "$SECURITY_GROUP_ID""
	yq -i ".app_servers.security_group_id = \"$SECURITY_GROUP_ID\"" ../config/config.yaml
}
