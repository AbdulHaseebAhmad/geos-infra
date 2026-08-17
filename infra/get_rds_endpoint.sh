#!/bin/bash

get_rds_endpoint(){
	
	RDS_ENDPOINT=$(aws rds describe-db-instances \
	    --db-instance-identifier "$DB_IDENTIFIER" \
	    --query "DBInstances[0].Endpoint.Address" \
	    --output text)

	if [[$? -ne 0 ]];
	then
		echo "the Rds endpoint could not be retrieved"
		log  "the Rds endpoint could not be retrieved"
		return 1
	fi

	echo "the rds_endpoint "$RDS_ENDPOINT" was succesfully retrieved"
	log  "the rds_endpoint "$RDS_ENDPOINT" was succesfully retrieved"
	yq -i ".rds.endpoint = \"$RDS_ENDPOINT\"" ../config/config.yaml
	return 0

}
