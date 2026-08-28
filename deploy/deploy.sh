#!/bin/bash

source ../lib/common.sh
source ../infra/check_and_install_aws_cli.sh 
source ../infra/configure_aws_cli.sh
#source ./provision_infra.sh
source ./provision_resources.sh

main(){
	
	echo check AWS CLI
	
	check_and_install_aws_cli || exitfn 1 "The check for aws cli and installation failed"
        
	echo Configure AWS CLI
	
	configure_aws_cli || exitfn 1 "The aws cli configuration failed"

	echo Check yaml parser
        
	yq --version > /dev/null 2>&1
        
	if [[ $? -ne 0  ]];
        then
                sudo snap install yq
        fi


	echo Provisioning Infrastructure

	provision_infra || exitfn 1 "The infrastructure could not be provisioned"

	echo Provisioning Infrastructure Succeeded

	echo Provisioning Resources	

	provision_resources || exitfn 1 "The provisioning of resources failed"
	
	echo Provisioning Resources Succeeded



}


main
