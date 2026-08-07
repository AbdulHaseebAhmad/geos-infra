#!/bin/bash


configure_alb_ingress_rules(){
	
	log "configuring alb secuirty group ingress rule"
	echo "configuring alb secuirty group ingress rule"

	    # Allow HTTP

	    aws ec2 authorize-security-group-ingress \
	        --group-id "$ALB_SECURITY_GROUP_ID" \
	        --protocol tcp \
	        --port 80 \
	        --cidr 0.0.0.0/0

	    if [[ $? -ne 0 ]]; then
                log "Failed to configure ingress rules."
                echo "Failed to configure ingress rules."
		return 1
            fi

	    # Allow HTTPS
	    aws ec2 authorize-security-group-ingress \
	        --group-id "$ALB_SECURITY_GROUP_ID" \
	        --protocol tcp \
	        --port 443 \
	        --cidr 0.0.0.0/0
	
	    if [[ $? -ne 0 ]]; then
	        log "Failed to configure ingress rules."
                echo "Failed to configure ingress rules."
                return 1
	    fi
	
	    log "Ingress rules configured."
	    echo "Ingress rules configured."
	    return 0
    }
