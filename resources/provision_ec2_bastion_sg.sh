#!/bin/bash

provision_ec2_bastion_sg(){
	
        log "Provisioning Security group for Bastion"
        echo  "Provisioning Security group for Bastion"

        SECURITY_GROUP_ID=$(aws ec2 create-security-group \
            --group-name "$SECURITY_GROUP_NAME" \
            --description "$SECURITY_GROUP_DESCRIPTION" \
            --vpc-id "$VPC_ID" \
            --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$SECURITY_GROUP_NAME}]" \
            --query "GroupId"\
            --output "text")

        if [[ $? -ne 0 ]];
        then
                log "security group for Bastion could not be formed"
                echo "security group for Bastion could not be formed"
                return 1
        fi

        log "Security group for Bastion provisioned with security group id = "$SECURITY_GROUP_ID""
        echo "Security group for Bastion provisioned with security group id = "$SECURITY_GROUP_ID""
        yq -i ".bastion_server.security_group_id = \"$SECURITY_GROUP_ID\"" ../config/config.yaml
	yq -i ".app_servers.bastion_security_group_id = \"$SECURITY_GROUP_ID\"" ../config/config.yaml
 	yq -i ".app_servers.ingress_rule_1.source_group = \"$SECURITY_GROUP_ID\"" ../config/config.yaml	
	return 0
}
