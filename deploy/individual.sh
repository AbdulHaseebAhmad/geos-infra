#!/bin/bash

source ../infra/add_http_alb_listener.sh
source ../lib/common.sh

source ../infra/associate_db_subnet_route_table.sh
source ../infra/create_db_private_routetable.sh
source ../infra/create_subnet.sh
source ../infra/create_db_subnet_group.sh
source ../infra/create_rds_security_group.sh
source ../infra/create_rds_db_instance.sh
source ../resources/provision_iam_role.sh
source ../resources/get_rds_secrets_arn.sh
source ../resources/create_instance_profile.sh
source ../resources/add_role_to_instance_profile.sh
source ../resources/attach_iam_instance_profile.sh
individual_execution(){
	
	CONFIG_FILE="../config/config.yaml"
	PRIVATE_SUBNETS=$(yq '.subnets.private_subnets' "$CONFIG_FILE")
	DB_ROUTE_TABLE_NAME=$(yq ".private_db_route_table.name" "$CONFIG_FILE")
	VPC_ID=$(yq ".vpc.vpc_id" "$CONFIG_FILE")
	
	NUMBER_OF_INSTANCES=$(yq ".app_servers.instances.number_of_instances" "$CONFIG_FILE")
        DB_SUBNET_GROUP_NAME=$( yq ".db_subnet_group.name" "$CONFIG_FILE")
        DB_SUBNET_GROUP_DESCRIPTION=$(yq ".db_subnet_group.description" "$CONFIG_FILE")
	DB_SUBNET_1_ID=$(yq ".subnet_private_3.subnet_id" "$CONFIG_FILE")
        DB_SUBNET_2_ID=$(yq ".subnet_private_4.subnet_id" "$CONFIG_FILE")

	RDS_SG_NAME=$(yq ".rds.security_group.name" "$CONFIG_FILE")
        RDS_SG_DESCRIPTION=$(yq ".rds.security_group.description" "$CONFIG_FILE")
        RDS_INGRESS_PROTOCOL=$(yq ".rds.ingress_rule.protocol" "$CONFIG_FILE")
        RDS_INGRESS_PORT=$(yq ".rds.ingress_rule.port" "$CONFIG_FILE")
        RDS_INGRESS_SOURCE=$(yq ".rds.ingress_rule.source_group" "$CONFIG_FILE")
	
<< comment	
	create_db_private_routetable


	for ((i=3; i<="$PRIVATE_SUBNETS"; i++))
        do
                SUBNET_NAME=$(yq ".subnet_private_$i.name" "$CONFIG_FILE")
                SUBNET_CIDR=$(yq ".subnet_private_$i.cidr" "$CONFIG_FILE")
                AVAILABILITY_ZONE=$(yq ".subnet_private_$i.availability_zone" "$CONFIG_FILE")
                VPC_ID=$(yq ".vpc.vpc_id" "$CONFIG_FILE")
                TAG="subnet_private_$i"
                echo "Private Subnet: $i/$PRIVATE_SUBNETS" "$PUBLIC_SUBNETS" "$SUBNET_NAME" "$SUBNET_CIDR" "$AVAILABILITY_ZONE" "$VPC_ID"

                create_subnet || exitfn 1 "the subnet could not be created"
        done

	DB_PRIVATE_ROUTE_TABLE_ID=$(yq ".private_db_route_table.route_table_id" "$CONFIG_FILE")

	for ((i=3; i<="$PRIVATE_SUBNETS "; i++))
        do
                PRIVATE_SUBNET_ID=$(yq ".subnet_private_$i.subnet_id" "$CONFIG_FILE")
                associate_db_subnet_route_table || exitfn 1 "the private route table could not be associted to the private subnet"
        done

	
	 create_db_subnet_group || exitfn 1 "the db subent group could not be created"

	create_rds_security_group


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



	RDS_NAME=$(yq ".rds.name" "$CONFIG_FILE")
        get_rds_secrets_arn || exitfn 1 "Failed to get RDS secrets ARN"	


	INSTANCE_PROFILE_NAME=$(yq ".iam_role.app_instance_profile.name" "$CONFIG_FILE")
	create_instance_profile || exitfn 1 "the instance profile could not be created"
comment

	 APP_INSTANCE_PROFILE_NAME=$(yq ".iam_role.app_instance_profile.name" "$CONFIG_FILE")
        APP_SECRETS_ROLE=$(yq ".iam_role.app_secrets_role.name" "$CONFIG_FILE")

        #add_role_to_instance_profile || exitfn 1 "adding role to secrets profile failed"

	 for (( i=2; i <= $NUMBER_OF_INSTANCES ; i++ ))
        do
                INSTANCE_ID=$(yq ".app_servers.instances.instance_"$i"_id" "$CONFIG_FILE")
                attach_iam_instance_profile || exitfn 1 "the instance profile could not be attached"
        done
}

individual_execution
