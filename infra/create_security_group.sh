#!/bin/bash

create_security_group(){

	log "Initiating ALB Security Group creation..."
	echo "Initiating ALB Security Group creation..."
    	
	ALB_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        	--group-name "$ALB_SECURITY_GROUP_NAME" \
        	--description "$ALB_SECURITY_GROUP_DESCRIPTION" \
        	--vpc-id "$VPC_ID" \
        	--tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$ALB_SECURITY_GROUP_NAME}]" \
        	--query "GroupId" \
        	--output text)

    	if [[ $? -ne 0 ]]; then
        	error "Failed to create ALB Security Group."
        	 "Failed to create ALB Security Group."
		return 1
    	fi
	
	log "ALB Security Group created: $ALB_SECURITY_GROUP_ID"
	echo "ALB Security Group created: $ALB_SECURITY_GROUP_ID"
	yq -i ".application_load_balancer.alb_security_group_id = \"$ALB_SECURITY_GROUP_ID\"" ../config/config.yaml
	#yq -i ".app_servers.ingress_rule_1.alb_security_group_id = \"$ALB_SECURITY_GROUP_ID\"" ../config/config.yaml
	yq -i ".app_servers.ingress_rule_2.source_group= \"$ALB_SECURITY_GROUP_ID\"" ../config/config.yaml
	return 0
}	
