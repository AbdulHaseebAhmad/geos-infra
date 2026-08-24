#!/bin/bash

modify_ec2_ingress_rules_cidr(){

        log "Modifying Bastion Security group rules for "$SECURITY_GROUP_ID""
        echo "Modifyinng Bastion Security group rules for "$SECURITY_GROUP_ID""

        aws ec2 authorize-security-group-ingress \
                 --group-id "$SECURITY_GROUP_ID" \
                 --protocol "$PROTOCOL" \
                 --port "$PORT" \
                 --cidr "$CIDR"

        if [[ $? -ne 0 ]];
        then
                log "Failed to modify Bastion Security group rules  for "$SECURITY_GROUP_ID""
                echo "Failed to modify Bastion Security group rulesi for "$SECURITY_GROUP_ID""
                return 1

        fi

                log "Bastion Security group rules modified for "$SECURITY_GROUP_ID""
                echo "Bastion Security group rules modified for "$SECURITY_GROUP_ID""
                return 0

}
