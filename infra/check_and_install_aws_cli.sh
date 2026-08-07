#!/bin/bash


check_and_install_aws_cli(){

	log "checking and installing aws cli"
	echo "checking and installing aws cli"

        aws --version

        if [[ $? -eq 0 ]]; then
                echo "CLI already exists $(aws --version) "
                log "CLI already exists $(aws --version) "
		return 0 
        else
                sudo snap install aws-cli --classic
                echo "Installed aws clie version : $(aws --version)"
		return 0 
	fi
		
}	
