#!/bin/bash

create_nat_route(){

        aws ec2 create-route \
                --route-table-id "$ROUTE_TABLE_ID" \
                --destination-cidr-block "0.0.0.0/0" \
                --gateway-id "$NAT_GATEWAY_ID"

        if [[ $? -ne 0 ]];
        then
                log "the internet route could not be created"
                echo "The internet route could not be created"
                return 1

        fi

        log "the internet route has been created succesfully in route table "$ROUTE_TABLE_ID" pointing to the gateway "$INTERNET_GATEWAY_ID""
        echo "the internet route has been created succesfully in route table "$ROUTE_TABLE_ID" pointing to the gateway "$INTERNET_GATEWAY_ID""
        return 0


}
