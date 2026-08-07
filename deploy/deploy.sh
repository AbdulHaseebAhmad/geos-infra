#!/bin/bash

source ../infra/check_and_install_aws_cli.sh 
source ../infra/configure_aws_cli.sh
source ../lib/common.sh
source ./provision_resources.sh


main(){
	
	#check AWS CLI
	#check_and_install_aws_cli || exitfn 1 "The check for aws cli and installation failed"
        #Configure AWS CLI
	#configure_aws_cli || exitfn 1 "The aws cli configuration failed"

	#Check yaml parser
        #yq --version > /dev/null 2>&1
        #if [[ $? -ne 0  ]];
        #then
         #       sudo snap install yq
        #fi


	#Provisioning infrastructure	
	#provision_infra || exitfn 1 "The infrastructure could not be provisioned"

	#Provisioning resources
	
	provision_resources || exitfn 1 "The provisioning of resources failed"
	



}


main
