#!/bin/bash


create_vpc(){

	log "initiated VPC creation"
	echo "initiated VPC creation"
        echo "$VPC_NAME" "$VPC_CIDR" "$VPC_TENANCY"

	VPC_ID=$(aws ec2 create-vpc \
		--no-amazon-provided-ipv6-cidr-block \
		--instance-tenancy "$VPC_TENANCY" \
		--cidr-block "$VPC_CIDR" \
		--tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value="$VPC_NAME"}]" \
		--query "Vpc.VpcId" \
		--output text)

	if [[ $? -ne 0 ]];
		then
			log "the VPC could not be created"
			echo "The VPC could not be created"
			return 1
	fi


	log "your VPC named "$VPC_NAME" has been succesfully Created, VPC_ID: "$VPC_ID""
	echo "your VPC named "$VPC_NAME" has been succesfully Created, VPC_ID: "$VPC_ID""
	yq -i '.vpc.vpc_id = "'"$VPC_ID"'"' ../config/config.yaml
	
	ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
            --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=true" \
            --query "RouteTables[0].RouteTableId" \
            --output text)
	
	if [[ $? -ne 0 ]]; then
	    log "Failed to retrieve the main route table."
	    echo "Failed to retrieve the main route table."
	    return 1
	fi
	
	yq -i ".vpc.route_table_id= \"$ROUTE_TABLE_ID\"" ../config/config.yaml
	return 0
	
}



