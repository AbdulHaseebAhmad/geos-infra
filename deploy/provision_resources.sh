#!/bin/bash

source ../lib/common.sh
source ../resources/provision_ec2_sg.sh
source ../resources/modify_ec2_ingress_rules.sh
source ../resources/provision_ec2_instance.sh
source ../resources/modify_ec2_ingress_rules_cidr.sh
source ../infra/register_target_for_alb.sh
source ../resources/provision_ec2_bastion_sg.sh
source ../resources/provision_ec2_bastion_instance.sh

provision_resources(){
	
	CONFIG_FILE="../config/config.yaml"
	
	VPC_ID=$(yq ".vpc.vpc_id" "$CONFIG_FILE")


	SECURITY_GROUP_NAME=$(yq ".bastion_server.security_group_name" "$CONFIG_FILE")
        SECURITY_GROUP_DESCRIPTION=$(yq ".bastion_server.security_group_description" "$CONFIG_FILE")

        provision_ec2_bastion_sg || exitfn 1 "The bastion_server ec2 security group could not be provisioned"

        INGRESS_RULES=$(yq  ".bastion_server.ingress_rules" "$CONFIG_FILE")
	SECURITY_GROUP_ID=$(yq ".bastion_server.security_group_id" "$CONFIG_FILE")
        
	for (( i=1; i <= $INGRESS_RULES; i++ ))
        do
                PROTOCOL=$(yq ".bastion_server.ingress_rule_"$i".protocol" "$CONFIG_FILE")
                PORT=$(yq ".bastion_server.ingress_rule_"$i".port" "$CONFIG_FILE")
                CIDR=$(yq ".bastion_server.ingress_rule_"$i".cidr" "$CONFIG_FILE")
                modify_ec2_ingress_rules_cidr || exitfn 1 "The security group ingress rules could not be modified"
        done


        NUMBER_OF_INSTANCES=$(yq ".bastion_server.instances.number_of_instances" "$CONFIG_FILE")

        for (( i=1; i <= $NUMBER_OF_INSTANCES; i++ ))
        do

        AMI_ID=$(yq ".bastion_server.instances.instance_ami_id" "$CONFIG_FILE")
        INSTANCE_TYPE=$(yq ".bastion_server.instances.instance_type" "$CONFIG_FILE")
        SECURITY_GROUP_ID=$(yq ".bastion_server.security_group_id" "$CONFIG_FILE")
        KEY_NAME=$(yq ".bastion_server.instances.instance_key_pair" "$CONFIG_FILE")
        INSTANCE_NAME=$(yq ".bastion_server.instances.instance_name" "$CONFIG_FILE")
        SUBNET_ID=$(yq ".subnet_public_$i.subnet_id" "$CONFIG_FILE")

        provision_ec2_bastion_instance $i || exitfn 1 "The ec2 instances could not be provisioned"
        done


	INGRESS_RULES=$(yq  ".app_servers.ingress_rules" "$CONFIG_FILE")
	
	SECURITY_GROUP_ID=$(yq ".app_servers.security_group_id" "$CONFIG_FILE")

	for (( i=1; i <= $INGRESS_RULES; i++ ))
	do
		PROTOCOL=$(yq ".app_servers.ingress_rule_"$i".protocol" "$CONFIG_FILE")
		PORT=$(yq ".app_servers.ingress_rule_"$i".port" "$CONFIG_FILE")
		SOURCE_GROUP=$(yq ".app_servers.ingress_rule_"$i".source_group" "$CONFIG_FILE")
		modify_ec2_ingress_rules || exitfn 1 "The security group ingress rules could not be modified"
	done

 
	NUMBER_OF_INSTANCES=$(yq ".app_servers.instances.number_of_instances" "$CONFIG_FILE")
        INSTANCE_PROFILE_NAME=$(yq ".iam_role.app_instance_profile.name" "$CONFIG_FILE")

	for (( i=1; i <= $NUMBER_OF_INSTANCES; i++ ))
	do
	
	AMI_ID=$(yq ".app_servers.instances.instance_ami_id" "$CONFIG_FILE")
	INSTANCE_TYPE=$(yq ".app_servers.instances.instance_type" "$CONFIG_FILE")
	SECURITY_GROUP_ID=$(yq ".app_servers.security_group_id" "$CONFIG_FILE")
	KEY_NAME=$(yq ".app_servers.instances.instance_key_pair" "$CONFIG_FILE")
	INSTANCE_NAME=$(yq ".app_servers.instances.instance_name" "$CONFIG_FILE")
	SUBNET_ID=$(yq ".subnet_private_$i.subnet_id" "$CONFIG_FILE")

	provision_ec2_instance $i || exitfn 1 "The ec2 instances could not be provisioned"
	done

	TARGET_GROUP_ARN=$(yq ".alb_target_group.target_group_arn" "$CONFIG_FILE")
	
	for (( i=1; i <= $NUMBER_OF_INSTANCES ; i++ ))
	do
		INSTANCE_ID=$(yq ".app_servers.instances.instance_"$i"_id" "$CONFIG_FILE")
		register_target_for_alb || exitfn 1 "The target group could not be registered"
	done



         	

}	


provision_resources
