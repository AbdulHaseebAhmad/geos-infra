#!/bin/bash

allocate_elastic_ip() {

    log "Allocating Elastic IP..."
    echo "Allocating Elastic IP..."

    ELASTIC_IP_ALLOCATION_ID=$(aws ec2 allocate-address \
        --domain vpc \
        --query "AllocationId" \
        --output text)

    if [[ $? -ne 0 ]]; then
        log "Failed to allocate Elastic IP."
        echo "Failed to allocate Elastic IP."
	return 1
    fi

    log "Elastic IP allocated: $ELASTIC_IP_ALLOCATION_ID"
    echo "Elastic IP allocated: $ELASTIC_IP_ALLOCATION_ID"
    yq -i ".nat_gateway.allocation_id = \"$ELASTIC_IP_ALLOCATION_ID\"" ../config/config.yaml
    return 0
}
