#!/bin/bash

associate_internet_gateway(){

	echo "Associating Internet Gateway to VPC"
	echo "$INTERNET_GATEWAY_ID" "$VPC_ID"

	aws ec2 attach-internet-gateway \
		--internet-gateway-id "$INTERNET_GATEWAY_ID" \
		--vpc-id "$VPC_ID"

	if [[ $? -ne 0 ]];
	then
		log "the internet gateway could not be associated with the VPC"
		echo "the internet gateway could not be associated with the VPC"
		return 1
	fi

	 log "the internet gateway associated with the VPC_ID:"$VPC_ID""
         echo "the internet gateway associated with the VPC_ID:"$VPC_ID""
         return 0
}
