#!/bin/bash

provision_ec2_bastion_instance(){

        log "provisioning  Bastion EC2 intance.."
        echo "provisioning Bastion EC2 intance.."


        if [[ -z "$1" ]];
        then
                return 1
        fi

	INSTANCE_ID=$(aws ec2 run-instances \
            --image-id "$AMI_ID" \
            --instance-type "$INSTANCE_TYPE" \
            --subnet-id "$SUBNET_ID" \
            --security-group-ids "$SECURITY_GROUP_ID" \
            --key-name "$KEY_NAME" \
	    --associate-public-ip-address \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value="$INSTANCE_NAME"}]" \
            --query "Instances[0].InstanceId" \
            --output text)

        if [[ $? -ne 0 ]];
        then
                log  "the provisioning of Bastion EC2 instance Failed"
                echo "the provisioning of Bastion EC2 instance Failed"
                return 1
        fi

        log "the Bastion ec2 instance was provisioned succesfully with instance_id = "$INSTANCE_ID""
        echo "the Bastion ec2 instance was provisioned succesfully with instance_id = "$INSTANCE_ID""
        yq -i ".bastion_server.instances.instance_$1_id = \"$INSTANCE_ID\"" ../config/config.yaml

        log "waiting for the Bastion ec2 with id "$INSTANCE_ID" to be available"
        echo   "waiting for the Bastion  ec2 with id "$INSTANCE_ID" to be available"

        aws ec2 wait instance-running \
            --instance-ids "$INSTANCE_ID"

        if [[ $? -ne 0 ]];
        then
            log "the Bastion ec2 with id $INSTANCE_ID failed to become available"
            echo "the Bastion ec2 with id $INSTANCE_ID failed to become available"
            return 1
        fi

        log "the Bastion ec2 with id $INSTANCE_ID is available"
        echo "the Bastion ec2 with id $INSTANCE_ID is available"
        return 0
}

provision_ec2_bastion_instance $1                                                                                                            53,16         Bot
