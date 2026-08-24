#!/bin/bash

create_rds_db_instance(){
	
	echo "creating RDS db instance"
       	log "creating RDS db instance"

	aws rds create-db-instance \
	    --db-instance-identifier "$DB_IDENTIFIER" \
	    --db-instance-class "$DB_CLASS" \
	    --engine "$DB_ENGINE" \
	    --engine-version "$DB_VERSION" \
	    --allocated-storage "$DB_STORAGE" \
	    --master-username "$DB_USERNAME" \
	    --manage-master-user-password \
	    --db-subnet-group-name "$DB_SUBNET_GROUP" \
	    --vpc-security-group-ids "$DB_SG_ID" \
	    --no-publicly-accessible
	
	if [[ $? -ne 0 ]];
	then
		echo "the db instance could not be created"
		log "the db instance could not be created"
		return 1
	fi

	echo "the db instance was succesfully created, waiting for it to be active"
	log "the db instance was succesfully created, waiting for it to be active"
	
	aws rds wait db-instance-available \
	    --db-instance-identifier "$DB_IDENTIFIER"

	if [[ $? -ne 0 ]];
        then
                echo "the db instance could not be activated"
                log "the db instance could not be activated"
                return 1
        fi

        echo "the db instance was succesfully activated"
        log "the db instance was succesfully activated"


	DB_SECRET_ARN=$(aws rds describe-db-instances \
	    --db-instance-identifier "$DB_IDENTIFIER" \
	    --query "DBInstances[0].MasterUserSecret.SecretArn" \
	    --output text)
	
	if [[ $? -ne 0 ]];
	then
		echo "the db secret arn could not be retrieved"
		log "the db secret arn could not be retrieved"
	fi
       	
	echo "the db secret arn succsefully retrieved and stored"
	log "the db secret arn succsefully retrieved and stored"	
	yq -i ".rds.secrets_arn = \"$DB_SECRET_ARN\"" ../config/config.yaml


	DB_ENDPOINT=$(aws rds describe-db-instances \
	    --db-instance-identifier "$DB_IDENTIFIER" \
	    --query "DBInstances[0].Endpoint.Address" \
	    --output text)
	if [[ $? -ne 0 ]];
	then
	        echo "the db endpoint could not be retrieved"
	        log "the db endpoint could not be retrieved"
	fi
	echo "the db endpoint succesfully retrieved and stored"
	log "the db endpoint succesfully retrieved and stored"
	yq -i ".rds.endpoint = \"$DB_ENDPOINT\"" ../config/config.yaml
	return 0


}
