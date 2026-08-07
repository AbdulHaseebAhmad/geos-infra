#!/bin/bash

source ../infra/add_http_alb_listener.sh
source ../lib/common.sh
individual_execution(){
	
	CONFIG_FILE="../config/config.yaml"

	TARGET_GROUP_ARN=$(yq ".alb_target_group.target_group_arn" "$CONFIG_FILE")
        ALB_ARN=$(yq ".application_load_balancer.alb_arn" "$CONFIG_FILE")

        add_http_alb_listener  ||  exitfn 1 "the http listener for the alb could not be created"

}

individual_execution
