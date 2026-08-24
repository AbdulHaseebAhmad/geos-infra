#!/biin/bash

modify_ec2_ingress_rules(){
	
	log "Modifying app server ecurity group rules for "$SECURITY_GROUP_ID""
        echo "Modifyinng app server Security group rules for "$SECURITY_GROUP_ID""
	
	aws ec2 authorize-security-group-ingress \
                 --group-id "$SECURITY_GROUP_ID" \
                 --protocol "$PROTOCOL" \
                 --port "$PORT" \
                 --source-group "$SOURCE_GROUP"
        
	if [[ $? -ne 0 ]];
        then
		log "Failed to modify app server Security group rules  for "$SECURITY_GROUP_ID""
        	echo "Failed to modify app server Security group rulesi for "$SECURITY_GROUP_ID""
        	return 1
	
	fi

		log "app server Security group rules modified for "$SECURITY_GROUP_ID""
		echo "app server Security group rules modified for "$SECURITY_GROUP_ID""
		return 0
     
}	
