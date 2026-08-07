#!/bin/bash

create_alb(){

	log "Provisioning ALB Security Group.."
	echo "Provisioning ALB Security Group.."

	ALB_ARN=$(aws elbv2 create-load-balancer \
	    --name "$ALB_NAME" \
	    --subnets "$PUBLIC_SUBNET_1_ID" "$PUBLIC_SUBNET_2_ID" \
	    --security-groups "$ALB_SECURITY_GROUP_ID" \
	    --scheme internet-facing \
	    --type application \
	    --ip-address-type ipv4 \
	    --query "LoadBalancers[0].LoadBalancerArn" \
	    --output text)
	
	if [[ $? -ne 0 ]];
	then
		log "the alb could not be provisioned.."
		echo "the alb could not be provisioned.."
		return 1

	fi

	log "the alb was succesfully provisioned"
	echo "the alb was succesfully provisioned"
	yq -i ".application_load_balancer.alb_arn =\"$ALB_ARN\"" ../config/config.yaml
	return 0



}
