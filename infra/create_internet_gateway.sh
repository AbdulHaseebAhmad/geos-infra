#!/bin/bash

create_internet_gateway(){
	
	echo "ProvisioningInternet Gateway"
	echo "$IGW_NAME"

	INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
	    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$IGW_NAME}]" \
	    --query "InternetGateway.InternetGatewayId" \
	    --output text)
	if [[ $? -ne 0 ]];
	then
		log "the internet gateway could not be created"
		echo "the internet gateway could not be created"
		return 1
	fi

	log "the internet gateway has been created INTERNET_GATEWAY_ID: "$INTERNET_GATEWAY_ID""
	echo  "the internet gateway has been created INTERNET_GATEWAY_ID: "$INTERNET_GATEWAY_ID""
	yq -i ".internet_gateway.internet_gateway_id = \"$INTERNET_GATEWAY_ID\"" "../config/config.yaml"
	return 0

}
