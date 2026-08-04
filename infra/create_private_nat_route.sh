#!/bin/bash

create_private_nat_route() {

    log "Creating default route through NAT Gateway..."
    echo "Creating default route through NAT Gateway..."
 
    aws ec2 create-route \
        --route-table-id "$PRIVATE_ROUTE_TABLE_ID" \
        --destination-cidr-block 0.0.0.0/0 \
        --nat-gateway-id "$NAT_GATEWAY_ID"

    if [[ $? -ne 0 ]]; then
        log "Failed to create NAT route."
        echo "Failed to create NAT route."
	return 1
    fi

    log "Private route table updated."
    echo "Private route table updated."
    return 0
}


