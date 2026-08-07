#!/bin/bash


register_target_for_alb(){
    
	log "Registering EC2 as Target for ALB"
	echo "Registering EC2 as Target for ALB"

	aws elbv2 register-targets \
        	--target-group-arn "$TARGET_GROUP_ARN" \
       		--targets Id="$INSTANCE_ID"

 	if [[ $? -ne 0 ]];
    	then
        	log "the registration of ec2 instance $INSTANCE_ID to the target group Failed"
        	echo "the registration of ec2 instance $INSTANCE_ID to the target group Failed"
        	return 1
    	fi

    	log "the ec2 instance with id $INSTANCE_ID was registered successfully to the target group"
    	echo "the ec2 instance with id $INSTANCE_ID was registered successfully to the target group"

<<HEALTH_CHECK
	log "waiting for the target health check to pass"
    	echo "waiting for the target health check to pass"

    	aws elbv2 wait target-in-service \
        	--target-group-arn "$TARGET_GROUP_ARN" \
        	--targets Id="$INSTANCE_ID"

    	if [[ $? -ne 0 ]];
    	then
        	log "the ec2 instance with id $INSTANCE_ID failed to become healthy"
        	echo "the ec2 instance with id $INSTANCE_ID failed to become healthy"
        	return 1
    	fi

    	log "the ec2 instance with id $INSTANCE_ID is healthy and in service"
    	echo "the ec2 instance with id $INSTANCE_ID is healthy and in service"
HEALTH_CHECK

    	return 0
}
