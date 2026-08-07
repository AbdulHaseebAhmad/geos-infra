#!/bin/bash

create_alb_target_group(){

	echo "Creating Target Group For ALB.."
	log  "Creating Target Group For ALB.."
	
	TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
	    --name "$TARGET_GROUP_NAME" \
	    --protocol HTTP \
	    --port 80 \
	    --vpc-id "$VPC_ID" \
	    --target-type instance \
	    --health-check-protocol HTTP \
	    --health-check-path "/" \
	    --query "TargetGroups[0].TargetGroupArn" \
	    --output text)

	if [[ $? -ne 0 ]];
	then
		log "the target group could not be created"
		echo "the target grroup could not be created"
		return 1
	fi
	
	log "The target group with ARN: $TARGET_GROUP_ARN was succesfully created"
	echo "The target group with ARN: $TARGET_GROUP_ARN was succesfully created"
	yq -i ".alb_target_group.target_group_arn = \"$TARGET_GROUP_ARN\"" ../config/config.yaml
	return 0
}
