#!/bin/bash

add_http_alb_listener(){
	
	log "adding http listener on port 80 for the alb"
	echo "adding http listener on port 80 for the alb"
	
	HTTP_LISTENER_ARN=$(aws elbv2 create-listener \
	    --load-balancer-arn "$ALB_ARN" \
	    --protocol HTTP \
	    --port 80 \
	    --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN" \
	    --query "Listeners[0].ListenerArn" \
	    --output text)

	#--default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port="443",StatusCode=HTTP_301}'
	
	if [[ $? -ne 0 ]]; then
	    log "Failed to create HTTP listener."
	    echo "Failed to create HTTP listener."
	    return 1
	fi

	log "HTTP listener created: $HTTP_LISTENER_ARN"
	echo "HTTP listener created: $HTTP_LISTENER_ARN"
	yq -i ".application_load_balancer.http_listener_arn = \"$HTTP_LISTENER_ARN\"" ../config/config.yaml
	return 0
}
