#!/biin/bash

modify_ec2_ingress_rules(){
	
	log "Modifying Security group rules for "$SECURITY_GROUP_ID""
        echo "Modifyinng Security group rules for "$SECURITY_GROUP_ID""
	
	aws ec2 authorize-security-group-ingress \
                 --group-id "$SECURITY_GROUP_ID" \
                 --protocol "$PROTOCOL" \
                 --port "$PORT" \
                 --source-group "$SOURCE_GROUP"
        
	if [[ $? -ne 0 ]];
        then
		log "Failed to modify Security group rules  for "$SECURITY_GROUP_ID""
        	echo "Failed to modify Security group rulesi for "$SECURITY_GROUP_ID""
        	return 1
	
	fi

		log "Security group rules modified for "$SECURITY_GROUP_ID""
		echo "Security group rules modified for "$SECURITY_GROUP_ID""
		return 0
     
}	
