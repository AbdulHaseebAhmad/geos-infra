#!/bin/bash

create_subnet(){

	SUBNET_ID=$(aws ec2 create-subnet \
	    --vpc-id "$VPC_ID" \
	    --cidr-block "$SUBNET_CIDR" \
	    --availability-zone "$AVAILABILITY_ZONE" \
	    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$SUBNET_NAME}]" \
	    --query "Subnet.SubnetId" \
	    --output text)

	if [[ $? -ne 0 ]];
	then
		log "the subnet could not be created"
		echo "the subnet could not be created"
		return 1	
	fi

	log "your Subnet has succesfully been created, Subnet_ID: $SUBNET_ID"
	echo "your Subnet has succesfully been created, Subnet_ID: $SUBNET_ID"
	yq -i ".${TAG}.subnet_id = \"$SUBNET_ID\"" ../config/config.yaml
	return 0 

}
