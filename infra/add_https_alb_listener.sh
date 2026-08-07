#!/bin/bash

add_https_alb_listener(){

	log "adding https listener on port 443 for alb.."
	echo "adding https listener on port 443 for alb .."

	HTTPS_LISTENER_ARN=$(aws elbv2 create-listener \
	    --load-balancer-arn "$ALB_ARN" \
	    --protocol HTTPS \
	    --port 443 \
	    --certificates CertificateArn="$CERTIFICATE_ARN" \
	    --ssl-policy ELBSecurityPolicy-TLS13-1-2-Res-2021-06 \
	    --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN" \
	    --query "Listeners[0].ListenerArn" \
	    --output text)

	if [[ $? -ne 0 ]]; then
	    log "Failed to create HTTPS listener."
	    echo  "Failed to create HTTPS listener."
	    return 1
	fi

	log "HTTPS listener created: $HTTPS_LISTENER_ARN"
	echo "HTTPS listener created: $HTTPS_LISTENER_ARN"
	yq -i ".application_load_balancer.https_listener_arn = \"$HTTPS_LISTENER_ARN\"" ../config/config.yaml
	return 0
}
