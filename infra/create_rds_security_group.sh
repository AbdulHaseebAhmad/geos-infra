#!/bin/bash

create_rds_security_group(){

	echo "creating RDS security group"
	log "creating RDS security group"

	DB_SG_ID=$(aws ec2 create-security-group \
	    --group-name "$RDS_SG_NAME" \
	    --description "$RDS_SG_DESCRIPTION" \
	    --vpc-id "$VPC_ID" \
	    --query "GroupId" \
	    --output text)

	if [[ $? -ne 0 ]];
	then
		echo "RDS security group creation failed"
		log "RDS security group creation failed"	
		return 1
	fi

	echo "adding RDS SG Tag"
	log  echo "adding RDS SG Tag"
	aws ec2 create-tags \
    		--resources "$DB_SG_ID" \
    		--tags "Key=Name,Value=$RDS_SG_NAME"
	

	if [[ $? -ne 0 ]];
        then
                echo "Failed to add RDS security group tag"
                log "Failed to add RDS security group tag"
                
        fi

	echo "RDS security group succesfuly created with security group id = "$DB_SG_ID""
        log "RDS security group succesfuly created with security group id = "$DB_SG_ID""
	yq -i ".rds.security_group.security_group_id = \"$DB_SG_ID\""	../config/config.yaml

	echo "adding ingress rules for "$DB_SG_ID""
	log "adding ingress rules for "$DB_SG_ID""

	aws ec2 authorize-security-group-ingress \
	    --group-id "$DB_SG_ID" \
	    --protocol "$RDS_INGRESS_PROTOCOL" \
	    --port "$RDS_INGRESS_PORT" \
	    --source-group "$RDS_INGRESS_SOURCE"
	
	echo "ingress rules succesfully added"
	log   "ingress rules succesfully added"	
	return 0
}
