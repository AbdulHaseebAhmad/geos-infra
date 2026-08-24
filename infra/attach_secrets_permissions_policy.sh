#!/bin/bash
attach_secrets_permissions_policy(){
        echo "attaching secrets manager permissions policy to iam role"
        log "attaching secrets manager permissions policy to iam role"

	aws iam put-role-policy \
            --role-name "$IAM_ROLE_NAME" \
            --policy-name "$POLICY_NAME" \
            --policy-document '{
                "Version": "2012-10-17",
                "Statement": [{
                    "Effect": "Allow",
                    "Action": "secretsmanager:GetSecretValue",
                    "Resource": "'"$DB_SECRET_ARN"'"
                }]
            }'

        if [[ $? -ne 0 ]];
        then
                echo "the permissions policy could not be attached"
                log "the permissions policy could not be attached"
                return 1
        fi
    
    	echo "the permissions policy was successfully attached"
        log "the permissions policy was successfully attached"
        return 0
}
