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
source ../infra/create_alb_target_group.sh
source ../infra/create_alb.sh
source ../infra/create_security_group.sh
source ../infra/configure_alb_ingress_rules.sh
source ../infra/add_http_alb_listener.sh
source ../infra/associate_db_subnet_route_table.sh
source ../infra/create_db_private_routetable.sh
source ../infra/create_db_subnet_group.sh
source ../infra/create_rds_security_group.sh
source ../infra/create_rds_db_instance.sh
source ../infra/provision_iam_role.sh
source ../infra/create_instance_profile.sh
source ../infra/add_role_to_instance_profile.sh
source ../infra/attach_secrets_permissions_policy.sh
source ../resources/provision_ec2_sg.sh
provision_infra() {

	if [[ $? -ne 0 ]];
	then 
		exit 1
	fi
	

	CONFIG_FILE="../config/config.yaml"
	
	REGION=$(yq '.region' "$CONFIG_FILE")
	VPC_NAME=$(yq '.vpc.name' "$CONFIG_FILE")
	VPC_CIDR=$(yq '.vpc.cidr' "$CONFIG_FILE")
	VPC_TENANCY=$(yq '.vpc.tenancy' "$CONFIG_FILE")
       
	create_vpc  || exitfn 1 "the vpc could not be created" 

	PUBLIC_SUBNETS=$(yq '.subnets.public_subnets' "$CONFIG_FILE")	
	
	PRIVATE_SUBNETS=$(yq '.subnets.private_subnets' "$CONFIG_FILE")
	
	IGW_NAME=$(yq '.internet_gateway.internet_gateway_name' "$CONFIG_FILE")

	create_internet_gateway || exitfn 1 "the Internet Gateway could not be created"

	INTERNET_GATEWAY_ID=$(yq '.internet_gateway.internet_gateway_id' "$CONFIG_FILE")
	
	VPC_ID=$(yq '.vpc.vpc_id' "$CONFIG_FILE")

	associate_internet_gateway || exitfn 1 "the Internet Gateway could not be associated"
	create_internet_route || exitfn 1 "the internet route could not be added to the main route table to point towards the internet gateway"
	
	

	ROUTE_TABLE_NAME=$(yq ".private_route_table.name" "$CONFIG_FILE")
	DB_ROUTE_TABLE_NAME=$(yq ".private_db_route_table.name" "$CONFIG_FILE")
	
	create_private_routetable || exitfn 1 "the private route table could not be created"
	create_db_private_routetable || exitfn 1 "the private db route table could not be created"

	ROUTE_TABLE_ID=$(yq '.vpc.route_table_id' "$CONFIG_FILE")
	PRIVATE_ROUTE_TABLE_ID=$(yq ".private_route_table.route_table_id" "$CONFIG_FILE")
	DB_PRIVATE_ROUTE_TABLE_ID=$(yq ".private_db_route_table.route_table_id" "$CONFIG_FILE")


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
		

	
	
	for ((i=1; i<="$PRIVATE_SUBNETS / 2"; i++))
        do
		PRIVATE_SUBNET_ID=$(yq ".subnet_private_$i.subnet_id" "$CONFIG_FILE")
		associate_subnet_route_table || exitfn 1 "the private route table could not be associted to the private subnet"
	done


        for ((i=3; i<="$PRIVATE_SUBNETS"; i++))
        do
                PRIVATE_SUBNET_ID=$(yq ".subnet_private_$i.subnet_id" "$CONFIG_FILE")
                associate_db_subnet_route_table || exitfn 1 "the private route table could not be associted to the private subnet"
        done
	
	allocate_elastic_ip || exitfn 1 "the elastic ip allocation failed"
	
	ELASTIC_IP_ALLOCATION_ID=$(yq ".nat_gateway.allocation_id" "$CONFIG_FILE")


	NAT_GATEWAY_NAME=$(yq ".nat_gateway.name" "$CONFIG_FILE")
	PUBLIC_SUBNET_ID=$(yq ".subnet_public_1.subnet_id" "$CONFIG_FILE")
	
	create_nat_gateway || exitfn 1 "the natgateway could not be provisioned"
	
	NAT_GATEWAY_ID=$(yq ".nat_gateway.nat_gateway_id" "$CONFIG_FILE")
	
	wait_for_nat_gateway || exitfn 1 "the wait for natgateway was interrupted"
	create_private_nat_route || exitfn 1 "the private route pointing to nat gateway could not be succesfull"
	

	TARGET_GROUP_NAME=$(yq ".alb_target_group.target_group_name" "$CONFIG_FILE")

	
	PUBLIC_SUBNET_1_ID=$(yq ".subnet_public_1.subnet_id" "$CONFIG_FILE")
	PUBLIC_SUBNET_2_ID=$(yq ".subnet_public_2.subnet_id" "$CONFIG_FILE")
	
	create_alb_target_group ||  exitfn 1 "the target group for alb could not be created"
	
	ALB_NAME=$(yq ".application_load_balancer.alb_name" "$CONFIG_FILE")
	ALB_SECURITY_GROUP_NAME=$(yq ".application_load_balancer.alb_securrity_group_name" "$CONFIG_FILE")
	ALB_SECURITY_GROUP_DESCRIPTION=$(yq ".application_load_balancer.alb_security_description" "$CONFIG_FILE")

	create_security_group  ||  exitfn 1 "the security group for alb could not be created"
	
	ALB_SECURITY_GROUP_ID=$(yq ".application_load_balancer.alb_security_group_id" "$CONFIG_FILE")
	
	configure_alb_ingress_rules  ||  exitfn 1 "the ingress rules could not be set for alb"
	
	create_alb  ||  exitfn 1 "alb could not be created"

	TARGET_GROUP_ARN=$(yq ".alb_target_group.target_group_arn" "$CONFIG_FILE")
	ALB_ARN=$(yq ".application_load_balancer.alb_arn" "$CONFIG_FILE")

	add_http_alb_listener  ||  exitfn 1 "the http listener for the alb could not be created"
	
	DB_SUBNET_GROUP_NAME=$( yq ".db_subnet_group.name" "$CONFIG_FILE")
	DB_SUBNET_GROUP_DESCRIPTION=$(yq ".db_subnet_group.description" "$CONFIG_FILE")

	SECURITY_GROUP_NAME=$(yq ".app_servers.security_group_name" "$CONFIG_FILE")
        SECURITY_GROUP_DESCRIPTION=$(yq ".app_servers.security_group_description" "$CONFIG_FILE")
        provision_ec2_sg || exitfn 1 "The app_server ec2 security group could not be provisioned"


	RDS_SG_NAME=$(yq ".rds.security_group.name" "$CONFIG_FILE")
	RDS_SG_DESCRIPTION=$(yq ".rds.security_group.description" "$CONFIG_FILE")
	RDS_INGRESS_PROTOCOL=$(yq ".rds.ingress_rule.protocol" "$CONFIG_FILE")
	RDS_INGRESS_PORT=$(yq ".rds.ingress_rule.port" "$CONFIG_FILE")	
	RDS_INGRESS_SOURCE=$(yq ".rds.ingress_rule.source_group" "$CONFIG_FILE")

	DB_SUBNET_1_ID=$(yq ".subnet_private_3.subnet_id" "$CONFIG_FILE")
	DB_SUBNET_2_ID=$(yq ".subnet_private_4.subnet_id" "$CONFIG_FILE")
	
	create_db_subnet_group || exitfn 1 "the db subent group could not be created"


	create_rds_security_group || exitfn 1 "the rds security group could not be created"
	
	DB_IDENTIFIER=$(yq ".rds.name" "$CONFIG_FILE")
	DB_CLASS=$(yq ".rds.type" "$CONFIG_FILE")
	DB_ENGINE=$(yq ".rds.engine" "$CONFIG_FILE")
	DB_VERSION=$(yq ".rds.version" "$CONFIG_FILE")
	DB_STORAGE=$(yq ".rds.storage" "$CONFIG_FILE")
	DB_USERNAME=$(yq ".rds.username" "$CONFIG_FILE")
	DB_SUBNET_GROUP=$(yq ".db_subnet_group.name" "$CONFIG_FILE")
	DB_SG_ID=$(yq ".rds.security_group.security_group_id" "$CONFIG_FILE")
	
		
	create_rds_db_instance || exitfn 1 "The RDS db Instance could not be created"
	
	IAM_ROLE_NAME=$(yq ".iam_role.app_secrets_role.name" "$CONFIG_FILE")
        provision_iam_role || exitfn 1 "The iam role could not be provisioned"	

	
	INSTANCE_PROFILE_NAME=$(yq ".iam_role.app_instance_profile.name" "$CONFIG_FILE")
        create_instance_profile || exitfn 1 "the instance profile could not be created"

        APP_INSTANCE_PROFILE_NAME=$(yq ".iam_role.app_instance_profile.name" "$CONFIG_FILE")
        APP_SECRETS_ROLE=$(yq ".iam_role.app_secrets_role.name" "$CONFIG_FILE")

        add_role_to_instance_profile || exitfn 1 "adding role to secrets profile failed"
	
	POLICY_NAME=$(yq ".iam_role.app_secrets_role.policy_name" "$CONFIG_FILE")

	DB_SECRET_ARN=$(yq ".rds.secrets_arn" "$CONFIG_FILE")
	attach_secrets_permissions_policy	
	
}

provision_infra
