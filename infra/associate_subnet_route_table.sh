#!/bin/bash

associate_subnet_route_table() {

    echo "Associating subnet $PRIVATE_SUBNET_ID with route table $PRIVATE_ROUTE_TABLE_ID"

    ROUTE_TABLE_ASSOCIATION_ID=$(aws ec2 associate-route-table \
        --subnet-id "$PRIVATE_SUBNET_ID" \
        --route-table-id "$PRIVATE_ROUTE_TABLE_ID" \
        --query "AssociationId" \
        --output text)

    if [[ $? -ne 0 ]]; then
        log "Failed to associate subnet $PRIVATE_SUBNET_ID with route table $PRIVATE_ROUTE_TABLE_ID"
        return 1
    fi

    log "Association ID: $ROUTE_TABLE_ASSOCIATION_ID"
    echo "Association ID: $ROUTE_TABLE_ASSOCIATION_ID"
    yq -i ".private_route_table.association_id = \"$ROUTE_TABLE_ASSOCIATION_ID\"" ../config/config.yaml
    return 0
}
