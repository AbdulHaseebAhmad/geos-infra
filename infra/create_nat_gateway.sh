#!/bin/bash

create_nat_gateway() {

    log "Creating NAT Gateway..."
    echo "Creating NAT Gateway..."
    
    NAT_GATEWAY_ID=$(aws ec2 create-nat-gateway \
        --subnet-id "$PUBLIC_SUBNET_ID" \
        --allocation-id "$ELASTIC_IP_ALLOCATION_ID" \
        --query "NatGateway.NatGatewayId" \
        --output text)

    if [[ $? -ne 0 ]]; then
        log "Failed to create NAT Gateway."
        echo "Failed to create NAT Gateway."
	return 1
    fi

    log "NAT Gateway created: $NAT_GATEWAY_ID"
    echo "NAT Gateway created: $NAT_GATEWAY_ID"
    yq -i ".nat_gateway.nat_gateway_id = \"$NAT_GATEWAY_ID\"" ../config/config.yaml
    return 0
}


