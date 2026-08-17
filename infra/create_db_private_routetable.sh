#!/bin/bash


create_db_private_routetable(){

        ROUTE_TABLE_ID=$(aws ec2 create-route-table \
            --vpc-id "$VPC_ID" \
            --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$DB_ROUTE_TABLE_NAME}]" \
            --query "RouteTable.RouteTableId" \
            --output text)

        if [[ $? -ne 0 ]];
        then
                log "the Route table could not be created"
                return 1
        fi

        log "your Route table has succesfully been created, ROUTE_TABLE_ID: $ROUTE_TABLE_ID"
        echo "your Route table has succesfully been created, ROUTE_TABLE_ID: $ROUTE_TABLE_ID"
        yq -i ".private_db_route_table.route_table_id = \"$ROUTE_TABLE_ID\"" ../config/config.yaml
        return 0

}

