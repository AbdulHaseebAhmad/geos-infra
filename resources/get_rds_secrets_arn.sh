#!/bin/bash

get_rds_secrets_arn(){
	
	echo "Getting RDS secrets Arn for $RDS_NAME"
	log "Getting RDS secrets Arn"

<< comment
	RDS_SECRET_ARN=$(aws secretsmanager list-secrets \
	    --query "SecretList[?contains(Name, '$RDS_NAME')].ARN" \
	    --output text)
comment

	aws secretsmanager list-secrets
	if [[ $? -ne 0 ]];
	then
		echo "Getting RDS secrets Arn failed"
		log "Getting RDS secrets Arn failed"	
    		return 1
    	fi

	echo "Rds secrets arn $RDS_SECRET_ARN succesfully retrieved"
	log  "Rds secrets arn succesfully retrieved"
	yq -i ".rds.secrets_arn = \"$RDS_SECRET_ARN\"" ../config/config.yaml
	return 0
    }
