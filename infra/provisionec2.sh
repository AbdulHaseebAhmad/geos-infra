#!/bin/bash



install_aws_cli(){
	
	aws --version

        if [[ $? -eq 0 ]]; then
		echo "CLI already exists $(aws --version) "
		return 0
	else 
		sudo snap install aws-cli --classic
		echo "Installed aws clie version : $(aws --version)"
	fi
}

configure_aws_cli(){
	aws configure
	if [[ $? -ne 0 ]]; then
		aws configure
		aws sts get-caller-identity
		echo "Cli Has been configured with the above User id and account "

	else 
		aws sts get-caller-identity
		echo "CLI has been already configured"					
	fi
}

provisions_security_group(){
	echo "Provisioning Security Group"
	read -p "Enter the name for the security group: " security_group_name
	read -p "Enter Description for the security group: " sg_description
	read -p "Enter VPC id : " vpc_id

	if [[ -z "$security_group_name" ]];
	then 
		security_group_name="$USER-provisioned-sg"
	fi
	if [[ -z "$sg_description" ]];
	then
		sg_description="security group provisioned by $USER"
	fi
	if [[ -z "$vpc_id" ]];
	then
		echo "you did not enter the vpc id"
		exit 1
	fi

	aws ec2 create-security-group \
	    --group-name "$security_group_name" \
	    --description "$sg_description" \
	    --vpc-id "$vpc_id"
	if [[ $? -ne 0 ]];
	then	
		echo security group could not be formed 
		exit 1
	fi
	echo "your security group has been created save the below security group id as you will need to attach it to the ec2 $?"

}

set_security_group_ingress_rules(){
	echo Provisioning Security Group Ingress Rules 
	read -p "Enter the Security Group Id: " security_group_id
	read -p "Enter the Protocol : " protocol
	read -p "Enter the port : " port
	read -p "Enter the Cidr: " cidr
	
	if [[ -z "$security_group_id" ]];
	then
		echo "Missing Security Group Id"
		exit

	elif [[ -z "$protocol" ]];
	then
		echo "Missing Protocol"
		exit 1
	elif [[ -z "$port" ]];
	then
		echo "Missing Port"
		exit 1
	elif [[ -z "$cidr" ]];
	then
		echo "Missing Source Cidr Range"
		exit 1
	fi

	aws ec2 authorize-security-group-ingress \
   	 	 --group-id "$security_group_id" \
   		 --protocol "$protocol" \
   		 --port "$port" \
		 --cidr "$cidr"
	if [[ $? -eq 0 ]];
	then
                echo "Security group rules modified for "$security_group_id""
                
        fi
}

set_security_group_egress_rules(){
	
	echo Provisioning Security Group Egress Rules

        read -p "Enter the Security Group Id: " security_group_id
        read -p "Enter the Protocol : " protocol
        read -p "Enter the port : " port
        read -p "Enter the Cidr: " cidr

	if [[ -z "$security_group_id" ]];
        then
                echo "Missing Security Group Id"
                exit
	fi
        if [[ -z "$protocol" ]];
        then
                echo "Missing Protocol"
                exit 1
	fi
	if [[ -z "$port" ]];
        then
                echo "Missing Port"
                exit 1
	fi
	if [[ -z "$cidr" ]];
        then
                echo "Missing Source Cidr Range"
                exit 1
        fi

        aws ec2 authorize-security-group-ingress \
                 --group-id "$security_group_id" \
                 --protocol "$protocol" \
                 --port "$port" \
                 --cidr "$cidr"
	if [[ $? -eq 0 ]];
	then	
		echo "Security group rules modified "$security_group_id" "
	fi
}

provision_ec2(){
	read -p "Enter the desired ec2 image id: " ec2_image_id
	
	read -p "Enter the desired number of instances: " number_of_instances

	read -p "Enter the desired key pair name: " key_pair_name

	read -p "Enter the security group id: " security_group_id

	read -p "Enter the subnet id: " subnet_id

	read -p "Enter the tag Name for the instance: " tag_value


	if [[ -z "$ec2_image_id" ]];
	then 
		echo "Ec2 Image id is missing"
		exit 1
	fi
	if [[ -z "$number_of_instances" ]];
	then
		number_of_instances=1
	fi
	if [[ -z "$key_pair_name" ]];
	then
		echo "Key Pair name is missing"
		exit 1
	fi
	if [[ -z "$security_group_id" ]];
	then
		echo "Security Group Id is missing"
		exit 1
	fi	
	if [[ -z "$tag_value" ]];
	then 
		
		tag_value="cli-built-WebServer"
	fi

	aws ec2 run-instances \
	    --image-id "$ec2_image_id" \
	    --count "$number_of_instances" \
	    --instance-type t2.micro \
	    --key-name "$key_pair_name" \
	    --security-group-ids "$security_group_id" \
	    --subnet-id "$subnet_id" \
	    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value="$tag_value"}]"



}


install_aws_cli
configure_aws_cli
provisions_security_group
set_security_group_ingress_rules
set_security_group_egress_rules
provision_ec2
