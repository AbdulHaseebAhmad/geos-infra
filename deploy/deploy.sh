#!/bin/bash

source ../lib/common.sh
source ../infra/create_vpc.sh
source ../infra/create_subnet.sh
source ../infra/create_internet_gateway.sh
source ../infra/accosiate_internet_gateway.sh
source ../infra/create_internet_route.sh
source ../infra/create_private_routetable.sh
source ../infra/associate_subnet_route_table.sh
source ../infra/allocate_elastic_ip.sh
source ../infra/create_nat_gateway.sh
source ../infra/wait_for_nat_gateway.sh
source ../infra/create_private_nat_route.sh

main() {

	if [[ $? -ne 0 ]];
	then 
		exitfn 1 "The source files are not valid"
	fi

	yq --version > /dev/null 2>&1
	if [[ $? -ne 0  ]];
	then
		sudo snap install yq
	fi


	CONFIG_FILE="../config/config.yaml"
	
	REGION=$(yq '.region' "$CONFIG_FILE")
	VPC_NAME=$(yq '.vpc.name' "$CONFIG_FILE")
	VPC_CIDR=$(yq '.vpc.cidr' "$CONFIG_FILE")
	VPC_TENANCY=$(yq '.vpc.tenancy' "$CONFIG_FILE")
        
	PUBLIC_SUBNETS=$(yq '.subnets.public_subnets' "$CONFIG_FILE")	
	PRIVATE_SUBNETS=$(yq '.subnets.private_subnets' "$CONFIG_FILE")
	
	IGW_NAME=$(yq '.internet_gateway.internet_gateway_name' "$CONFIG_FILE")
	INTERNET_GATEWAY_ID=$(yq '.internet_gateway.internet_gateway_id' "$CONFIG_FILE")
	VPC_ID=$(yq '.vpc.vpc_id' "$CONFIG_FILE")
	ROUTE_TABLE_ID=$(yq '.vpc.route_table_id' "$CONFIG_FILE")
	ROUTE_TABLE_NAME=$(yq ".private_route_table.name" "$CONFIG_FILE")
	#PUBLIC_SUBNET_ID=$(yq ".subnet_public_1.subnet_id" "$CONFIG_FILE")
	ELASTIC_IP_ALLOCATION_ID=$(yq ".nat_gateway.allocation_id" "$CONFIG_FILE")
  	#NAT_GATEWAY_ID=$(yq ".nat_gateway.nat_gateway_id" "$CONFIG_FILE")
	PRIVATE_ROUTE_TABLE_ID=$(yq ".private_route_table.route_table_id" "$CONFIG_FILE")

	create_vpc  || exitfn 1 "the vpc could not be created" 
	create_internet_gateway || exitfn 1 "the Internet Gateway could not be created"
        associate_internet_gateway || exitfn 1 "the Internet Gateway could not be associated"
        create_internet_route || exitfn 1 "the internet route could not be added to the main route table to point towards the internet gateway"
	create_private_routetable || exitfn 1 "the private route table could not be created"

	for ((i=1; i<="$PRIVATE_SUBNETS"; i++)) 
	do
		SUBNET_NAME=$(yq ".subnet_private_$i.name" "$CONFIG_FILE")
        	SUBNET_CIDR=$(yq ".subnet_private_$i.cidr" "$CONFIG_FILE")
        	AVAILABILITY_ZONE=$(yq ".subnet_private_$i.availability_zone" "$CONFIG_FILE")
        	VPC_ID=$(yq ".vpc.vpc_id" "$CONFIG_FILE")
		TAG="subnet_private_$i"
		echo "Private Subnet: $i/$PRIVATE_SUBNETS" "$PUBLIC_SUBNETS" "$SUBNET_NAME" "$SUBNET_CIDR" "$AVAILABILITY_ZONE" "$VPC_ID"	
		create_subnet || exitfn 1 "the subnet could not be created"
	done
	for ((i=1; i<="$PUBLIC_SUBNETS";i++))
	do	
		SUBNET_NAME=$(yq ".subnet_public_$i.name" "$CONFIG_FILE")
                SUBNET_CIDR=$(yq ".subnet_public_$i.cidr" "$CONFIG_FILE")
                AVAILABILITY_ZONE=$(yq ".subnet_public_$i.availability_zone" "$CONFIG_FILE")
                VPC_ID=$(yq ".vpc.vpc_id" "$CONFIG_FILE")
		TAG="subnet_public_$i"
		echo "Public Subnet: $i/$PUBLIC_SUBNETS" "$SUBNET_NAME" "$SUBNET_CIDR" "$AVAILABILITY_ZONE" "$VPC_ID"
		create_subnet || exitfn 1 "the subnets could not be created"
	done
	
	PRIVATE_ROUTE_TABLE_ID=$(yq '.private_route_table.route_table_id' "$CONFIG_FILE")
	
	for ((i=1; i<="$PRIVATE_SUBNETS"; i++))
        do
		PRIVATE_SUBNET_ID=$(yq ".subnet_private_$i.subnet_id" "$CONFIG_FILE")
		associate_subnet_route_table || exitfn 1 "the private route table could not be associted to the private subnet"
	done
	

	allocate_elastic_ip || exitfn 1 "the elastic ip allocation failed"
	
	PUBLIC_SUBNET_ID=$(yq ".subnet_public_1.subnet_id" "$CONFIG_FILE")
	create_nat_gateway || exitfn 1 "the natgateway could not be provisioned"
	NAT_GATEWAY_ID=$(yq ".nat_gateway.nat_gateway_id" "$CONFIG_FILE")
	wait_for_nat_gateway || exitfn 1 "the wait for natgateway was interrupted"
	create_private_nat_route || exitfn 1 "the private route pointing to nat gateway could not be succesfull"


	#create_internet_gateway || exitfn 1 "the Internet Gateway could not be created"      
	#associate_internet_gateway || exitfn 1 "the Internet Gateway could not be associated"
	#create_internet_route || exitfn 1 "the internet route could not be added to the main route table to point towards the internet gateway"
	
}

main
