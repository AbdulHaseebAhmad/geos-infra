#!/bin/bash

wait_for_nat_gateway() {

    log "Waiting for NAT Gateway to become available..."
    echo "Waiting for NAT Gateway to become available..."

    aws ec2 wait nat-gateway-available \
        --nat-gateway-ids "$NAT_GATEWAY_ID"

    if [[ $? -ne 0 ]]; then
        log "NAT Gateway did not become available."
        echo "NAT Gateway did not become available."
	return 1
    fi

    log "NAT Gateway is available."
    echo  "NAT Gateway is available."
    return 0
}
