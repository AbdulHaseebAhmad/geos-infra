create_edu_connect_database() {

    echo "Creating edu-connect database"
    log "Creating edu-connect database"
    

    SECRET_JSON=$(aws secretsmanager get-secret-value \
        --secret-id "$DB_SECRET_ARN" \
        --query SecretString \
        --output text)
    
    if [[ $? -ne 0 ]];
    then
	echo "failed to fetch secrets json"
	log "failed to fetch secrets json"
	return 1 
    fi

    DB_USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
    DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')

    log "Creating edu-connect database..."

    PGPASSWORD="$DB_PASSWORD" psql \
        -h "$RDS_ENDPOINT" \
        -U "$DB_USERNAME" \
        -d postgres \
        -c 'CREATE DATABASE "edu-connect";'
    
    if [[ $? -ne 0 ]];
    then
        echo "failed to create edu-connect db"
        log "failed to create edu-connect db"
        return 1
    fi 

    log "edu-connect database created successfully"
    echo "edu-connect database created successfully"

}
