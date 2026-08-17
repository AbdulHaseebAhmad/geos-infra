#!/bin/bash

create_db_subnet_group(){
	log  "creating Db Subnet Group"
	echo "creating Db Subnet Group"

	DB_SUBNET_GROUP_ARN=$(aws rds create-db-subnet-group \
		    --db-subnet-group-name "$DB_SUBNET_GROUP_NAME" \
		    --db-subnet-group-description "$DB_SUBNET_GROUP_DESCRIPTION" \
		    --subnet-ids "$DB_SUBNET_1_ID" "$DB_SUBNET_2_ID" \
		    --query 'DBSubnetGroup.DBSubnetGroupArn' \
		    --output text )

	if [[ $? -ne 0 ]];
	then 
		log "The db subnet could not be created"
		echo "The db subnet could not be created"
		return 1
	fi

	echo "the db subnet group was created with Arn = $DB_SUBNET_GROUP_ARN"
	log "the db subnet group was created with Arn = $DB_SUBNET_GROUP_ARN"
	yq -i ".db_subnet_group.arn = \"$DB_SUBNET_GROUP_ARN\"" ../config/config.yaml 
	return 0 



	    
    
}
